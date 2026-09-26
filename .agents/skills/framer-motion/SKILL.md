---
name: framer-motion
description: >-
  Use this skill to master React animations using Framer Motion, focusing on layouts, variants, and gestural interactions.
---

# Framer Motion Mastery

This skill focuses on delivering high-performance, complex animations in React.

## Advanced Techniques

1.  **Shared Layout Animations**: Use `layoutId` to seamlessly animate components between different parts of the DOM.
2.  **Orchestration**: Use `Variants` to stagger animations, control children from parents, and keep animation logic clean.
3.  **Scroll Animations**: Utilize `useScroll` and `useTransform` for parallax effects and scroll-linked animations without killing performance.
4.  **Exit Animations**: Always wrap components that are removed from the DOM in `AnimatePresence` to allow them to animate out gracefully.

## Best Practices

-   Prefer hardware-accelerated properties (transform, opacity).
-   Use custom springs for a natural feel: `transition={{ type: "spring", stiffness: 300, damping: 30 }}`.
