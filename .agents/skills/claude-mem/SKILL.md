---
name: claude-mem
description: >-
  Use this skill to implement and utilize long-term memory, project context tracking, and state management.
---

# Claude-Mem: Context & Memory Management

For complex projects, maintaining context across multiple sessions or long conversations is critical.

## Memory Architecture

1.  **State Tracking**: Maintain a clear understanding of what has been built, what is currently being built, and what is planned.
2.  **Decision Logs**: Document *why* critical architectural decisions were made so they aren't questioned repeatedly later.
3.  **Context Switching**: When returning to a previous task, quickly reload the relevant state and dependencies.

## Usage

-   Create and maintain a `project_state.md` or `MEMORY.md` file in the repository root to track overarching goals and current status.
-   Regularly update the memory file when milestones are reached.
