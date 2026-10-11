// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import { useEffect, useRef, useState } from 'react';
import { previewPrompts, rerollPack, type ExpressionIntensity, type PackSlot, type PackView } from './packApi';

export function IntensityPicker({value, onChange, disabled, label = 'Expression intensity'}: {
  value: ExpressionIntensity; onChange: (value: ExpressionIntensity) => void; disabled?: boolean; label?: string;
}) {
  return <label>{label}<select aria-label={label} value={value} disabled={disabled}
    onChange={(e) => onChange(e.target.value as ExpressionIntensity)}>
    <option value="current">Current prompts</option><option value="subtle">Subtle</option>
    <option value="clear">Clear</option><option value="strong">Strong</option>
  </select><small>Changes expression wording, not CFG or noise. Results depend on the model.</small></label>;
}

export function SlotIntensityEditor({slot, pack, disabled, onBegin, onDone, onEnd}: {
  slot: PackSlot; pack: PackView; disabled: boolean;
  onBegin: () => void; onDone: (pack: PackView) => void; onEnd: () => void;
}) {
  const [intensity, setIntensity] = useState<ExpressionIntensity>(slot.intensity ?? pack.intensity ?? 'current');
  const [prompt, setPrompt] = useState(slot.prompt ?? '');
  const [generated, setGenerated] = useState(false);
  const [edited, setEdited] = useState(slot.customPrompt === true);
  const [newSeed, setNewSeed] = useState(false);
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState('');
  const request = useRef(0);
  useEffect(() => () => {request.current++;}, []);
  const preview = async (level = intensity) => {
    const id = ++request.current;
    setBusy(true); setProblem('');
    try {
      const value = await previewPrompts({ activePack: true, promptRules: pack.promptRules ?? {prefix:'',suffix:'',replacements:[]},
        prompt: '', set: 'full', intensity: level, useIntensityPrompt: true });
      if (id !== request.current) return;
      const found = value.previews.find((p) => p.emotion === slot.emotion);
      if (!found) throw new Error('This expression is no longer in the pack.');
      setPrompt(found.effective); setGenerated(true); setEdited(false);
    } catch (e) { if (id === request.current) setProblem(e instanceof Error ? e.message : 'Could not preview wording.'); }
    finally { if (id === request.current) setBusy(false); }
  };
  const run = async () => {
    onBegin(); setBusy(true); setProblem('');
    try { onDone(await rerollPack(slot.emotion, {intensity, newSeed, useIntensityPrompt: generated, ...(edited ? {promptOverride: prompt} : {})})); }
    catch (e) { setProblem(e instanceof Error ? e.message : 'Could not retry expression.'); }
    finally { setBusy(false); onEnd(); }
  };
  return <details><summary>Tune {slot.emotion}</summary><fieldset disabled={disabled || busy}>
    <IntensityPicker value={intensity} onChange={(value) => {setIntensity(value); if (!edited) void preview(value);}} label={`Intensity for ${slot.emotion}`} />
    <button type="button" onClick={() => void preview()}>Use intensity wording for {slot.emotion}</button>
    {slot.customPrompt ? <p>A custom prompt overrides intensity until you replace its wording.</p> : null}
    <label>Final prompt<textarea aria-label={`Prompt for ${slot.emotion}`} value={prompt}
      onChange={(e) => {setPrompt(e.target.value); setGenerated(false); setEdited(true);}} /></label>
    <label><input type="checkbox" checked={newSeed} onChange={(e) => setNewSeed(e.target.checked)} />New random seed</label>
    <button type="button" onClick={() => void run()}>Retry {slot.emotion} with these settings</button>
    {problem ? <p role="alert">{problem}</p> : null}
  </fieldset></details>;
}
