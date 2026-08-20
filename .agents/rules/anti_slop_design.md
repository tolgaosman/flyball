---
name: Emil Kowalski / Anti-Slop Design Guidelines
description: Strict UI/UX design philosophy prioritizing premium aesthetics, fluid animations, and impeccable taste.
---

# Premium Design Guidelines ("Anti-Slop")

Whenever generating, modifying, or refactoring user interfaces in this project, you **MUST** strictly adhere to the following design principles. 

This project rejects generic, lazy, or "slop" UI. We aim for impeccable taste, heavily inspired by Emil Kowalski's spatial design and animation philosophies.

## 1. Animations & Physics (The Core)
- **Never use linear or generic ease curves.** Always use bouncy, fluid spring physics for interactions (e.g., `Curves.easeOutCirc`, `Curves.fastLinearToSlowEaseIn`).
- **Micro-interactions:** Every button, card, and interactive element MUST have a subtle, satisfying scale-down effect on press (`flutter_animate` is highly recommended).
- **Haptics:** Tie subtle haptic feedback (`HapticFeedback.lightImpact()`) to logical user interactions.

## 2. Aesthetics & Glassmorphism
- **No Hard Shadows:** Never use 100% opacity blacks or thick brutalist drop shadows. Use soft, highly blurred, diffuse shadows with very low opacity to create spatial depth (e.g., `BoxShadow` with `blurRadius: 24`, `opacity: 0.1`).
- **Translucency:** Embrace glassmorphism. Surfaces should rarely be solid colors; use slight translucency (`color.withOpacity(0.9)`) overlaid on the background.
- **Borders:** Borders should be practically invisible (e.g., `width: 1.0` with `0.1` opacity) just to define edges cleanly without shouting.

## 3. Typography & Spacing
- **Modern Sans-Serifs:** Use highly legible, premium fonts like `Inter`, `Geist`, or `SF Pro`. Never use blocky or default browser fonts.
- **Tight Tracking:** Headings should have tight letter spacing (`letterSpacing: -1.0` or similar) for a dense, premium look.
- **Generous Whitespace:** Layouts must breathe. Use consistent, generous padding variables (`AppSpacing.lg`, `AppSpacing.xl`) and never hardcode random magic numbers.

Always verify that the resulting UI feels physical, expensive, and meticulously crafted.
