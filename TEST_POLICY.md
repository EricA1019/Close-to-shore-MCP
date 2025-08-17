## Test Suite Policy

This document defines which tests belong in the canonical test suites and which belong in the `scenes/tests/scratch/` folder for situational, flaky, or exploratory tests.

Rules for adding tests to the suite:

- Integration tests (`scenes/tests/integration/`):
  - Must be deterministic and reproducible in a headless GUT run.
  - Must assert observable, user-facing behavior (scene composition, UI presence, input flows) not internal implementation details.
  - Should not rely on manual editor state, intermittent native imports, or local machine-specific resources.
  - Must avoid relying on timing-sensitive heuristics; prefer awaiting frames or signals.

- Unit tests (`scenes/tests/unit/`):
  - Small, fast, and isolated. Mock or stub heavy dependencies.
  - Cover public interfaces and data transformations.

- Smoke tests (`scenes/tests/smoke/`):
  - Minimal end-to-end checks that ensure the project boots and core scenes load without fatal errors.

- Scratch tests (`scenes/tests/scratch/`):
  - For experiments, reproducing bugs, performance/fuzzing checks, and flaky tests.
  - Not run by default in CI or headless developer runs.
  - May be promoted to integration/unit after being stabilized and reviewed.

Criteria for promoting a scratch test:

1. The test passes reliably across at least 5 repeated headless runs on the same machine.
2. The test does not require changing import state or native extension rebuilds to succeed.
3. The test asserts behavior that a user would rely on (not internal timings or ephemeral editor state).

Process for adding tests to the suite:

1. Add the test to `scenes/tests/scratch/` and iterate until stable.
2. Open a PR that includes the test and a short justification referencing the acceptance criteria above.
3. Obtain one review approving the promotion. The test will be moved to the appropriate suite folder.

CI and Task Runner behavior:

- The default GUT tasks in `.vscode/tasks.json` run the `scenes/tests` folder. Maintainers should ensure `.vscode/tasks.json` uses `-gdir=res://scenes/tests/integration` for fast team runs or configure CI to run a curated set of suites.

This policy aims to keep the canonical test suite fast, reliable, and focused on user-facing behavior while preserving a place for experimentation.
