# Vuetify Agent Guide

This module supplements the Vue guide for applications that use Vuetify. It must not be selected for frontend or Vue projects that do not use Vuetify.

## Version-Aware Documentation

Before substantial Vuetify work:

1. Read the installed `vuetify` version from the package manifest or lockfile.
2. Inspect the target component and the closest existing Vuetify views in the repository.
3. Confirm every non-trivial component API against documentation for the installed Vuetify version before editing.

When the project exposes the official [Vuetify MCP server](https://github.com/vuetifyjs/mcp), use it actively instead of relying on memory. If MCP tools are deferred or lazily loaded, discover the server's exposed tools before falling back. Prefer these tools when exposed:

- Use `get_vuetify_api_by_version` when the server requires an exact-version API index before component lookup.
- Use `get_component_api_by_version` for the installed version to confirm relevant props, slots, events, defaults, and version-specific behavior.
- Use `get_feature_guide` for cross-component concerns such as themes, accessibility, display behavior, platform support, and icons.
- Use `get_v4_breaking_changes`, `get_upgrade_guide`, or the official [Vuetify upgrade guide](https://vuetifyjs.com/getting-started/upgrade-guide/) for Vuetify 4 migrations and other uncertain major-version behavior.

For non-trivial Vuetify component work, using an available `vuetify-mcp` is required. Report any unavailable-tool or unsupported-version fallback instead of silently skipping the lookup.

Do not install or configure the MCP server, a plugin, or a global tool unless the user or project explicitly authorizes it. If `vuetify-mcp` is expected but unavailable, say so briefly and use the official versioned Vuetify documentation plus the installed package's TypeScript types or source. Never guess an API from another major version.

MCP and documentation output are implementation guidance. The installed package, local types, existing component patterns, tests, and rendered behavior remain the final authority.

## Vuetify-First UI Policy

Use Vuetify's components, props, slots, theme system, display helpers, and utility classes as the primary visual API.

- Layout and surfaces: prefer components such as `VContainer`, `VRow`, `VCol`, `VSheet`, `VSpacer`, `VCard`, `VCardItem`, `VCardText`, `VCardActions`, and `VToolbar` when their semantics and behavior fit.
- Lists and settings: prefer `VList`, `VListItem`, `VListSubheader`, and `VDivider`.
- Controls: prefer `VBtn`, Vuetify selection controls, and Vuetify text, select, autocomplete, and combobox inputs.
- Feedback: prefer `VAlert`, `VProgressLinear`, `VProgressCircular`, `VEmptyState`, `VSnackbar`, and `VTooltip` where supported by the installed version.
- Navigation and overlays: prefer Vuetify tabs, windows, dialogs, menus, and navigation drawers.

Do not use generic `div`, `span`, or `section` wrappers merely to reproduce spacing, alignment, surfaces, headers, or groups that a suitable Vuetify component already expresses. Native semantic elements remain appropriate when they add genuine document or accessibility meaning. Do not rebuild an existing Vuetify control or surface with custom CSS.

## Props, Slots, and CSS

- Prefer documented component props such as `color`, `variant`, `density`, `rounded`, `border`, `elevation`, `lines`, `size`, `width`, and `max-width` when they exist in the installed version.
- Prefer documented slots such as `prepend`, `append`, `title`, `subtitle`, `actions`, and `activator` over custom wrapper markup.
- Prefer Vuetify spacing, flex, typography, sizing, and visibility utilities when their installed-version behavior matches the requirement.
- Keep scoped CSS minimal. Do not use CSS to imitate a prop, slot, token, or utility that already provides the same behavior.
- Treat major-version migrations as API changes. In particular, recheck typography, breakpoints, grid spacing, elevation, theme defaults, and renamed props or slots rather than assuming Vuetify 3 and Vuetify 4 behave alike.

## Theme Compatibility

- Let components inherit the active Vuetify theme. Force an isolated light or dark theme only when the product explicitly requires it.
- Use semantic Vuetify colors and theme tokens such as `primary`, `secondary`, `surface`, `error`, `warning`, `info`, and `success`.
- Avoid fixed hex, RGB, white, black, or light-only/dark-only border colors in feature components. Prefer component color props and Vuetify theme variables.
- Pair semantic color with text, an icon, or the component's semantic type so state does not depend on color alone.
- For dialogs, menus, snackbars, and other teleported content, inspect the complete shared wrapper chain. A child is not theme-compatible when a parent dialog, card, toolbar, or theme provider forces the wrong theme or surface color.
- Repair unintended theme overrides at the highest shared owner. Do not pass the current theme redundantly through every child as compensation.

For material overlay changes, verify the rendered overlay after opening it in every supported theme and while toggling the global theme with the overlay still open. Confirm that the overlay's theme class, background, and foreground actually change.

## Common Vuetify Patterns

### Dialogs

- Prefer `VDialog` with a theme-inheriting `VCard`.
- Use `VCardItem` or `VToolbar` for the title and close action, `VCardText` for content, and `VCardActions` for actions when supported by the installed version.
- Use Vuetify progress components for loading states.
- Ensure fullscreen or narrow dialogs preserve scrolling and keep headers, tabs, and actions usable.

### Forms, Settings, and Lists

- Prefer grouped list sections, subheaders, dividers, and list-item slots for settings-style interfaces.
- Keep titles and descriptions readable at narrow widths; use supported line and typography APIs rather than fixed heights.
- Mark destructive choices with the semantic error treatment and explicit warning text.

### Loading, Empty, Error, Buttons, and Icons

- Use Vuetify progress, empty-state, and alert components when supported by the installed version.
- Make long error messages and identifiers wrap without horizontal overflow.
- Use `VBtn` and `VIcon` for actions and icons. Icon-only controls require an accessible name.
- Preserve existing loading, disabled, keyboard, and click-propagation behavior unless the task explicitly changes it.

## Vuetify Verification Checklist

In addition to the frontend and Vue verification guides, confirm:

- The exact installed Vuetify version and relevant component APIs were checked, using `vuetify-mcp` when available.
- Suitable raw layout or control markup was replaced by Vuetify components without sacrificing semantic HTML.
- The result follows the nearest established modal, settings, list, form, or toolbar pattern.
- Colors and surfaces are semantic and respond correctly to every supported theme.
- Teleported overlays inherit and update the active theme.
- The UI works at the project's narrow supported viewport without clipping or horizontal overflow.
- Loading, empty, error, disabled, and destructive states remain understandable.
- Icon-only actions have accessible names.
- Targeted TypeScript, test, lint, and production-build checks required by the project pass.
- Temporary previews, generated test entrypoints, and unrelated files are absent from the final diff.
