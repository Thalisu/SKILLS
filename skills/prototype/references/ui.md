# UI prototype

Three structurally different variants of one screen, on one route, switchable from a floating
bottom bar. The reader flips between them in the browser, picks one, or steals bits from each, and
throws the rest away.

When the question is about logic or state rather than what something looks like, this is the wrong
shape: use `logic.md`.

## When this is the right shape

- "What should this page look like?"
- "I want to see a few options for this dashboard before committing."
- "Try a different layout for the settings screen."
- Any time the reader would otherwise spend a day picking between three vague mockups in their
  head.

## Where the variants live: strongly prefer the existing route

A variant is far easier to judge when it butts up against the rest of the app: real header, real
sidebar, real data, real density. A throwaway route on its own is a vacuum, and every variant looks
fine in a vacuum.

| Situation | Where |
|---|---|
| the screen has a route already | on that route, gated by `?variant=`; the existing data fetching, params and auth stay, only the rendered subtree swaps |
| the thing is new but would naturally sit inside an existing page (a new section, a new card, a new step in an existing flow) | inside that host page, same gate |
| an entirely new top-level surface, or a flow with no sensible host | a throwaway route under the project's own routing convention, with `prototype` in its path or file name; same gate |

Before taking the last row, check once more that no existing page could host the variants: an
empty route hides the design problems a populated one exposes.

The host page gets the smallest possible mount, one import and one render line, so the whole thing
reverts by deleting two lines and the new files. The mount goes in the report.

## Process

### 1. State the question and the plan

One line, in a banner at the top of the switcher file:

> Three variants of the settings page on the existing `/settings` route, behind `?variant=`.

Three variants is the default. More than five stops being different and starts being noise.

### 2. Draft three radically different variants

Each variant is held to:

- the page's purpose and the data it actually has;
- the project's component library and styling system (Tailwind, shadcn, MUI, plain CSS, whatever
  is already there);
- a clear exported name, such as `VariantA`, `VariantB`, `VariantC`, each with a short human label
  (`Sidebar sections`, `Single column`, `Dense table`).

Variants must disagree about structure: different layout, different information hierarchy,
different primary affordance. Three slightly tweaked card grids is wallpaper, not a prototype.
When two drafts come out alike, redo one with an explicit prohibition ("no card grid", "no
sidebar").

Every constraint the brief marks as decided holds in all three: a term the glossary fixes, a
navigation element that must stay, a flow that is settled elsewhere.

### 3. Wire them to the route

One switcher component reads the variant key and renders one variant:

```tsx
// pseudo-code; adapt to the project's framework and router
const variant = searchParams.get('variant') ?? 'A';
return (
  <>
    {variant === 'A' && <VariantA {...data} />}
    {variant === 'B' && <VariantB {...data} />}
    {variant === 'C' && <VariantC {...data} />}
    <PrototypeSwitcher variants={['A', 'B', 'C']} current={variant} />
  </>
);
```

On an existing route, all the existing data fetching stays above the switcher; only the rendered
subtree changes. On a throwaway route, the route mounts the same switcher.

### 4. Build the floating switcher

A small fixed bar at the bottom centre of the screen, in one shared component:

- **Left arrow**: previous variant, wrapping around.
- **Label**: the current key and its human label, such as `B (Sidebar sections)`.
- **Right arrow**: next variant, wrapping around.

Behaviour:

- An arrow updates the URL search param through the framework's router (`router.replace`,
  `navigate`, or the equivalent), so a variant is shareable and survives reload.
- The left and right arrow keys also cycle, except while an `<input>`, `<textarea>` or
  `[contenteditable]` has focus.
- Visually distinct from the page (a high-contrast pill with a subtle shadow), so it is obviously
  not part of the design under judgement.
- Hidden in production builds, gated on `process.env.NODE_ENV !== 'production'` or the project's
  equivalent, so a stray merge cannot ship the bar to users.

### 5. Report

The report's `open:` line is the dev command and the URL with `?variant=A`; `variants:` lists the
three keys with their labels; `look at:` names the one structural difference the reader should
compare first. The useful answer is often "the header from B with the sidebar from C": that
composite is the design they want.

## Anti-patterns

- **Variants that differ in colour or copy only.** A tweak, not a prototype. Real variants
  disagree about structure.
- **Too much shared code.** A shared `<Header>` is fine; a shared `<Layout>` defeats the point.
  Each variant is free to throw the layout out.
- **Real mutations.** Read-only is fine. A variant that has to mutate points at a stub: the
  question is what it should look like, not whether the backend works.
- **Promoting a variant straight to production.** It was written under prototype constraints (no
  tests, minimal error handling). The winner is rewritten properly when it is folded in.
