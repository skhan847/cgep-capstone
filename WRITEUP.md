# Capstone write-up: Acme Health Patient Intake API

- Primary framework: HIPAA Security Rule (why: `docs/FRAMEWORK.md`)
- OSCAL catalog: NIST SP 800-66 Rev. 2, component in `oscal/component-definition.json`
- Architecture: `docs/ARCHITECTURE.md`

## Gaps: which layer, and where

| Gap | Status | Layer 1: Terraform | Layer 2: Rego policy | Layer 4: OSCAL control-id |
|---|---|---|---|---|
| GAP-01 S3 CMK | Closed | `terraform/grc_kms.tf` | `policies/hipaa_s3_cmk.rego` | `hipaa-164.312.a.2.iv` |
| GAP-02 DynamoDB CMK | Closed | `terraform/main.tf` (`server_side_encryption`) | `policies/hipaa_dynamodb_cmk.rego` | `hipaa-164.312.a.2.iv` |
| GAP-03 TLS-only | Closed | `terraform/grc_s3_hardening.tf` | `policies/hipaa_s3_tls.rego` | `hipaa-164.312.e.1` |
| GAP-04 Versioning | Closed | `terraform/grc_s3_hardening.tf` | `policies/hipaa_s3_versioning.rego` | `hipaa-164.308.a.7.ii.a` |
| GAP-05 Lambda not in VPC | Open, planned | none yet | none yet | `hipaa-164.312.e.1` (partial) |
| GAP-06 No DLQ / X-Ray / concurrency | Open, planned | none yet | none yet | none (SOC 2 / CMMC only, no HIPAA control) |
| GAP-07 Wildcard IAM | Closed | `terraform/grc_iam_least_privilege.tf` | `policies/hipaa_iam_least_privilege.rego` | `hipaa-164.312.a.1` |
| GAP-08 API logging / WAF | Open, planned | none yet | none yet | `hipaa-164.312.b` (partial) |

Why two layers for the closed gaps: Terraform remediates the current state to make it compliant today, while Rego enforces policy-as-code so no change through the pipeline can take it out of compliance tomorrow.

Why some gaps stay open: not every gap can be fixed in one pass, and transparency builds auditor trust. GAP-05, 06 and 08 are named in OSCAL as open items with a plan, not hidden.

## Proof the gate works (Layer 3)

- PR #1 passed the gate and was merged. The run on main shows all 5 named steps green: `docs/layer3/pipeline-main-green.png`
- PR #3 re-introduced `dynamodb:*`. Conftest failed with `GAP-07 [HIPAA 164.312(a)(1)]` and the merge was blocked by branch protection: `docs/layer3/pr-b-blocked.png`, `docs/layer3/pr-b-conftest-fail.png`
- PR #2 and PR #4 also went through the same required check before merging.

## How to check it yourself

From the repo root, with Terraform and Conftest installed, and either AWS credentials or a running Moto plus the `moto_override.tf` that the pipeline writes in its setup step:

    terraform -chdir=terraform init
    terraform -chdir=terraform plan -out=tfplan
    terraform -chdir=terraform show -json tfplan > terraform/plan.json
    conftest test --all-namespaces -p policies terraform/plan.json

Expected: 6 tests, 6 passed. Change `"dynamodb:PutItem"` to `"dynamodb:*"` in `terraform/grc_iam_least_privilege.tf` and re-run: 1 failure.

## Limitations (honest list)

- Everything ran on Moto (a local AWS emulator), not a real AWS account. Proof of the deploy gate is in `docs/deploy-gate/`.
- Moto cannot run Lambda without Docker, so the API Gateway to Lambda path was not exercised; `handler.py` was called directly.
- Moto does not write CloudTrail log files, so the trail is configured and logging but no log objects exist.
- Moto ignores the `aws:SecureTransport` condition and treats the TLS-only Deny as "deny all". Pipeline step 5 lifts the vault policy, uploads, then restores it and checks it with `diff` (marked MOTO ONLY). Real AWS would not need this.
- Rego only checks changes that go through the pipeline. Manual console drift would need a tool like AWS Config.
- The vault uses Object Lock GOVERNANCE mode, which a privileged admin can bypass. Production should use COMPLIANCE mode.
- Retention is a fixed 6 years from upload; HIPAA says "whichever is later", so long-lived policy documents need longer retention.
- Trivy config scan is report-only for now.

## AI assistance

Code, pipeline and OSCAL were drafted with help from Claude. I typed, ran and verified every step, and the explanations are my own words.
