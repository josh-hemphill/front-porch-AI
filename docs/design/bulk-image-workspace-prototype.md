# Bulk image workspace prototype

The **Images** navigation entry offers Prepare, Queue, and Review views on
desktop and web. Generation belongs to an app service, so navigating away
does not stop the queue. The desktop app must remain open.

## Prepare

Select several characters and choose the save destination:

- **Primary portrait:** replaces the character's portrait only after review
  and an explicit replacement confirmation.
- **Expressions:** prepares the starter eight expressions, optionally only
  missing labels, using the existing expression prompts and global rules.
- **Additional portraits:** saves situational images to the character gallery.
  These remain separate from both the primary portrait and expressions, even
  when a character has no usable primary portrait.

The prompt accepts `{character}` for each character's name. Additional and
primary images can use the current portrait as an Edit source. Sources,
prompts, seeds, and destination identities are captured during preparation.

## Run and review

Requests run sequentially under the existing image-generation lock. Pause
finishes the current request. Completed candidates can be kept, discarded,
or retried while later requests generate. A retry is added to the next pass
with an editable prompt and an optional new seed; it retains the original
candidate. Save kept imports only selected results.

The queue and candidate files persist in the active data directory's
`ImageBatches` folder. A request interrupted by app exit is marked interrupted
rather than submitted again automatically. Gallery imports use the job's
identity to avoid duplicate entries when saving is retried.

## Prototype boundaries

- One queue and the existing Image Studio configuration; no named batches or
  independent generation profiles yet. A configuration fingerprint pauses
  waiting jobs when settings differ. It does not restore a configuration.
- The starter eight expressions are supported. Local expression rule editing,
  per-request strength editing, richer character filters, and source comparison
  are future iterations. Strength comes from Image Studio settings; existing
  model-specific handling still applies.
- Expression candidates are added as gallery entries with their labels;
  existing expressions are not deleted. Only-missing is the default.
- Discard hides a request but retains its artifacts. Artifact cleanup,
  storage budgeting, and queue export are not implemented.
- Primary saves preserve existing character-card metadata using the current
  portrait writer. Its existing size limits remain in effect.

## Local checks

1. Configure Image Studio, open Images, and prepare additional portraits for
   two synthetic characters. Verify the destination and captured prompts.
2. Start, leave the page, return, and pause after the current image. Confirm
   completed candidates remain available and waiting requests stay queued.
3. Keep and save one candidate. Confirm it appears among additional portraits
   and the primary portrait is unchanged. Retry another with a changed prompt.
4. Restart before another pass. Confirm the queue loads without automatically
   sending interrupted requests. Change model settings and verify waiting work
   refuses to run under a different configuration.

The isolated demonstration uses temporary storage, a test database, mock
preferences, and a synthetic image producer. It exercises production queue,
UI, and web routes; it does not validate model quality or an external backend.
Build the web bundle, set `FPAI_REVIEW_IMAGES` to an output folder, and run
`flutter test integration_test/image_batches_demo.local_poke.dart -d windows`.
The local capture driver is ignored by Git, following the repository's local
poke convention.
