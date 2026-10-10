// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import { useCallback, useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { api, ApiError } from '../api/client';
import './imageBatches.css';

interface Job {
  id: string; characterId: string; characterName: string; kind: string;
  label: string; prompt: string; state: string; kept: boolean; seed: number;
  edit: boolean; size: string; candidate?: string; error?: string;
}
interface Queue { running: boolean; working: boolean; pauseRequested: boolean; error?: string; jobs: Job[] }
interface Character { id: string; name: string }

export function ImageBatchesPage() {
  const [queue, setQueue] = useState<Queue>();
  const [characters, setCharacters] = useState<Character[]>([]);
  const [selected, setSelected] = useState<string[]>([]);
  const [search, setSearch] = useState('');
  const [kind, setKind] = useState('additional');
  const [prompt, setPrompt] = useState('');
  const [edit, setEdit] = useState(false);
  const [missingOnly, setMissingOnly] = useState(true);
  const [tab, setTab] = useState('prepare');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [redo, setRedo] = useState<Job>();
  const [redoPrompt, setRedoPrompt] = useState('');
  const [newSeed, setNewSeed] = useState(true);
  const [confirmSave, setConfirmSave] = useState(false);
  const epoch = useRef(0);
  const refresh = useCallback(async () => {
    const request = ++epoch.current;
    try { const next = await api.get<Queue>('/api/image/batches'); if (request === epoch.current) setQueue(next); }
    catch (e) { setError(e instanceof ApiError ? e.message : 'Could not load batches.'); }
  }, []);
  useEffect(() => {
    void refresh();
    api.get<Character[]>('/api/characters').then(setCharacters).catch(() => setError('Could not load characters.'));
    const focus = () => void refresh();
    window.addEventListener('focus', focus);
    return () => window.removeEventListener('focus', focus);
  }, [refresh]);
  useEffect(() => {
    if (!queue?.running || busy) return;
    const timer = window.setInterval(() => void refresh(), 2000);
    return () => window.clearInterval(timer);
  }, [queue?.running, busy, refresh]);
  const action = async (path: string, body: unknown = {}) => {
    const request = ++epoch.current;
    setBusy(true); setError('');
    try { const next = await api.post<Queue>(`/api/image/batches/${path}`, body); if (request === epoch.current) setQueue(next); return true; }
    catch (e) { setError(e instanceof ApiError ? e.message : 'Image operation failed.'); return false; }
    finally { setBusy(false); }
  };
  const locked = busy || queue?.running || queue?.working;
  const reviewLocked = busy || queue?.working;
  const jobs = queue?.jobs ?? [];
  const waiting = jobs.filter((j) => j.state === 'waiting').length;
  const kept = jobs.filter((j) => j.state === 'review' && j.kept);
  const rows = jobs.filter((j) => tab === 'review' ? ['review', 'saved', 'failed', 'interrupted'].includes(j.state) : j.state !== 'discarded');
  const save = async () => { if (await action('save')) setConfirmSave(false); };
  return <div className="image-batches">
    <header><h2>Images</h2><button disabled={reviewLocked || !kept.length} onClick={() => {
      if (kept.some((j) => j.kind === 'portrait')) setConfirmSave(true); else void save();
    }}>Save {kept.length} kept</button></header>
    <section className="card batch-status" aria-label="Queue status">
      <span>{jobs.filter((j) => ['review', 'saved'].includes(j.state)).length} finished · {waiting} waiting</span>
      <button className="primary" disabled={locked || !waiting} onClick={() => void action('start')}>Start {waiting} images</button>
      <button disabled={busy || !queue?.running} onClick={() => void action('pause')}>{queue?.pauseRequested ? 'Pausing after current image…' : 'Pause after current image'}</button>
      <small>Runs while the desktop app remains open.</small>
    </section>
    {error || queue?.error ? <p role="alert">{error || queue?.error}</p> : null}
    <div role="group" aria-label="Images views" className="batch-tabs">
      {['prepare', 'queue', 'review'].map((value) => <button key={value} aria-pressed={tab === value} onClick={() => setTab(value)}>{value[0].toUpperCase() + value.slice(1)}</button>)}
    </div>
    {confirmSave ? <section className="card" aria-label="Confirm portrait replacement">
      <h3>Replace primary portraits?</h3><p>The kept primary portrait candidates replace the selected characters’ current portraits. Additional portraits stay in the gallery.</p>
      <button disabled={reviewLocked} onClick={() => void save()}>Replace portraits</button><button onClick={() => setConfirmSave(false)}>Cancel</button>
    </section> : null}
    {tab === 'prepare' ? <section className="card">
      <h3>Add work across characters</h3>
      <fieldset disabled={!!locked}>
        <label>Save destination<select value={kind} onChange={(e) => setKind(e.target.value)}>
          <option value="additional">Additional portraits · character gallery</option>
          <option value="expressions">Expression set · starter (8)</option>
          <option value="portrait">Primary portrait</option>
        </select></label>
        <p>Additional portraits are saved to the character’s gallery. They do not replace the primary portrait or become expressions.</p>
        <label>Prompt / instruction<textarea rows={4} value={prompt} onChange={(e) => setPrompt(e.target.value)} placeholder="Use {character} for each character’s name." /></label>
        {kind !== 'expressions' ? <label><input type="checkbox" checked={edit} onChange={(e) => setEdit(e.target.checked)} /> Edit the current character portrait</label> :
          <label><input type="checkbox" checked={missingOnly} onChange={(e) => setMissingOnly(e.target.checked)} /> Only missing expressions</label>}
        <p>Uses current Image Studio settings. Source images and prompts are captured when prepared. Changing generation settings pauses older waiting work until those settings are restored.</p>
        <Link to="/models">Configure in Image Studio</Link>
        <label>Find characters<input value={search} onChange={(e) => setSearch(e.target.value)} /></label>
        <div className="batch-characters">{characters.filter((c) => c.name.toLowerCase().includes(search.toLowerCase())).map((c) => <label key={c.id}>
          <input type="checkbox" checked={selected.includes(c.id)} onChange={(e) => setSelected(e.target.checked ? [...selected, c.id] : selected.filter((id) => id !== c.id))} />{c.name}
        </label>)}</div>
        <button className="primary" disabled={!selected.length || !queue} onClick={() => void action('prepare', { characterIds: selected, kind, prompt, edit, missingOnly }).then((ok) => { if (ok) setTab('queue'); })}>Prepare for {selected.length} characters</button>
      </fieldset>
    </section> : <div className="batch-results">{!rows.length ? <p>{tab === 'review' ? 'Finished images will appear here for review.' : 'Prepare a batch to add images to the queue.'}</p> : rows.map((job) => <article className="card" key={job.id}>
      <h3>{job.characterName} · {job.label}</h3><p>{job.state}</p>
      {tab === 'review' && job.candidate ? <img src={`/api/image/batches/${job.id}/picture`} alt={`${job.characterName} ${job.label} candidate`} /> : null}
      <p>{job.prompt}</p><small>Seed {job.seed} · {job.edit ? 'Edit' : 'Create'} · {job.size}</small>
      {job.error ? <p>{job.error}</p> : null}
      <div className="batch-actions">
        {job.state === 'review' ? <button disabled={!!reviewLocked} onClick={() => void action(`${job.id}/review`, {action: 'keep'})}>{job.kept ? 'Kept ✓' : 'Keep'}</button> : null}
        {['review', 'saved', 'failed', 'interrupted'].includes(job.state) ? <button disabled={!!reviewLocked} onClick={() => { setRedo(job); setRedoPrompt(job.prompt); setNewSeed(true); }}>Redo…</button> : null}
        {['waiting', 'review', 'failed', 'interrupted'].includes(job.state) ? <button disabled={!!reviewLocked} onClick={() => void action(`${job.id}/review`, {action: 'discard'})}>Discard</button> : null}
      </div>
    </article>)}</div>}
    {redo ? <section className="card" aria-label="Prepare another pass">
      <h3>Another pass · {redo.characterName}</h3>
      <label>Prompt<textarea rows={4} value={redoPrompt} onChange={(e) => setRedoPrompt(e.target.value)} /></label>
      <label><input type="checkbox" checked={newSeed} onChange={(e) => setNewSeed(e.target.checked)} /> Use a new seed</label>
      <button disabled={!!reviewLocked} onClick={() => void action(`${redo.id}/review`, { action: 'redo', prompt: redoPrompt, newSeed }).then((ok) => { if (ok) { setRedo(undefined); setTab('queue'); } })}>Add to queue</button>
      <button onClick={() => setRedo(undefined)}>Cancel</button>
    </section> : null}
  </div>;
}
