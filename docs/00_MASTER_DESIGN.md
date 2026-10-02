# ZOTIK – Master Design 2026-09-26

This document is the consolidation layer over the retained legacy specifications.

## Product identity
Free, age-inclusive original action-JRPG with Zotik as an anthropomorphic orange fantasy protagonist. Core pillars: story-driven exploration, real-time combat, puzzles with reset/recovery, companions, world rifts, local-first saves, optional multiplayer/online systems in later phases, recurring events, housing/city building, cosmetics, gift codes and creator content without pay-to-win.

## Phase 1 scope
The first production target is a complete Lunaris vertical slice that can be played from New Game through the first major boss, Weltenklinge acquisition, story return, save, full application restart and deterministic reload.

## Deferred from Phase 1
Online co-op, self-hosted dedicated servers, TikTok Live interaction, housing/city builder, marketplace, casino, recurring online events and broad cross-save are preserved requirements but are not implementation scope until the foundation slice passes.

## Size strategy
Target the complete base client at <=2 GB where practical. Local saves are primary; server infrastructure must not be used as bulk save storage. Reuse modular environment assets, shared animation libraries, texture budgets, LOD and platform profiles.
