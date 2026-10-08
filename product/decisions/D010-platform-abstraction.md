# D010 — Platform abstraction for future OS

**Status:** Accepted (2026-10-08)

## Context

Name says “Mac” but Gradle/pub/npm rules apply elsewhere; avoid mac-only types everywhere.

## Decision

Introduce **`DevCleanerHost`**, **`HostPaths`**, **`ScanEngine`**, **`DoctorEngine`**, **`DiskSpaceProvider`** with **`MacOSDevCleanerHost`** as only supported implementation. Factory: **`createDevCleanerHost()`**.

## Consequences

New OS = new host module + factory branch; macOS rules stay in `ScanService` / `DoctorService` until split per engine.
