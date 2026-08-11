# Vue Agent Guide

This module supplements the TypeScript and frontend guides for Vue 3 applications. It does not assume that the project uses Vuetify or another component library.

## Version and Project Conventions

- Read the installed `vue` version and relevant framework integrations from the package manifest or lockfile before changing component APIs or configuration.
- Inspect nearby single-file components, routing, state management, testing, and build conventions before introducing a new pattern.
- Confirm unfamiliar or version-sensitive Vue behavior against the official documentation for the installed version and the local TypeScript types. Do not assume a pattern from another Vue major version applies.
- Preserve the project's established component registration and import strategy unless the task explicitly changes it.

## Single-File Component Architecture

- Use Vue 3 Composition API with `<script setup lang="ts">` for new or substantially rewritten single-file components unless the project documents another established convention.
- Keep single-file component sections ordered as `<script>`, `<template>`, then `<style>`.
- Keep source state minimal and derive presentation values with `computed`.
- Use watchers for actual side effects or synchronization boundaries, not as a substitute for derived state.
- Keep props read-only and use typed emits for upward communication.
- Follow the project's established `v-model` contract and type every public prop, emit, slot, and exposed method that the local tooling supports.
- Split repeated or substantial presentation blocks into focused child components.
- Keep page or modal orchestration separate from reusable form, list, and row presentation.
- Do not create a composable for a pure one-off formatting helper.

## Behavior and Lifecycle

- Preserve public props, emits, slots, routes, state-store contracts, and loading or error behavior unless the task explicitly changes them.
- Keep ownership clear: parents coordinate data and navigation; focused children render reusable UI and emit intentional events.
- Clean up timers, listeners, observers, and other external effects when their owning component or scope is disposed.
- Do not mutate props or hide cross-component state in module-level variables.

## Vue Verification

In addition to the frontend verification guide, run the project's Vue-aware type check, targeted component tests, lint checks, and production build as appropriate. Verify changed prop and emit contracts, reactive updates, mount and unmount behavior, router or store integration, and relevant loading, empty, error, and disabled states.
