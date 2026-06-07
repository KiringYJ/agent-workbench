# TypeScript Agent Guide

## Language and Toolchain Policy

- Prefer TypeScript over JavaScript for new project code, scripts, tests, and configuration when the toolchain supports it.
- Avoid adding new JavaScript files when a TypeScript equivalent is practical. If JavaScript is necessary, use the latest ECMAScript standard supported by the runtime/toolchain and keep type-aware boundaries with JSDoc, generated types, or nearby TypeScript declarations when practical.
- Prefer the latest stable TypeScript, runtime, framework, build, and lint stack compatible with the project. Do not downgrade or freeze older tooling without a documented constraint.
- Use the strictest type-checking and lint rules the project can support. Prefer fixing code over weakening `tsconfig`, ESLint, formatter, or framework rules.

## Naming

Follow the project’s existing TypeScript conventions first. If no convention is documented:

- Use `camelCase` for variables and functions.
- Use `PascalCase` for classes, types, interfaces, React components, and exported constructors.
- Use descriptive file names aligned with the local framework convention.

## Workflow

Typical verification, adjusted by `AI_AGENT_PROJECT.md`, is:

```bash
npm run typecheck
npm run lint
npm test
```

Use the package manager already present in the project (`npm`, `pnpm`, `yarn`, `bun`) and do not switch package managers without explicit approval.

When establishing or tightening a TypeScript project, favor options such as `strict`, `noImplicitOverride`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, no unused code checks, and strict linting for unsafe `any`, unchecked promises, implicit coercions, and import hygiene.

## Logging and Output

Use the project’s structured logger when available. Avoid `console.log` for diagnostics in library or server code unless the project explicitly uses it.

## Dependencies

Do not add packages casually. Prefer platform APIs, framework utilities, or existing dependencies. If a package is necessary, update the correct manifest and lockfile together.
