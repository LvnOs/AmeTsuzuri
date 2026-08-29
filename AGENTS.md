# Project Agent Instructions

This file applies to the entire repository.

## Communication

- Communicate with the user in Japanese unless they request another language.
- When reporting completed implementation work, state the changed files and the
  verification commands that were actually run, including failures or omitted
  checks. Do not describe an unexecuted check as successful.
- If an unexpected stop, unexplained delay, process conflict, environment issue,
  or unusual retry occurs while executing a task, append the following section at
  the very end of the final report. Omit the section when none occurred.
- Time spent waiting only for explicit user approval is not an unexpected stop.

```text
## 想定外の停止事項

- 発生内容：
- 影響：
- 暫定対応：
- 別途調査が必要な事項：
```

## Flutter and Dart Commands

- The Flutter SDK is installed at `C:\Develop\flutter`, outside the normal
  workspace-write sandbox. Flutter CLI startup can require writes under the SDK
  cache even for commands such as `flutter --version`.
- Run Flutter validation commands with the required external-write permission
  from the outset when the execution environment requires it. A sandboxed
  Flutter command that produces no output may be blocked on SDK cache access; do
  not immediately treat it as a test or source-code failure.
- Do not persist `FLUTTER_ALREADY_LOCKED=true` as a user or system environment
  variable. Do not use it as the default workaround for startup problems.
- The mere presence of `C:\Develop\flutter\bin\cache\lockfile` does not prove a
  live lock conflict. Confirm the owning process or command line before acting.
- VS Code may legitimately run the Flutter debug adapter, `flutter run`, the Dart
  analysis server, frontend server, and DDS. Do not terminate all Dart or Flutter
  processes indiscriminately. Identify and stop only a demonstrably stale or
  conflicting process when necessary.
- Direct Dart commands may also attempt to write analytics or cache data outside
  the workspace. If that is blocked, use an approved execution context or a
  task-scoped writable location; do not change global user settings without the
  user's request.

## Repository Safety

- Preserve pre-existing and unrelated working-tree changes. Inspect the current
  diff before editing overlapping files, and never discard user changes to make
  tests pass.
- Keep implementation scope aligned with the user's request. Do not broaden a
  focused UI or behavior change into unrelated Weather, Letter, Room, tutorial,
  asset, or data changes without explicit authorization.
- Use `apply_patch` for hand-authored file changes.
