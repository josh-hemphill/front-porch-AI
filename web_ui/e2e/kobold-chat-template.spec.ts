// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import { test, expect } from '@playwright/test';

// The real sandboxed app and real host-owned preset seeded by browser_test.dart.
test('upload and clear a preset chat template without changing the model settings', async ({ page }) => {
  const settings = await (await page.request.get('/api/settings')).json();
  try {
    const switched = await page.request.post('/api/settings', { data: { backend: 'kobold' } });
    expect(switched.ok()).toBe(true);
    await page.goto('/#/models');
    const select = page.locator('#kc-preset');
    await expect(select).toBeVisible();
    const model = await (await page.request.get('/api/backend/local-model')).json();
    const preset = model.presets.find((entry: { name: string }) => entry.name === 'Long chats');
    expect(preset).toBeTruthy();
    await select.selectOption(preset.path);
    const panel = page.getByRole('heading', { name: 'Chat template', exact: true }).locator('..');
    await expect(panel.getByText('Upload .jinja file')).toBeVisible();
    await panel.screenshot({ path: test.info().outputPath('template-before.png') });
    const upload = page.waitForResponse(response =>
      response.url().endsWith('/api/backend/local-model/chat-template') && response.request().method() === 'POST');
    await panel.locator('input[type=file]').setInputFiles({
      name: 'example-chat-template.jinja', mimeType: 'text/plain',
      buffer: Buffer.from('{% if enable_thinking is false %}direct{% endif %}'),
    });
    const response = await upload;
    expect(response.ok(), await response.text()).toBe(true);
    const saved = await response.json();
    expect(saved.preset.path).toBe(preset.path);
    expect(saved.preset.chatTemplate).toMatch(/chat_templates[/\\][a-f0-9]+[/\\]example-chat-template\.jinja$/);
    await expect(panel.getByRole('button', { name: 'Use embedded template' })).toBeVisible();
    await expect(panel.getByRole('status')).toContainText('Restart KoboldCpp');
    await panel.screenshot({ path: test.info().outputPath('template-after.png') });
    await page.reload();
    await expect(panel.getByRole('button', { name: 'Use embedded template' })).toBeVisible();
    const clearing = page.waitForResponse(response =>
      response.url().endsWith('/api/backend/local-model/chat-template') && response.request().method() === 'POST');
    await panel.getByRole('button', { name: 'Use embedded template' }).click();
    expect((await clearing).ok()).toBe(true);
    await expect(panel.getByText('Uses the template embedded in the GGUF.')).toBeVisible();
    const after = await (await page.request.get('/api/backend/local-model')).json();
    expect(after.model).toBe(model.model);
    expect(after.preset.chatTemplate).toBe('');
  } finally {
    await page.request.post('/api/backend/local-model/preset', { data: { path: null } });
    await page.request.post('/api/settings', { data: {
      backend: settings.backend, remoteApiUrl: settings.remoteApiUrl, remoteModelName: settings.remoteModelName,
    } });
  }
});
