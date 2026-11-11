# Primary framework: HIPAA Security Rule

## Why HIPAA
- The Patient Intake API collects PHI today, so HIPAA is a legal requirement now.
  SOC 2 (one customer request) and CMMC (a possible federal pilot) are not.
- CMMC protects CUI (federal contract data). Patient intake data is PHI, not CUI.
- HIPAA technical safeguards cover 7 of the 8 starter gaps (GAP-06 is availability/monitoring,
  documented as a secondary SOC 2 CC7.2 reference).

## How it is used in each layer
- Rego policies: `custom.framework: hipaa` and `controls:` lists 45 CFR 164.x IDs.
- OSCAL: catalog = NIST SP 800-66 Rev. 2; HIPAA 164.x IDs as props;
  SOC 2 / CMMC IDs as secondary props only.

## Trade-off accepted
No official HIPAA OSCAL catalog exists, so the chain cites NIST SP 800-66r2.

HIPAA is federally mandated requirement for all healthcare providers to keep patient data secret.