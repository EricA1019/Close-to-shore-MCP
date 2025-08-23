## 2025-08-23 — ASCII Addon + Headless

- Godot headless (4.3) can fail to resolve `class_name` types across addons before the class cache is ready during test boot.
- Prefer path-based `extends` and explicit `preload()` for cross-file types inside addons.
- Avoid strict type annotations on cross-referenced addon types in headless until CI is stable.
- UI controls in tests need non-zero size — give containers a `custom_minimum_size` to avoid zero-sized images.

# Hard-Learned Lessons for Godot MCP Template

This document collects practical lessons and workflow tips for using Godot effectively, integrated into this template:

## Purpose
Capture and share workflow improvements, technical lessons, and best practices for future reference.

## Structure & Best Practices
- Organize lessons by topic (entity system, testing, plugins, etc.).
- Log new lessons and workflow changes as they occur.
- Reference this file in onboarding and documentation updates.

## Update & Log
- Use the "Update All Docs" task to keep documentation in sync.
- Log major lessons and changes here for transparency.

## Last Updated
2025-08-17

## Entity System
- Use a flexible entity/component system for game objects
- Prefer composition over inheritance for extensibility

## Turn Order & Battle Managers
- Centralize turn order logic for clarity and maintainability
- Use battle managers to handle combat flow, state, and transitions

## Scene & Script Organization
- Keep scenes modular and scripts well-documented
- Use automated indexing to track and update project structure

## Testing
- Integrate GUT for unit and integration tests
- Write tests for core systems and gameplay logic

## Plugin Management
- Use a plugin manager to keep addons up-to-date
- Document each plugin’s purpose and usage

## Documentation
- Maintain local copies of engine and tool docs for quick reference
- Update workflow docs as new lessons are learned

## General Workflow
- Start with a clear roadmap and flexible checklist
- Log decisions and changes in DEV_LOG.md
- Use MCP protocol for minimal, testable changes

## Customization
- Merge and adapt scripts, assets, and automation from proven templates
- Document all modifications and attributions

## Goal
Make Godot development smoother, faster, and more maintainable for all future projects.
