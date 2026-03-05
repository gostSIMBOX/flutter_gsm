# Index Builder Flow

## Command: /index

Builds/updates index files for ADR/SDD/DDD/TDD/VDD flows.

## Usage

```bash
/index                           # Build all indexes (parallel)
/index adr                       # Build ADR index only
/index sdd                       # Build SDD index only
/index ddd                       # Build DDD index only
/index vdd                       # Build VDD index only
/index tdd                       # Build TDD index only
/index status                    # Show index status
```

## Initialization

**Before any execution**, check if `flows/.templates/indexes/` exists:

```
IF flows/.templates/indexes/ does NOT exist:
  1. Create flows/.templates/indexes/ directory
  2. Create index templates for each type
  3. Inform user: "Initialized index templates"
  4. Continue with execution
```

## Execution Model

**This command SHOULD run in 5 parallel subagents when building all indexes:**

```
Main Agent
    │
    ├─► Delegate to subagent #1 (ADR index)
    ├─► Delegate to subagent #2 (SDD index)
    ├─► Delegate to subagent #3 (DDD index)
    ├─► Delegate to subagent #4 (VDD index)
    ├─► Delegate to subagent #5 (TDD index)
    │
    └─► Wait for all to complete
        │
        └─► Aggregate results
```

**For single index builds**, run in current agent or single subagent.

## Index Specifications

### ADR Index (`flows/adr-index.md`)

**Structure:**

```markdown
# ADR Index

Master index of all Architecture Decision Records.

## Active ADRs

| # | Name | Title | Type | Status | Created | Decided | File |
|---|------|-------|------|--------|---------|---------|------|
| 001 | clean-architecture | Clean Architecture | constraining | DRAFT | 2026-03-03 | - | flows/adr-001-clean-architecture/ |
| 002 | dependency-injection | Dependency Injection | enabling | APPROVED | 2026-03-03 | 2026-03-04 | flows/adr-002-dependency-injection/ |

### Types
- **constraining** (ограничивающий) - selects from options, closes alternatives
- **enabling** (расширяющий) - adds new capabilities, expands scope
- **pending** (ожидающий принятия решения) - decision deferred, awaiting info

## Statistics

- **Total**: 5
- **Approved**: 2
- **Review**: 1
- **Draft**: 2
- **Rejected**: 0
- **Superseded**: 0

## Categories

### Architecture
- ADR 001: Clean Architecture
- ADR 005: Service Orchestration

### Performance
- (none)

## Relationships

### Dependencies
- ADR 002 depends on ADR 001
- ADR 003 depends on ADR 001

### Conflicts
- (none)
```

**Extraction from `flows/adr-[NNN]-[name]/adr.md`:**
- Number: From filename or meta section
- Name: From directory name (without number)
- Title: From `# ADR-[NNN]: [Title]`
- Type: From meta section (constraining/enabling/pending)
- Status: From meta section (DRAFT/REVIEW/APPROVED/REJECTED/SUPERSEDED)
- Created: From meta section
- Decided: From meta section

---

### SDD Index (`flows/sdd-index.md`)

**Structure:**

```markdown
# SDD Index

Master index of all Spec-Driven Development flows.

## Active SDD Flows

| Name | Requirements | Specifications | Plan | Implementation | Status | Layer |
|------|--------------|----------------|------|----------------|--------|-------|
| sdd-call | ✓ | ✓ | ✗ | ⏳ | IN_PROGRESS | L1 |
| sdd-endpoint | ✓ | ✓ | ✗ | ✗ | DRAFT | L1 |

## Statistics

- **Total**: 27
- **Complete** (all docs): 22
- **In Progress**: 5
- **Draft**: 0

## By Layer

### Layer 0 (Infrastructure)
- sdd-core-architecture
- sdd-event-streaming
- sdd-monitoring
- sdd-build-system
- sdd-release-workflow
- sdd-patch-management

### Layer 1 (Domain)
- sdd-sip-core
- sdd-sip
- sdd-telephony
...

### Layer 2 (Features)
- (none - SDD is primarily L0/L1)

## Dependencies

| Flow | Requires | Enables |
|------|----------|---------|
| sdd-call | sdd-endpoint, sdd-call-model | gateway-service |
| sdd-gateway-service | sdd-sip, sdd-telephony | voip-calling |
```

**Extraction from `flows/sdd-[name]/`:**
- Requirements: Check `01-requirements.md` exists
- Specifications: Check `02-specifications.md` exists
- Plan: Check `03-plan.md` exists
- Implementation: Check `04-implementation-log.md` exists
- Status: From `_status.md` or inferred from document completion
- Layer: From waterfall layer classification

---

### DDD Index (`flows/ddd-index.md`)

**Structure:**

```markdown
# DDD Index

Master index of all Document-Driven Development flows.

## Active DDD Flows

| Name | Requirements | Specifications | Plan | Status | Layer | Stakeholders |
|------|--------------|----------------|------|--------|-------|--------------|
| ddd-001-voip-calling | ✓ (stakeholder) | ✗ | ✗ | DRAFT | L2 | Enterprise, Remote Workers |
| ddd-imei-modification | ✓ | ✗ | ✗ | DRAFT | L2 | Device Admins |

## Statistics

- **Total**: 2
- **Complete**: 0
- **In Progress**: 2
- **Draft**: 0

## By Stakeholder Type

### Enterprise
- ddd-001-voip-calling

### Device Administration
- ddd-imei-modification

## Related SDD

| DDD Flow | Related SDD | Relationship |
|----------|-------------|--------------|
| ddd-001-voip-calling | sdd-endpoint | Implements |
| ddd-001-voip-calling | sdd-call | Implements |
```

**Extraction from `flows/ddd-[name]/`:**
- Requirements: Check `01-requirements.md` or `01-stakeholder-requirements.md`
- Specifications: Check `02-specifications.md` exists
- Plan: Check `03-plan.md` exists
- Stakeholders: From requirements document

---

### VDD Index (`flows/vdd-index.md`)

**Structure:**

```markdown
# VDD Index

Master index of all Visual-Driven Development flows.

## Active VDD Flows

| Name | Requirements | Visual Specs | Plan | Implementation | Status | Layer |
|------|--------------|--------------|------|----------------|--------|-------|
| vdd-ui-theming | ✓ | ✓ | ✗ | ✓ | COMPLETE | L2 |
| vdd-001-video-calling | ✓ (visual) | ✗ | ✗ | ✗ | DRAFT | L2 |
| vdd-call-ui | ✗ | ✓ | ✗ | ✗ | DRAFT | L2 |

## Statistics

- **Total**: 4
- **Complete**: 1
- **In Progress**: 2
- **Draft**: 1

## By Component Type

### Screens
- vdd-screens

### Components
- vdd-call-ui
- vdd-001-video-calling (video components)

### Theming
- vdd-ui-theming

## Related SDD

| VDD Flow | Related SDD | Relationship |
|----------|-------------|--------------|
| vdd-ui-theming | sdd-core-architecture | Uses DI |
| vdd-call-ui | sdd-call | Displays call state |
```

**Extraction from `flows/vdd-[name]/`:**
- Requirements: Check `01-requirements.md` or `01-visual-requirements.md`
- Visual Specs: Check `01-visual-specs.md` or `02-specifications.md`
- Plan: Check `03-plan.md` exists
- Implementation: Check `04-implementation-log.md` exists

---

### TDD Index (`flows/tdd-index.md`)

**Structure:**

```markdown
# TDD Index

Master index of all Tests-Driven Development flows.

## Active TDD Flows

| Name | Requirements | Test Specs | Plan | Implementation | Status | Layer |
|------|--------------|------------|------|----------------|--------|-------|
| tdd-testing | ✓ | ✓ | ✗ | ✓ | COMPLETE | L2 |
| tdd-android-plugin | ✓ | ✓ | ✗ | ✗ | DRAFT | L2 |

## Statistics

- **Total**: 8
- **Complete**: 1
- **In Progress**: 6
- **Draft**: 1

## By Test Type

### Unit Tests
- tdd-testing

### Integration Tests
- tdd-incall-service
- tdd-native-bridge

### Plugin Tests
- tdd-android-plugin
- tdd-plugin-tests

## Systems Under Test

| TDD Flow | System Under Test |
|----------|-------------------|
| tdd-android-plugin | flutter_dialer |
| tdd-telephony-testing | TelephonyService |
```

**Extraction from `flows/tdd-[name]/`:**
- Requirements: Check `01-requirements.md` or `01-test-requirements.md`
- Test Specs: Check `01-test-specifications.md` or `02-specifications.md`
- Plan: Check `03-plan.md` exists
- Implementation: Check `04-implementation-log.md` exists

---

## Parallel Execution

**When running `/index` (all indexes):**

```
Main Agent
    │
    ├─► Subagent #1: Build adr-index.md
    │   Prompt: "Scan flows/adr-*/, extract metadata, build adr-index.md"
    │
    ├─► Subagent #2: Build sdd-index.md
    │   Prompt: "Scan flows/sdd-*/, extract metadata, build sdd-index.md"
    │
    ├─► Subagent #3: Build ddd-index.md
    │   Prompt: "Scan flows/ddd-*/, extract metadata, build ddd-index.md"
    │
    ├─► Subagent #4: Build vdd-index.md
    │   Prompt: "Scan flows/vdd-*/, extract metadata, build vdd-index.md"
    │
    ├─► Subagent #5: Build tdd-index.md
    │   Prompt: "Scan flows/tdd-*/, extract metadata, build tdd-index.md"
    │
    └─► Wait for all (async.parallel or similar)
        │
        ├─► All succeeded: Report success
        ├─► Some failed: Report partial success, retry failed
        └─► Update waterfall/_status.md with index status
```

**Timeout per subagent:** 60 seconds

**Retry policy:** Retry failed indexes once before reporting failure

---

## Output Files

| File | Purpose |
|------|---------|
| `flows/adr-index.md` | ADR master index |
| `flows/sdd-index.md` | SDD master index |
| `flows/ddd-index.md` | DDD master index |
| `flows/vdd-index.md` | VDD master index |
| `flows/tdd-index.md` | TDD master index |
| `flows/waterfall/_status.md` | Updated with index status |

---

## Subagent Delegation

**Delegate to subagents:**

```
Task: Build [TYPE] index

Prompt:
1. Scan all flows/[type]-*/ directories
2. For each flow, extract:
   - Document existence (requirements, specs, plan, implementation)
   - Status from _status.md
   - Layer classification (L0/L1/L2)
   - Dependencies (if documented)
3. Build index markdown file with:
   - Summary table
   - Statistics
   - Categorization
   - Dependencies/relationships
4. Save to flows/[type]-index.md
5. Return summary to main agent
```

---

## Best Practices

### Do
- Run indexes in parallel when possible
- Update indexes when flows change
- Include statistics for quick overview
- Cross-reference related flows
- Keep index format consistent

### Don't
- Block index builds on missing optional files
- Include flows that don't match naming convention
- Forget to update waterfall status
- Overwrite manual additions to indexes

---

## Error Handling

**If flow directory is malformed:**
- Log warning
- Skip flow
- Continue with remaining flows

**If index file is locked:**
- Retry once
- Report error if still locked
- Continue with other indexes

**If subagent fails:**
- Retry once with same prompt
- If still fails, run in main agent
- Report partial success if only some indexes built

---

*Created: 2026-03-04*
*Version: 1.0*
