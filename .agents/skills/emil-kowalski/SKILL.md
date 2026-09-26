---
name: emil-kowalski
description: >-
  Use this skill to craft high-end, fluid, and physics-based UI animations, inspired by the work of Emil Kowalski.
---

# Emil Kowalski Style UI Engineering

Emil Kowalski is renowned for creating interfaces that feel alive, using physical, spring-based animations.

## Core Animation Philosophy

1.  **Springs over Durations**: Never use linear or ease-in-out durations for interactive elements. Always use physics-based springs (e.g., Framer Motion's `spring` transition).
2.  **Interruptibility**: Animations must be fully interruptible. If a user clicks away mid-animation, it should fluidly transition to the new state without jumping.
3.  **Spatial Awareness**: Elements should move logically within the UI. Use layout animations to animate size and position changes smoothly.
4.  **Micro-Interactions**: Add subtle scaling or color shifts on click/tap (`whileTap={{ scale: 0.95 }}`) to provide tactile feedback.

## Recommended Tooling

-   **Framer Motion**: The standard for React spring animations.
-   **CSS Variables**: Use them to smoothly transition colors and themes.
-   **Radix UI / Vaul**: Unstyled primitives for building accessible, high-quality components.
