## What

<!-- One or two sentences. What does this PR change? -->

## Why

<!-- The intent. Link the issue if one exists: Closes #123 -->

## Area

<!-- Mark all that apply -->

* [ ] CRDs (vendored from `environments-api`)
* [ ] RBAC (`config/rbac`)
* [ ] Controller-manager deployment (`config/manager`)
* [ ] Network policy / Prometheus monitoring
* [ ] Kustomize overlay (`config/default`)
* [ ] CI / release tooling / docs

## Version sync

<!-- This repo vendors CRDs and stamps environments.blanketops.dev/* version labels -- check these are current, not just "some version" -->

* [ ] `controller-version` label matches the `environments-controller` release this targets
* [ ] `contract-version` label matches the `environments-contract` release this targets
* [ ] `api-version` label matches the `environments-api` release this targets
* [ ] `operator-version` label matches the `environments` release this targets
* [ ] CRDs re-vendored from `environments-api` if schemas changed

## Checklist

* [ ] `make build` renders cleanly (no cluster access required)
* [ ] `make build-installer` regenerates `dist/install.yaml` and it's committed
* [ ] `make validate` passes against a real cluster, if touching RBAC or manager manifests
* [ ] Commit messages follow Conventional Commits

## Notes for reviewer

<!-- Anything non-obvious: design trade-offs, deferred follow-ups, areas needing close attention -->
