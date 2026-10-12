# KoboldCpp reasoning-off tool compatibility

## Failure and scope

KoboldCpp 1.122.1 maps `reasoning_effort: none` to a zero token budget.
Negative budgets are unrestricted. Its sampler can inject reasoning closing
tokens before applying the output grammar, then feed those tokens to the
grammar and assert that the grammar stack is not empty.

A synthetic prompt containing an open `<think>` marker reproduced the reported
`gpttype_adapter.cpp:2485` assertion in a separate CPU-only engine. The test
model had no embedded chat template. Enabling `jinja_tools` alone therefore
still reached the legacy grammar path and did not fix that reproduction.

## Compatibility path

For a managed backend whose loaded staged configuration enables both Jinja
and Jinja tools, a non-generating token-count request checks the effective
rendered prompt. The first advertised function is named explicitly for this
check, avoiding the legacy auto selector's internal generation. Older engines
that return only token IDs use detokenization to inspect that same rendering.
A recognized Qwen assistant prefix with a closed empty think block and the
advertised tools keeps the ordinary native tool path. Missing templates,
failed rendering, forced-open thinking, unsupported prefix formats and
unverified external launch flags keep the compatibility path. There is no
cross-model cache: each request is checked against the currently loaded
backend, including after swaps and restarts. Raw prompt data is never logged
by this verification. The probe has a bounded wait and cannot crash-test the
backend by sampling.

Reasoning-off Kobold tool requests on the compatibility path retain their original budget, samplers,
conversation, cancellation client and token limit. They request a JSON object
with tool selections as ordinary text, without native tools or constrained
output fields on the wire. Responses are converted to the existing
`LlmToolResponse`, restricted to advertised functions and any named choice.
Auto may return no calls; malformed output remains eligible for the existing
caller fallback. Streamed requests retain progress and cancellation.

The decoder consumes the first complete JSON object, so repeated fenced
answers do not duplicate operations. Quoted braces and escapes do not close
an object early. Truncated objects cannot execute a call. Empty call IDs let
the existing clerk assign distinct round IDs. Existing operation handlers
still own argument validation. Soft prompting does not guarantee schema
adherence as constrained decoding does.

Staged managed-engine configs also enable `jinja_tools`, so models with a
working template preserve that template during ordinary native tool requests.
Original preset files are unchanged. Remote providers use their existing
transport. No setting, profile migration or new UI is added. A preset template picker
  belongs in a separate desktop/web PR; it should select or clear a local
  `.jinja` path, preserve it through preset read/save/copy, and explain the
  restart requirement. The compatibility
path applies to both desktop and web because they use the same Dart services.

This targets reasoning-off calls. Native calls with reasoning enabled keep
the existing path; an upstream grammar-safe budget implementation is still
needed to address the general finite-budget interaction.

## Verification

- New staging guards failed before the launch change and passed afterward.
- Real isolated KoboldCpp 1.122.1 reproduced the original assertion.
- Real HTTP tests prove native bypass with the supplied matching template
  and compatibility fallback without a template; the bypass guard was
  deliberately disabled and failed before being restored.
- Real HTTP tests cover buffered and streamed reasoning-off tools with and
  without the triggering marker, ordinary text, and a synthetic book lookup
  followed by a tool result and an empty follow-up selection.
- Unit guards cover output-field removal, preserving source payloads,
  repeated fenced responses, malformed calls, named choices and opt-in
  reasoning salvage.
- The existing launch argument test has a Windows mixed-separator failure
  with and without this change. Its permitted-overlay expectation changes
  only for the newly app-owned `jinja_tools` field.
- All model inputs and generated outputs used synthetic data in an isolated
  engine. No primary-profile chats, database, preferences or logs were read.

## Path-complete checklist

| Turn event | Status |
| --- | --- |
| Normal send, 1:1 | Shared request transport; no state or receipts changed |
| Normal send, group per speaker | Same shared request transport; no speaker state changed |
| Continue | Existing text stream and suppression retained; no clock/finalize changes |
| Regenerate | Same transport; rewind and reapplication untouched |
| Swipe | No alternate state changed |
| Delete bot/user tail | No transcript or saved state changed |
| Edit history | No rewrite or stored state changed |

Prompt paths: full generation, Continue suffix, overflow and impersonate
history builders are unchanged. The compatibility instruction is confined to
the separate tool request; it does not alter mouth prompts or history.

Twins checked: the shared scalar-eval wiring, clerk/catalog dispatch,
Journal/Growth structured negotiation, character-creator tool calls and
story/world tool callers. Desktop and web use the same service.

## Isolated poke script

1. Launch a dedicated QA profile and backend with synthetic characters.
2. Keep Native tool calling on and reasoning off; send a message requiring a
   synthetic lore lookup and a Realism evaluation.
3. Confirm the lookup completes and the backend survives, then test Continue.
4. Repeat for a synthetic group chat and cancel an active evaluation; confirm
   another request still works. Repeat the send from the companion web UI.

These full UI pokes remain manual; the automated evidence is transport-level.
