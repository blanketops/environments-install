# BlanketOps Environments Install

## Overview

BlanketOps Environments Install provides the declarative installation manifests for BlanketOps Environments.

---

## Tooling Requirements

End users need:

- `kubectl`
- access to a Kubernetes cluster

This repository vendors kustomize locally for reproducibility.
No Go toolchain is required.

This is useful for:

- Air-gapped environments
- GitOps pipelines
- Release artifacts
- Versioning & Releases

---

## Versioning & Releases

- This repository pins CRD versions and operator image tags.
- No code is built here — releases are purely manifest updates.
- Releases should align with compatible versions of:
  - `environments-api`
  - `environments-controller`
---

## License

Apache License 2.0 — see [LICENSE](LICENSE) for details.
