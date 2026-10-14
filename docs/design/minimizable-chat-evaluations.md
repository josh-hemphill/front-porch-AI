# Minimizable chat evaluations

Proposal for issue #461. Desktop keeps the current prominent evaluation panel by
default. Minimize evaluation replaces it with a compact status bar over the chat;
Show evaluation details restores the panel. Web/mobile exposes the same actions
within its existing progress card. The transcript can be read while minimized.

## Discussion concerns

- Keep ongoing work visible for new users: expanded remains the default, and
  minimizing retains a spinner and the active phase rather than hiding activity.
- Let users review chat during long calls: only the compact bar intercepts
  pointers after minimizing; the transcript is accessible.
- Avoid trapping users in initialization or verification screens: the minimize
  control is outside the existing phase panel and is available without streamed
  text. It does not depend on the panel exposing a cancellation button.
- Keep existing cancellation semantics: Stop this reply retains the Realism
  cancellation path; Skip goal check retains the objective-only skip path.
  Verification-only phases can be minimized without claiming a new abort path.
- Confirm that a slow call is still waiting: show elapsed time after 30 seconds.
  This measures the current visible evaluation sequence, including phase changes,
  not backend token throughput or an estimated time remaining.
- Avoid extra sidebar/global indicators: this change stays in the chat surface.

Minimized presentation lasts for the active evaluation sequence. Finishing that
sequence or switching chats resets the expanded default. This is UI state only;
no settings, stored messages, prompt content, scoring, or scheduling change.
Generation/edit controls retain their existing busy-state guards. Minimizing does
not allow concurrent sends or make evaluations independent background jobs.

## Path-complete checklist

| Turn event | Result |
| --- | --- |
| Normal send, 1:1 | Presentation only; existing eval order, deltas and receipts unchanged. |
| Normal send, group | Uses the same desktop/web presentation; speaker ownership unchanged. |
| Continue | No clock, prompt or state mutation; shows only phases already emitted. |
| Regenerate | Rewind/reapplication unchanged; shows only phases already emitted. |
| Swipe | Stored alternate state unchanged. |
| Delete | Transcript/state rewind unchanged. |
| Edit history | Rewrite and cursor behavior unchanged. |

Prompt matrix: N/A; this proposal never constructs or modifies a prompt.
Twins checked: Realism/greeting/verification vs objective, desktop vs web,
1:1 vs group via the shared chat overlay builder. Journal/Growth/Pockets/RAG
state and persistence are not changed. No profile data is required to test it.

## Verification and manual poke

New Flutter and web interaction guards exercise minimize/expand, unchanged
cancel/skip callbacks, elapsed-time visibility, and reset after inactivity.
The Flutter guard verifies interaction with the underlying transcript while
minimized. Both guards must fail if the minimize handler is disabled.

1. Enable Realism or objectives in a synthetic chat and send a message; confirm
   the expanded progress view appears as before.
2. During initialization or streaming, minimize, scroll the transcript, and
   restore details. Confirm the request continued throughout.
3. Minimize again and use Stop this reply or Skip goal check as appropriate;
   verify their existing distinct effects.
4. For a call longer than 30 seconds, check elapsed time. Switch chats or finish
   the evaluation and confirm a later evaluation opens expanded.
5. Repeat on phone web and a group chat. Confirm sending stays protected while
   evaluation is active.
