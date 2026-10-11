// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import {expect, openRoute, test} from './support/fixtures';

test('expression intensity changes real preview wording and survives a tab switch', async ({page}, testInfo) => {
  await openRoute(page, '/models');
  await page.getByRole('tab', {name:'Expression pack', exact:true}).click();
  const panel = page.locator('#studio-pack-panel');
  const intensity = panel.getByLabel('Expression intensity', {exact:true});
  await intensity.selectOption('subtle');
  await page.getByRole('tab', {name:'Create',exact:true}).click();
  await page.getByRole('tab', {name:'Expression pack',exact:true}).click();
  await expect(intensity).toHaveValue('subtle');
  await intensity.focus(); await page.keyboard.press('Tab');
  await panel.locator('label').filter({has:intensity}).screenshot({path:testInfo.outputPath('expression-intensity.png')});
  const rules = {prefix:'',suffix:'',replacements:[]};
  const response = await page.request.post('/api/image/expression-pack/preview', {
    data:{promptRules:rules, intensity:'subtle',set:'full',prompt:'portrait'},
  });
  expect(response.ok()).toBe(true);
  const subtle = await response.json() as {previews:{emotion:string;effective:string}[]};
  expect(subtle.previews.find((p)=>p.emotion==='anger')?.effective).toContain('gently tightened lips');
  const strongResponse = await page.request.post('/api/image/expression-pack/preview', {
    data:{promptRules:rules,intensity:'strong',set:'full',prompt:'portrait'},
  });
  expect(strongResponse.ok()).toBe(true);
  const strong = await strongResponse.json() as typeof subtle;
  expect(strong.previews.find((p)=>p.emotion==='anger')?.effective).toContain('deeply furrowed brows');
});


test('retry keeps generated prompts adjustable and previews honor slot overrides', async ({page, allowHttp}) => {
  test.skip(!process.env.FPAI_INTENSITY_IMAGE_URL, 'Requires a real A1111 img2img backend.');
  test.setTimeout(30 * 60_000);
  allowHttp((url,status) => status === 404 && url.includes('/api/image/expression-pack/source'));
  const saved=await (await page.request.get('/api/image/config')).json() as {backend:string;localUrl:string};
  try {
    expect((await page.request.post('/api/image/config',{data:{backend:'a1111',localUrl:process.env.FPAI_INTENSITY_IMAGE_URL,currentPassword:process.env.FPAI_PASSWORD}})).ok()).toBe(true);
    await openRoute(page,'/models');
    await page.getByRole('tab',{name:'Expression pack',exact:true}).click();
    const panel=page.locator('#studio-pack-panel');
    await panel.getByLabel('Character',{exact:true}).selectOption({label:'Porch Tester'});
    await panel.getByLabel('Image prompt',{exact:true}).fill('portrait');
    await panel.getByLabel('Pack picture file').setInputFiles({name:'synthetic.png',mimeType:'image/png',buffer:Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAEAAAABQCAIAAAAm3eQSAAAAkUlEQVR4nO3PUQkAIBTAQMO+EIYwtCH8OITBAtzWnvN1iwsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKCB8YiXgQthSyGlgmdeIgAAAABJRU5ErkJggg==','base64')});
    await panel.getByLabel('Expression intensity',{exact:true}).selectOption('subtle');
    await panel.getByRole('button',{name:'Start pack',exact:true}).click();
    await expect(panel.getByLabel('Pack expression intensity')).toBeEnabled({timeout:20 * 60_000});
    await panel.getByText('Tune joy',{exact:true}).click();
    const retry=panel.getByRole('button',{name:'Retry joy with these settings',exact:true});
    await retry.click(); await expect(retry).toBeEnabled({timeout:10 * 60_000});
    type View={slots:{emotion:string;customPrompt:boolean;intensity:string;state:string}[]};
    let pack=await (await page.request.get('/api/image/expression-pack')).json() as View;
    expect(pack.slots.some(s=>s.state==='done')).toBe(true);
    expect(pack.slots.find(s=>s.emotion==='joy')?.customPrompt).toBe(false);
    await panel.getByLabel('Intensity for joy').selectOption('strong');
    await expect(panel.getByLabel('Prompt for joy')).toHaveValue(/strongly raised cheeks/);
    await retry.click(); await expect(retry).toBeEnabled({timeout:10 * 60_000});
    pack=await (await page.request.get('/api/image/expression-pack')).json() as View;
    expect(pack.slots.find(s=>s.emotion==='joy')?.intensity).toBe('strong');
    await panel.getByRole('button',{name:'Edit pack prompt rules...',exact:true}).click();
    const dialog=page.locator('dialog'); await expect(dialog).toContainText('strongly raised cheeks');
    await dialog.getByRole('button',{name:'Cancel',exact:true}).click();
  } finally {
    await page.request.post('/api/image/expression-pack/cancel',{data:{}});
    await expect.poll(async()=> (await (await page.request.get('/api/image/expression-pack')).json() as {running?:boolean}).running ?? false).toBe(false);
    await page.request.post('/api/image/expression-pack/discard',{data:{}});
    await page.request.post('/api/image/config',{data:{backend:saved.backend,localUrl:saved.localUrl,currentPassword:process.env.FPAI_PASSWORD}});
  }
});
