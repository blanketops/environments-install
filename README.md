# Blanketops Environments Install

## Overview

Blanketops Environments Install provides the `declarative` `installation` `manifests` for BlanketOps Environments.

This repository is install-only.
It exists to make installing, upgrading, and removing BlanketOps Environments `boring`, `repeatable`, and `explicit`.

It contains:

- CustomResourceDefinitions (CRDs)
- RBAC definitions
- Controller deployment manifests
- Network and monitoring configuration
- Kustomize overlays

It does not contain:

- Go code
- controllers or reconciliation logic
- CRD source definitions
- image build tooling

## Repository Scope & Boundaries

This repository is intentionally limited in scope.

BlanketOps Environments is split into three layers:

```txt
blanketops-environments-api
└─ owns CRD schemas and Go types

blanketops-environments-operator
└─ owns controllers and runtime logic

blanketops-environments-install ← this repo
└─ owns installation manifests only
```

This separation ensures:

- APIs evolve independently
- operators are replaceable
- installs remain stable and auditable

## Directory Structure

```tree
.
├── bin/ # Local tooling (kustomize only)
├── config/
│ ├── crd/ # Vendored CRDs
│ ├── rbac/ # Roles, role bindings, service accounts
│ ├── manager/ # Controller deployment manifests
│ ├── default/ # Default install overlay
│ ├── network-policy/ # Network policies
│ └── prometheus/ # Metrics and monitoring
├── Makefile # Install and validation targets
└── README.md
```

⚠️ CRDs in this repo are artifacts, not sources of truth.
They are generated and versioned in the API repository, then vendored here.

---

## Tooling Requirements

End users need:

- `kubectl`
- access to a Kubernetes cluster

This repository vendors kustomize locally for reproducibility.
No Go toolchain is required.

## Common Operations

### Show available commands

```Makefile
make help
```

Render manifests (no cluster access required)

```Makefile
make build
```

Render CRDs only:

```Makefile
make build-crds
```

### Validate against a cluster (server-side dry run)

```Makefile
make validate
```

This does not persist any resources.

---

Install CRDs

```Makefile
make install
```

### Deploy BlanketOps Environments

```
make deploy
```

This applies:

- CRDs
- RBAC
- Controller deployment
- Supporting resources

### Show diff against live cluster

```Makefile
make diff
```

### Uninstall

Remove deployed resources:

```Makefile
make undeploy
```

Remove CRDs:

```Makefile
make uninstall
```

### Generating a Single Install Bundle

To produce a single, consolidated YAML file:

```Makefile
make build-installer
```

This creates:

```sh
dist/install.yaml
```

Users can then install BlanketOps Environments with:

```sh
kubectl apply -f install.yaml
```

This is useful for:

- Air-gapped environments
- GitOps pipelines
- Release artifacts
- Versioning & Releases

---

## Versioning & Releases

- This repository pins CRD versions and operator image tags

- Releases should align with compatible versions of:
  - `blanketops-environments-api`
  - `blanketops-environments-operator`

No code is built here — releases are purely `manifest updates`.

```

```
