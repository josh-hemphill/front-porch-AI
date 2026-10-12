# Windows ONNX runtime compatibility

Kokoro, Piper and Whisper share the Windows ONNX runtime with the other in-process
ONNX consumers. Sherpa's native library and its runtime must be bundled together.
The native-assets install step must not overwrite that runtime with an older DLL.

## Repair slices

1. Select Sherpa's runtime and matching provider DLLs for the Windows bundle,
   exclude competing same-name runtime files from plugin/native asset copying,
   and fail configuration if the required runtime is missing. Exercise the real
   CMake install flow and validate the finished bundle with synthetic speech.
2. Before initializing Sherpa on Windows, inspect the already-loaded ONNX runtime
   or preload the bundled runtime, require the C API used by the pinned Sherpa
   build (currently 28), and throw a descriptive error if incompatible. Verify
   rejection with a real older runtime and acceptance with the matching runtime.

The CMake change owns windows/CMakeLists.txt and a focused helper. The runtime
change owns the shared Sherpa loader, a Windows-only helper and a new native test.
No existing tests or dependency versions need to change. Chat-path matrices are
not applicable: no chat, generation orchestration or storage behavior changes.
No chat files or crash dump memory are used. Reproductions use fixed synthetic
text in a separate process. Independent reduced-context review follows both
slices. Run touched Dart analysis, native tests, Windows build and synthetic
speech using the final staged libraries. Keep existing user sessions intact.

## Verification

The incompatible bundled runtime reproduced the same native fault offset using
fixed synthetic text. Preloading the matching runtime completed six generations.
The new process-loaded-runtime rejection test was red before the guard and green
afterwards. All four native guard cases pass against real DLLs, including the
rebuilt bundle. The Windows release build passes and its runtime hashes match
Sherpa's source runtime (1.28.2). The other ONNX binding initializes alongside
Kokoro, and the production Kokoro worker generates a synthetic WAV successfully.
Touched Dart analysis is clean. The broader speech regression run has 15 passes
and five explicit model-fixture skips; the real Kokoro case is separately run and
passes. An unchanged macOS path test uses host-platform path joining with a
literal forward-slash expectation, so it fails on Windows; no protected test is
modified to hide that failure. Independent reduced-context review has no required
findings. Reporting the Windows GetLastError code on library load failure is a
possible later diagnostic improvement.

The API floor must be reviewed when changing the pinned Sherpa native dependency.
No chat records, preferences, crash dump memory or user speech were read. Existing
chat paths and web UI are unchanged; shared server-side speech uses the repaired
Windows process runtime.

## Local check

1. Start the rebuilt Windows executable with Kokoro enabled.
2. Generate a short reply or use a voice preview and confirm audio plays.
3. Repeat the workload that previously triggered the crash. If another failure
   occurs, collect only its process/module/exception metadata before investigating.
The size ratchet passes. The existing part-file ratchet additionally reports
unrecorded part directives in expression-pack and image-batch files already on
this branch; this repair adds no part directives and leaves those files and
protected baselines unchanged. These unrelated checks are not reported as green.
