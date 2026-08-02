# LingBi Product-First Free-Style Redesign

Date: 2026-07-28

Status: approved direction, pending written-spec review

## Objective

Redesign the existing Open Design project `lingbi-windows-code-grounded-full-suite` so its default experience looks and behaves like a real LingBi Windows application rather than a design-board factory or component showcase.

Open Design chooses the visual direction. This specification deliberately does not prescribe a named design style, palette, typography family, corner radius, shadow system, density, or component aesthetic.

## Product-first artifact structure

The current visible board index, preview-width controls, and previous/next board controls are review tooling. They must not appear in the default product artifact.

The project will expose two distinct surfaces:

1. A default product artifact that opens directly into a full-width LingBi application interface.
2. A separate internal review artifact that preserves access to all 24 code-grounded product states for design inspection and traceability.

Review navigation may be freely redesigned, but it must remain outside the default product experience.

## Creative freedom

Open Design may freely choose and consistently apply:

- overall visual language;
- information hierarchy and page composition;
- typography, color, spacing, density, shape, iconography, and motion;
- navigation presentation and component treatment;
- how the application feels distinctive, current, and appropriate for a serious desktop writing tool.

The redesign should avoid the appearance of a generic dashboard template, a component gallery, or an automatically generated admin system. The result should feel authored as one coherent product.

## Product truth constraints

Creative freedom does not authorize invented product capabilities. The redesign must remain grounded in the existing LingBi code facts and preserve:

- the real project areas `overview / writing / ideation / review / publish`;
- the project assets `protagonist / worldRules / outline / openingScene / firstChapter`;
- the first-chapter safety chain: candidate generation, explicit confirmation, atomic adoption, and recovery;
- truthful maturity distinctions, including unavailable, planned, partial, disabled, and externally blocked behavior;
- local-first and Windows-desktop product context;
- privacy-sensitive behavior, including telemetry remaining off by default;
- the code-entry and service-boundary traceability already established for the 24 states.

Open Design may reorganize how these truths are presented, but must not silently upgrade partial or planned features into fully working features.

## Deliverables

- A polished default product artifact with no visible review shell.
- A separate internal review artifact covering all 24 existing states.
- A clear declaration of the visual direction selected by Open Design and why it suits LingBi.
- Consistent treatment across startup, onboarding, writing, ideation, review, publishing, recovery, marketplace, and settings surfaces.
- Functional navigation within the artifact sufficient to evaluate the chosen product structure and representative state transitions.

## Acceptance criteria

- The first viewport reads unmistakably as a real LingBi application.
- No board index, board number, code annotation, preview-width selector, or previous/next review control is visible in the default product experience.
- The primary application navigation is product-native and limited to genuine LingBi destinations.
- The redesign is materially more coherent and visually intentional than the current artifact, not merely a color or spacing pass.
- All 24 states remain available in the separate review surface and retain their code/service/maturity traceability.
- The product artifact remains usable at Windows desktop widths from 1280 through 1920 pixels.
- No existing business flow is removed solely to simplify the visual redesign.

## Out of scope

- Flutter implementation.
- Changes to LingBi business logic, services, tests, or repository architecture.
- New product features not supported by the current code-grounded fact pack.
- A mobile redesign.
