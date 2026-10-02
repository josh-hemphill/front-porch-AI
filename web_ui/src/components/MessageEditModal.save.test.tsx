// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// When Save fails the editor must stay put with the user's draft and say why.

import { act } from 'react-dom/test-utils';
import { createRoot, type Root } from 'react-dom/client';
import { createElement } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { MessageEditModal } from './MessageEditModal';

let container: HTMLDivElement;
let root: Root;

function typeInto(el: HTMLTextAreaElement, value: string) {
  const setter = Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value')!.set!;
  setter.call(el, value);
  el.dispatchEvent(new Event('input', { bubbles: true }));
}

function saveButton(): HTMLButtonElement {
  return [...container.querySelectorAll('button')].find((b) =>
    /^Sav/.test(b.textContent ?? ''),
  ) as HTMLButtonElement;
}

describe('MessageEditModal save', () => {
  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });

  afterEach(() => {
    act(() => root.unmount());
    container.remove();
  });

  it('keeps the draft and shows the reason when saving fails', async () => {
    const onSave = vi.fn(async () => {
      throw new Error("Couldn't save your edit. Front Porch AI didn't answer.");
    });
    await act(async () => {
      root.render(createElement(MessageEditModal, { initialText: 'before', onCancel: () => {}, onSave }));
    });
    const body = container.querySelector('textarea.msg-edit-body') as HTMLTextAreaElement;
    await act(async () => typeInto(body, 'after'));

    await act(async () => saveButton().click());

    expect(onSave).toHaveBeenCalledWith('after');
    expect(container.querySelector('[role="alert"]')?.textContent).toContain(
      "Couldn't save your edit.",
    );
    expect((container.querySelector('textarea.msg-edit-body') as HTMLTextAreaElement).value).toBe('after');
    expect(saveButton().disabled).toBe(false);
  });
});
