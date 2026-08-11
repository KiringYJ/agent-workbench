# Frontend Agent Guide

## Scope and Local Conventions

- Read the package manifest, lockfile, framework configuration, and `AI_AGENT_PROJECT.md` before choosing commands or UI patterns.
- Use the package manager selected by the existing lockfile. Do not switch package managers, repair dependencies implicitly, or allow a fallback runner to install packages without an explicit project decision.
- Inspect the target component and its nearest visual peers before designing a material UI change. Reuse the project's established hierarchy, spacing, density, typography, surfaces, actions, and scrolling behavior.
- Treat the project's design system and component library as the primary UI vocabulary. Prefer existing components and tokens over a parallel hand-written visual system.
- Keep repository-specific rules in `AI_AGENT_PROJECT.md`, including exact validation commands, authoritative device-capability signals, expensive opt-in browser gates, and local service ports.

## Component and Markup Discipline

- Use design-system components for controls, feedback, navigation, overlays, and repeated surfaces when suitable components exist.
- Keep native semantic elements when they provide real document structure or accessibility. Do not replace meaningful headings, landmarks, lists, links, or form semantics with generic layout wrappers.
- Do not recreate a component-library button, input, select, checkbox, dialog, menu, tab, card, alert, chip, or progress indicator with custom markup and CSS.
- Prefer component APIs, slots, theme tokens, and utility classes before adding custom wrappers or CSS.
- Add custom CSS only for behavior the design system cannot express. Keep the exception narrow and explain it in the implementation summary.
- For non-trivial work, state a short responsibility map: which component owns data and orchestration, which components own reusable presentation, and which public props, events, routes, or APIs must remain stable.

## Responsive Layout and Input Capability

- Use framework breakpoints and viewport measurements for layout and available space only.
- Do not infer touch, hover, pointer precision, drag delay, long-press behavior, or other physical input capabilities from viewport width or a `mobile` layout breakpoint.
- Use the project's authoritative device or input-capability signal for interaction branches. If none exists, establish the boundary explicitly instead of silently treating a narrow desktop window as a touch device.
- Test responsive layout separately from input behavior. A narrow desktop viewport must retain desktop mouse and keyboard behavior unless the product explicitly specifies otherwise.

## Accessibility and UI States

- Preserve keyboard operation, visible focus, meaningful labels, focus management, and appropriate semantic or ARIA relationships.
- Give icon-only controls an accessible name.
- Do not communicate state through color alone; pair color with text, an icon, or another semantic cue.
- Design and verify relevant loading, empty, active, disabled, error, and destructive states rather than validating only the happy path.
- Ensure labels and identifiers wrap safely, and check for horizontal overflow or clipped content at the project's narrow supported viewport.

## Services and Command Execution

- Check the expected port or health endpoint before starting a development server and reuse an already-running intended instance.
- Treat development servers, watchers, and preview processes as managed services. Record their process or session identifier, verify readiness separately, and stop processes started for the task during cleanup.
- Use bounded polling and explicit deadlines. If a service produces no useful progress, inspect its process, port, and logs instead of retrying the same launch indefinitely.
- Run package-manager checks that share one dependency tree sequentially. Avoid concurrent type-check, test, lint, and build processes that can contend for the same cache or `node_modules` state.

## Verification

Choose the smallest checks that prove the requested behavior, using commands documented by the project. For a material frontend change, normally cover:

1. A targeted type check, lint check, and component or unit test while iterating.
2. The project's broader frontend check and production build when the risk warrants them.
3. Desktop and narrow responsive layouts.
4. Every supported theme, including the rendered content of teleported overlays.
5. Relevant loading, empty, active, disabled, error, and destructive states.
6. Keyboard and accessible-name behavior for changed controls.
7. Horizontal overflow, clipped labels, and contrast regressions.

When an overlay is theme-aware, open it in each theme and also change the global theme while it remains open. Verify the overlay surface itself, not only the dimmed page behind it.

Treat expensive performance traces, repeated browser matrices, trusted input injection, and specialized visual gates as project-owned opt-in checks unless the user or `AI_AGENT_PROJECT.md` requires them for the current task. Report an intentionally omitted opt-in gate as a scope boundary, not as an unexplained validation failure.
