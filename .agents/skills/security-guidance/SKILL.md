---
name: security-guidance
description: >-
  Use this skill to inject security best practices into the development lifecycle and ensure secure defaults.
---

# Security Guidance

Security must be built in, not bolted on. This skill ensures secure coding practices are always active.

## Key Directives

1.  **Secure Defaults**: Always default to the most secure setting (e.g., HTTPOnly cookies, deny-by-default firewall rules).
2.  **Defense in Depth**: Do not rely on a single layer of security. Validate on the frontend *and* the backend.
3.  **Data Minimization**: Only request, process, and store the data absolutely necessary for the feature.
4.  **Dependency Management**: Always be aware of the security posture of third-party libraries.

## Specific Checks

-   CORS configuration is strict.
-   CSP (Content Security Policy) is implemented.
-   Secrets are NEVER hardcoded or logged.
