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

This score indicated that although some protections were already in place, the service still had broad access to kernel interfaces, devices, namespaces, and unrestricted system calls.

---

## 2. Hardening Process

### Directive 1: PrivateDevices=true

**Purpose:** Prevents the service from accessing physical and virtual device nodes under `/dev`.

**Reason for selection:** The payment service does not interact with hardware devices.

**Result:** Exposure score decreased.

---

### Directive 2: ProtectKernelModules=true

**Purpose:** Prevents reading or loading kernel modules.

**Reason for selection:** The application has no legitimate need to manage kernel modules.

**Result:** Exposure score decreased.

---

### Directive 3: ProtectKernelTunables=true

**Purpose:** Prevents modification of kernel tunable parameters.

**Reason for selection:** The payment service should not modify operating system settings.

**Result:** Exposure score decreased.

---

### Directive 4: ProtectControlGroups=true

**Purpose:** Prevents modification of control group hierarchies.

**Reason for selection:** The service does not manage other processes.

**Result:** Exposure score decreased.

---

### Directive 5: RestrictSUIDSGID=true

**Purpose:** Prevents creation of SUID or SGID files.

**Reason for selection:** The service should not be able to create files with elevated privileges.

**Result:** Exposure score decreased.

---

### Directive 6: ProtectProc=invisible

**Purpose:** Restricts visibility of other processes in `/proc`.

**Reason for selection:** The payment service only requires access to its own process information.

**Result:** Exposure score decreased.

---

### Directive 7: ProcSubset=pid

**Purpose:** Limits accessible `/proc` information to process-related entries.

**Reason for selection:** Reduces information disclosure.

**Result:** Exposure score decreased.

---

### Directive 8: LockPersonality=true

**Purpose:** Prevents changes to execution domain personality.

**Reason for selection:** The service has no legitimate reason to alter ABI behaviour.

**Result:** Exposure score decreased.

---

### Directive 9: RestrictRealtime=true

**Purpose:** Prevents acquisition of real-time scheduling privileges.

**Reason for selection:** The payment service does not perform real-time operations.

**Result:** Exposure score decreased.

---

### Directive 10: SystemCallArchitectures=native

**Purpose:** Restricts execution to native system call architectures.

**Reason for selection:** Prevents use of alternate ABIs.

**Result:** Exposure score decreased.

---

### Directive 11: RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

**Purpose:** Restricts socket creation to Unix sockets and standard IPv4/IPv6 networking.

**Reason for selection:** The service only requires normal network communication.

**Result:** Exposure score decreased.

---

### Directive 12: UMask=0027

**Purpose:** Ensures newly created files are not world-readable.

**Reason for selection:** Payment-related logs and temporary files should have restricted access.

## **Result:** Exposure score decreased.

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

**Final score:** ________ (below 2.5)

The payment service continued to operate correctly while significantly reducing its attack surface.

---

## 5. Final kk-payments.service Unit File

Include the complete final version of the service unit file submitted for deployment.

*(Paste the full contents of the hardened unit file here.)*

---

## Conclusion

The hardening exercise demonstrated that reducing a service's exposure score requires balancing security improvements with operational requirements. Rather than applying every recommendation blindly, each directive was evaluated to determine whether it was appropriate for the workload and whether it preserved the functionality of the payment service.
