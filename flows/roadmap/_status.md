# Roadmap Status

## Mode: DFS

## Goal

**MVP (auto-detected)**: Core gateway functionality - SIP↔GSM bidirectional calling working

## Critical Path

| Order | Flow | Type | Status | Phase | Progress |
|-------|------|------|--------|-------|----------|
| 1 | sdd-core-architecture | SDD | ✓ COMPLETE | IMPLEMENTATION | 100% |
| 2 | sdd-sip-core | SDD | IN_PROGRESS | IMPLEMENTATION | 95% |
| 3 | sdd-gateway-service | SDD | PENDING | SPEC | 33% |

## Current Focus

- **Flow**: sdd-sip-core
- **Phase**: IMPLEMENTATION
- **Status**: Phase 3 COMPLETE, Phase 4 starting
- **Blockers**: none

## Path Progress

- Flows on path: 3
- Flows complete: 1/3
- Current flow progress: 95%
- Overall: 65%

## Skipped Flows (not on critical path)

| Flow | Type | Reason Skipped |
|------|------|----------------|
| sdd-account | SDD | Auth can be hardcoded for MVP |
| sdd-dialer | SDD | Not required for core routing |
| sdd-ui-theming | SDD | UI exists, not on critical path |
| sdd-monitoring | SDD | Observability, not required for MVP |
| sdd-event-streaming | SDD | Enhancement, not core routing |
| sdd-android-plugin | SDD | Build concern, not runtime |
| sdd-build-system | SDD | Build concern, not runtime |
| sdd-patch-management | SDD | Deployment concern |
| sdd-release-workflow | SDD | Deployment concern |
| ddd-001-voip-calling | DDD | Documentation, not implementation |
| tdd-testing | TDD | Testing infrastructure, not runtime |
| All other sdd-* flows | SDD | Not on critical path to MVP |

## Last Action

[2026-03-05 00:55] Phase 3 (Plugin Implementation) complete - SipService + RepositoryImpl

## Next Action

1. Begin Phase 4: State Management
2. Create SipProvider (ChangeNotifier)
3. Create SipEventHandlers

---

*Updated by /roadmap*
