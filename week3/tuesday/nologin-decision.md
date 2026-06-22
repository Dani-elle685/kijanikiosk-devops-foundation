# nologin-decision.md

# Decision: Use `/usr/sbin/nologin`

## Summary

All accounts that are not intended for interactive user access should use `/usr/sbin/nologin` as their login shell.

This is a deliberate security and administration decision, not merely a convention.

## Reasoning

Both `/usr/sbin/nologin` and `/bin/false` prevent a user from obtaining an interactive shell, but they do so differently.

### How `/usr/sbin/nologin` Works

When a login service such as SSH, `login`, or another PAM-enabled authentication mechanism successfully authenticates a user, it attempts to start the user's configured shell from `/etc/passwd`.

If the shell is `/usr/sbin/nologin`:

1. Authentication may succeed.
2. The system executes `/usr/sbin/nologin`.
3. `nologin` immediately terminates the session.
4. A message is displayed indicating that interactive logins are not permitted.
5. A non-zero exit status is returned.

This explicitly communicates that the account exists but is not intended for interactive use.

### How `/bin/false` Works

If the shell is `/bin/false`:

1. Authentication may succeed.
2. The system executes `/bin/false`.
3. The program immediately exits with a non-zero status.
4. No explanatory message is normally shown.

The result is that login fails, but the reason is less obvious to administrators and users.

## Why `/usr/sbin/nologin` Is Preferred

### 1. Clear Administrative Intent

`/usr/sbin/nologin` clearly documents that the account is a non-login account. Anyone reviewing `/etc/passwd` can immediately understand the purpose of the configuration.

### 2. Better User Feedback

If someone attempts to log in interactively, `nologin` can display a message explaining that access is intentionally disabled. This reduces confusion and troubleshooting effort.

### 3. Standard Practice for Service Accounts

Most modern Linux distributions use `/usr/sbin/nologin` for system and service accounts. Using the distribution's standard approach improves consistency and maintainability.

### 4. Equivalent Security Outcome

From a security perspective, both options prevent an interactive shell from being started. Therefore, choosing `nologin` does not weaken security while providing better operational clarity.

## Exceptions

No exceptions are recommended unless a specific application vendor explicitly requires a different shell setting. Interactive user accounts should continue to use their normal login shell.

## Final Decision

**Use `/usr/sbin/nologin` for all accounts that should not permit interactive logins.**

The mechanism is explicit, communicates administrative intent, provides useful feedback during login attempts, and achieves the same security objective as `/bin/false`.
