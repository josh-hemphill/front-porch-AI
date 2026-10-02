// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// In-chat model chip. Desktop opens the global Model Settings dialog from the
// chat sidebar (lib/ui/pages/chat_page.sidebar_widgets.dart) — one
// remoteModelName for every chat, not a per-chat override. This chip writes
// that same field through POST /api/settings. A model-only body does not
// change the API URL or key, so it does not need the password step-up Settings
// uses for those. If the server asks for one anyway, the sheet says so and
// links to Settings instead of failing quietly.
//
// KoboldCpp (and any other backend ModelPicker does not apply to) has no
// remote model list. The chip shows the backend name and the sheet links to
// Settings, where the host model is chosen. The Settings links replace the
// sheet's history marker entry, so Back from Settings lands on the chat.

import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { api, ApiError } from '../../api/client';
import { ModelPicker } from '../../components/ModelPicker';
import { useBackDismiss } from '../../hooks/useBackDismiss';

const MARKER_KEY = 'fpModelSwitch';

export interface ChatModelSnapshot {
  backend: string;
  remoteApiUrl: string;
  remoteModelName: string;
  loadedModel?: string;
}

const BACKEND_LABELS: Record<string, string> = {
  kobold: 'KoboldCpp',
  omlx: 'oMLX',
  openRouter: 'Remote API',
};

/** ModelPicker is the chat-model control for OpenAI-compatible backends only. */
export function modelPickerApplies(backend: string): boolean {
  return backend === 'openRouter' || backend === 'omlx';
}

export function backendDisplayName(backend: string): string {
  const known = BACKEND_LABELS[backend];
  if (known) return known;
  const trimmed = backend.trim();
  return trimmed || 'Model';
}

export function chatModelChipLabel(s: ChatModelSnapshot): string {
  if (modelPickerApplies(s.backend)) {
    const name = s.remoteModelName.trim();
    return name || 'Select a model';
  }
  return backendDisplayName(s.backend);
}

function pinVisualViewport(el: HTMLElement): () => void {
  const vv = window.visualViewport;
  if (!vv) return () => {};
  const apply = () => {
    el.style.setProperty('--fp-vvh', `${vv.height}px`);
    el.style.setProperty('--fp-vvw', `${vv.width}px`);
    el.style.setProperty('--fp-vv-top', `${vv.offsetTop}px`);
    el.style.setProperty('--fp-vv-left', `${vv.offsetLeft}px`);
  };
  apply();
  vv.addEventListener('resize', apply);
  vv.addEventListener('scroll', apply);
  window.addEventListener('scroll', apply);
  return () => {
    vv.removeEventListener('resize', apply);
    vv.removeEventListener('scroll', apply);
    window.removeEventListener('scroll', apply);
    el.style.removeProperty('--fp-vvh');
    el.style.removeProperty('--fp-vvw');
    el.style.removeProperty('--fp-vv-top');
    el.style.removeProperty('--fp-vv-left');
  };
}

function ModelSwitchSheet({
  settings,
  onClose,
  onSaved,
}: {
  settings: ChatModelSnapshot;
  onClose: () => void;
  onSaved: (next: ChatModelSnapshot) => void;
}) {
  const overlayRef = useRef<HTMLDivElement>(null);
  const [error, setError] = useState('');
  const [needsSettings, setNeedsSettings] = useState(false);
  const [saving, setSaving] = useState(false);
  const alive = useRef(true);
  const requestDismiss = useBackDismiss(MARKER_KEY, onClose);

  useEffect(() => {
    alive.current = true;
    return () => {
      alive.current = false;
    };
  }, []);

  useLayoutEffect(() => {
    const el = overlayRef.current;
    if (!el) return;
    return pinVisualViewport(el);
  }, []);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape') return;
      e.preventDefault();
      e.stopPropagation();
      requestDismiss();
    };
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [requestDismiss]);

  const canPick = modelPickerApplies(settings.backend);

  const save = (id: string) => {
    if (saving) return;
    setSaving(true);
    setError('');
    setNeedsSettings(false);
    void (async () => {
      try {
        const next = await api.post<ChatModelSnapshot>('/api/settings', {
          remoteModelName: id,
        });
        onSaved({
          ...settings,
          ...next,
          remoteModelName: next.remoteModelName || id,
        });
      } catch (e) {
        if (!alive.current) return;
        setSaving(false);
        if (e instanceof ApiError && e.payload.totpRequired === true) {
          setNeedsSettings(true);
          setError('Saving the model needs your web login. Open Settings to confirm it.');
          return;
        }
        setError(e instanceof ApiError ? e.message : 'Could not save the model');
      }
    })();
  };

  return (
    <div
      className="drawer-backdrop center model-switch-overlay"
      ref={overlayRef}
      onClick={requestDismiss}
    >
      <div
        className="modal model-switch-sheet"
        role="dialog"
        aria-label="Change model"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="model-switch-head">
          <span className="model-switch-title">Model</span>
          <button type="button" className="ghost" onClick={requestDismiss}>
            Close
          </button>
        </div>
        <div className="model-switch-body">
          {canPick ? (
            <ModelPicker
              apiUrl={settings.remoteApiUrl}
              apiKey=""
              savedApiUrl={settings.remoteApiUrl}
              value={settings.remoteModelName}
              onChange={save}
            />
          ) : (
            <>
              <p className="muted small">
                {backendDisplayName(settings.backend)} runs on the computer that hosts
                this chat. Choose its model in Settings.
              </p>
              <Link to="/settings" replace className="model-switch-settings">
                Open Settings
              </Link>
            </>
          )}
          {saving && <p className="muted small">Saving…</p>}
          {error && (
            <p className="error" role="alert">
              {error}{' '}
              {needsSettings && <Link to="/settings" replace>
                  Open Settings
                </Link>}
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

export function ChatModelSwitcher() {
  const [settings, setSettings] = useState<ChatModelSnapshot | null>(null);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    let cancelled = false;
    api
      .get<ChatModelSnapshot>('/api/settings')
      .then((next) => {
        if (!cancelled) setSettings(next);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, []);

  if (!settings) return null;

  const label = chatModelChipLabel(settings);

  return (
    <>
      <button
        type="button"
        className="model-switch-chip"
        title={label}
        aria-haspopup="dialog"
        aria-expanded={open}
        onClick={() => setOpen(true)}
      >
        <span className="model-switch-chip-text">{label}</span>
      </button>
      {open && (
        <ModelSwitchSheet
          settings={settings}
          onClose={() => setOpen(false)}
          onSaved={(next) => {
            setSettings(next);
            setOpen(false);
          }}
        />
      )}
    </>
  );
}
