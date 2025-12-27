# Botswana company KYC research (sources + app mapping)

Date: 2025-12-13

This note records the minimum set of documents/fields we require for a company to be verified in the app, anchored to official/credible Botswana sources where available.

## CIPA (Companies and Intellectual Property Authority)

### Beneficial ownership information
- CIPA states that, in addition to director/shareholder details, applicants are required to provide names/addresses/details of all beneficial owners and declare the nature of their interest.
- Source: https://www.cipa.co.bw/beneficial-owner

**App mapping**
- Required upload: `beneficial_ownership` (Beneficial Ownership Declaration).

### Company registration documents
- CIPA Online Business Registration System (OBRS) supports viewing certificates/extracts.
- Source entry point: https://www.cipa.co.bw/ (OBRS links), plus guides listed on https://www.cipa.co.bw/information-center

**App mapping**
- Required uploads (practical verification set):
  - `cipa_certificate`
  - `cipa_extract`

## BURS (Botswana Unified Revenue Service)

### TIN (Taxpayer Identification Number)
- BURS publishes a downloadable “TIN Application Form”.
- Source (download link): http://burs.org.bw/index.php/treaties-and-legislation/category/10-general-downloads?download=39:tin-application-form
- Workspace artifact (downloaded for reproducibility): `research/botswana_kyc/burs_tin_application_form.pdf`

**App mapping**
- Required upload: `burs_tin` (TIN Evidence).

## General business verification (practical, non-registry)

### Director identity (Omang/ID)
- We require a director identity document (Omang/ID) as a practical control to reduce fraudulent company profiles. This is not a registry-issued company document; it supports manual admin review.

**App mapping**
- Required upload: `director_id` (Director Omang/ID).

### Proof of business address
- Proof of address is a standard KYC item used to corroborate operational presence.

**App mapping**
- Required upload: `proof_of_address` (Proof of Business Address).

## Current required uploads in-app

The app currently treats the following as REQUIRED for KYC submission:
- `cipa_certificate`
- `cipa_extract`
- `beneficial_ownership`
- `director_id`
- `burs_tin`
- `proof_of_address`

Optional uploads remain:
- `directors_list`
- `authority_letter`

## Gap analysis vs current implementation (practicality)

### Covered end-to-end (no remaining blockers)
- **Required docs**: CIPA certificate + extract + beneficial ownership declaration + director Omang/ID + BURS TIN evidence + proof of address are all enforced in the company submission UI and enforced again by Firestore rules.
- **Admin review**: Admin screens can view all required/optional KYC docs and approve/reject with a reason.
- **Notifications**:
  - On submission, admins receive a notification.
  - On approve/reject, the company receives a notification (push/email via `notifyUser`, with in-app fallback).
- **Workflow locks**: Once submitted, companies cannot edit KYC until a decision is made.

### Known limitations (intentional for minimal UX)
- **Beneficial ownership “details”** are not stored as structured fields (names/addresses/nature of interest). We accept a declaration document upload instead.
- The app does not attempt to validate document authenticity (e.g., verifying registration numbers online); admin review is the control.

### Optional improvements (not required for the minimal workflow)
- Capture “Company registration number” and “TIN number” as text fields to make admin review faster (documents already contain these, so this is convenience only).
