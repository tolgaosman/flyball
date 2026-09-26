---
name: anthropic-security-audit
description: >-
  Use this skill to perform rigorous security audits, threat modeling, and vulnerability assessments based on Anthropic's methodology.
---

# Anthropic Security Audit

This skill enforces a high-tier security mindset, particularly focused on modern web applications and AI integrations.

## Audit Methodology

1.  **Threat Modeling**: Identify the assets, entry points, and potential threat actors. Map out the attack surface.
2.  **AI & LLM Vulnerabilities**: Check for prompt injection, insecure output handling, training data poisoning, and model denial of service.
3.  **OWASP Top 10**: Systematically review for Broken Access Control, Cryptographic Failures, Injection (SQL/XSS), Insecure Design, and Security Misconfiguration.
4.  **Principle of Least Privilege**: Ensure every component, service, and user has only the minimum permissions necessary.

## Actionable Steps during Audit

-   Trace user input from the boundary to the database and back.
-   Verify authentication and session management robustness.
-   Review dependency trees for known CVEs.
-   Ensure sensitive data is encrypted at rest and in transit.
