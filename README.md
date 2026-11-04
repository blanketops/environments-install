# BlanketOps Environments Install

## Overview

BlanketOps Environments Install provides the declarative installation manifests for BlanketOps Environments.


⚠️ CRDs in this repo are artifacts, not sources of truth.
They are generated and versioned in the API repository, then vendored here.

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
