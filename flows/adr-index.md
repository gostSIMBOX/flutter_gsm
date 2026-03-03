# ADR Index

Master index of all Architecture Decision Records.

## Active ADRs

| # | Name | Title | Type | Status | Created | Decided | File |
|---|------|-------|------|--------|---------|---------|------|
| 001 | clean-architecture | Clean Architecture | constraining | DRAFT | 2026-03-03 | - | flows/adr-001-clean-architecture/ |
| 002 | dependency-injection | Dependency Injection (get_it) | enabling | DRAFT | 2026-03-03 | - | flows/adr-002-dependency-injection/ |
| 003 | state-management | State Management (Provider) | enabling | DRAFT | 2026-03-03 | - | flows/adr-003-state-management/ |
| 004 | error-handling | Error Handling (Centralized) | enabling | DRAFT | 2026-03-03 | - | flows/adr-004-error-handling/ |
| 005 | service-orchestration | Service Orchestration | constraining | DRAFT | 2026-03-03 | - | flows/adr-005-service-orchestration/ |

### Types
- **constraining** - selects from options, closes alternatives
- **enabling** - adds new capabilities, expands scope

## Statistics

- **Total**: 5
- **Approved**: 0
- **Review**: 0
- **Draft**: 5
- **Rejected**: 0
- **Superseded**: 0

## Categories

### Architecture
- ADR 001: Clean Architecture
- ADR 005: Service Orchestration

### Performance
- (none)

### Security
- (none)

### API
- ADR 002: Dependency Injection
- ADR 003: State Management
- ADR 004: Error Handling

## Relationships

### Dependencies
- ADR 002 depends on ADR 001 (DI supports Clean Architecture)
- ADR 003 depends on ADR 001 (State management supports layer separation)
- ADR 004 depends on ADR 001 (Error handling in core layer)
- ADR 005 depends on ADR 001, 002, 003 (Orchestration uses all patterns)

### Supersedes
- (none yet)

---

## Index Maintenance

When creating/updating ADRs:
1. Add entry to table above
2. Update statistics
3. Add to relevant category
4. Note any relationships

**Last updated**: 2026-03-03 (by /legacy command)
**Next ADR number**: 6
