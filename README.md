# Sandbox Scala BA 2025-06

This repository contains an empty Scala sandbox setup.

## Continuous Integration

A GitHub Actions workflow automatically checks code formatting and executes the test suite on every push or pull request targeting the `main` branch. The workflow is defined in `.github/workflows/ci.yml` and runs `sbt scalafmtCheckAll` to verify formatting and `sbt test` to ensure that the codebase works before changes are merged.
