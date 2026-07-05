# Task: systemd Service Hardening Investigation

## Objective

The objective of this task was to reduce the exposure score of `kk-payments.service` reported by `systemd-analyze security` to below **2.5**, while ensuring that the payment service continued to function correctly.

---

## 1. Initial Assessment

The initial version of `kk-payments.service` contained only the basic hardening directives provided in the assignment handout:

* `NoNewPrivileges=true`
* `PrivateTmp=true`
* `ProtectSystem=strict`
* `ProtectHome=true`
* `CapabilityBoundingSet=`

Running:

```bash
systemd-analyze security kk-payments.service
```

produced the following result:

**Initial score:** 5.8 (MEDIUM)

This score indicated that although some protections were already in place, further procedures were supposed to be initiated for hardening

---

## 2. Hardening Process

### Directive 1: PrivateDevices=true

**Purpose:** Prevents the service from accessing physical and virtual device nodes under `/dev`.

**Reason for selection:** The payment service does not interact with hardware devices.

---

### Directive 2: ProtectKernelModules=true

**Purpose:** Prevents reading or loading kernel modules.

**Reason for selection:** The application has no legitimate need to manage kernel modules.

---

### Directive 3: ProtectKernelTunables=true

**Purpose:** Prevents modification of kernel tunable parameters.

**Reason for selection:** The payment service should not modify operating system settings.

---

### Directive 4: ProtectControlGroups=true

**Purpose:** Prevents modification of control group hierarchies.

**Reason for selection:** The service does not manage other processes.

---

### Directive 5: RestrictSUIDSGID=true

**Purpose:** Prevents creation of SUID or SGID files.

**Reason for selection:** The service should not be able to create files with elevated privileges.

---

### Directive 6: ProtectProc=invisible

**Purpose:** Restricts visibility of other processes in `/proc`.

**Reason for selection:** The payment service only requires access to its own process information.

---

### Directive 7: ProcSubset=pid

**Purpose:** Limits accessible `/proc` information to process-related entries.

**Reason for selection:** Reduces information disclosure.

---

### Directive 8: LockPersonality=true

**Purpose:** Prevents changes to execution domain personality.

**Reason for selection:** The service has no legitimate reason to alter ABI behaviour.

---

### Directive 9: RestrictRealtime=true

**Purpose:** Prevents acquisition of real-time scheduling privileges.

**Reason for selection:** The payment service does not perform real-time operations.

---

### Directive 10: SystemCallArchitectures=native

**Purpose:** Restricts execution to native system call architectures.

**Reason for selection:** Prevents use of alternate ABIs.

---

### Directive 11: RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

**Purpose:** Restricts socket creation to Unix sockets and standard IPv4/IPv6 networking.

**Reason for selection:** The service only requires normal network communication.

---

### Directive 12: UMask=0027

**Purpose:** Ensures newly created files are not world-readable.

**Reason for selection:** Payment-related logs and temporary files should have restricted access.

##
## 3. Directives Investigated but Not Applied

### PrivateNetwork=true

**Reason investigated:**

This directive isolates the service from the host network stack.

**Why it was rejected:**

The payment service communicates with external systems over HTTP/HTTPS. Enabling this directive prevented outbound network communication and caused the service to fail.

---

### MemoryDenyWriteExecute=true

**Reason investigated:**

Prevents creation of writable and executable memory mappings.

**Why it was rejected:**

Node.js relies on the V8 JavaScript engine, which may use JIT compilation requiring executable memory mappings. Testing indicated that this directive caused the service to fail to start.

---

## 4. Final Exposure Score

After applying the selected hardening directives and testing service functionality:

**Final score:** 1.1 (below 2.5)

---

## 5. Final kk-payments.service Unit File hardening includes:

        NoNewPrivileges=true
        PrivateTmp=true
        ProtectSystem=strict
        ProtectHome=true
        CapabilityBoundingSet=

        PrivateDevices=true
        PrivateUsers=true
        PrivateMounts=true

        ProtectClock=true
        ProtectHostname=true
        ProtectKernelLogs=true
        ProtectKernelModules=true
        ProtectKernelTunables=true
        ProtectControlGroups=true

        ProtectProc=invisible
        ProcSubset=pid

        RestrictSUIDSGID=true
        RestrictRealtime=true
        LockPersonality=true
        SystemCallArchitectures=native

        RestrictNamespaces=true
        RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

        SystemCallFilter=@system-service
        SystemCallFilter=~@clock @cpu-emulation @debug @module \
                        @mount @obsolete @privileged \
                        @raw-io @reboot @resources @swap

        UMask=0027
        RemoveIPC=true

---



