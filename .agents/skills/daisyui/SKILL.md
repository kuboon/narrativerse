---
name: daisyui
description: 'Build and refactor Rails ERB UI with Tailwind CSS v4 + daisyUI v5 in this repository. Use when creating pages, panels, forms, and buttons with consistent theme classes and responsive behavior.'
argument-hint: 'What screen or component should be built or restyled with daisyUI?'
---

# daisyUI Workflow For Narrativerse

## Outcome
Produce production-ready UI updates in Rails views using daisyUI + Tailwind that match this project's visual language and compile cleanly.

## When To Use
- Building or restyling ERB views and partials
- Creating consistent forms, panels, cards, and action rows
- Updating theme-aware classes for light/dark support
- Fixing Tailwind/daisyUI styling regressions

## Procedure
1. Confirm the target file and UX goal.
2. Inspect nearby view patterns first so new markup stays consistent.
3. Apply daisyUI component classes in ERB templates (for example `btn`, `card`, `badge`, `link`).
4. Add project-specific styling in `app/assets/stylesheets/application.tailwind.css`.
5. Use `@apply` with Tailwind utility classes only.
6. Keep generated CSS untouched; do not hand-edit `app/assets/builds/application.css`.
7. Verify desktop and mobile layouts after the change.
8. Rebuild CSS and check for compile issues.

## Decision Points
- If a style can be expressed with existing daisyUI classes: keep it in template markup.
- If a custom pattern repeats across multiple views: create a semantic class in `application.tailwind.css` and compose it from Tailwind utilities.
- If a one-off tweak is needed in one view: keep it inline with utility classes in that template.
- If build fails with `unknown utility` around daisyUI component names: remove component-class usage from `@apply` and move those classes back into ERB markup.

## Quality Checks
- Uses Tailwind v4 + daisyUI v5 compatible patterns
- Take reusable class sets into  `@apply`
- Visual consistency with existing theme variables and component styling
- Works on desktop and mobile
- CSS build succeeds without warnings/errors

## Resources
- [daisyui](https://daisyui.com/llms.txt)

## Validation Commands
- `npm run build:css`
