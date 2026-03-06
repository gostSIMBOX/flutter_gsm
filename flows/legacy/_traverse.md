# Traversal State

> Persistent recursion stack for tree traversal. AI reads this to know where it is and what to do next.

## Mode

- **BFS** (no comment): Breadth-first, analyze all domains systematically
- **DFS** (with comment): Depth-first, focus deeply on specific topic

## Source Path

[project root]

## Focus (DFS only)

magisk-voice-recording - Voice call recording from phone line via Magisk

## Existing Flows Index

| Flow Path | Type | Topics | Key Decisions |
|-----------|------|--------|---------------|
| flows/sdd-core-architecture/ | SDD | Clean Architecture, DI, error handling | get_it, ErrorHandler |
| flows/sdd-gateway-service/ | SDD | GSM↔SIP routing, orchestration | bidirectional bridge |
| flows/sdd-telephony/ | SDD | Android telephony, MethodChannel | permission_handler |
| flows/sdd-android-telecom-integration/ | SDD | InCallService, Call API | EventChannel streaming |
| flows/sdd-call-model/ | SDD | TeleCall data model | 40+ fields |
| flows/sdd-patch-management/ | SDD | PJSIP patches, audio | WebRTC AEC, Qualcomm restrictions |
| flows/sdd-magisk-voice-recording/ | SDD | Magisk, CAPTURE_AUDIO_OUTPUT, privapp permissions | systemless root, privileged permissions |
| flows/adr-001-clean-architecture/ | ADR | Architecture pattern | layers, dependencies |
| flows/adr-002-dependency-injection/ | ADR | DI framework | get_it chosen |
| flows/adr-003-state-management/ | ADR | State management | Provider chosen |
| flows/adr-004-error-handling/ | ADR | Error handling strategy | centralized ErrorHandler |
| flows/adr-005-service-orchestration/ | ADR | Service coordination | orchestration pattern |

## Current Stack

> Read top-to-bottom = root-to-current. Last item = where AI is now.

```
/ (root)                                    COMPLETED
└── magisk-voice-integration                EXITING
```

## Stack Operations Log

| # | Operation | Node | Phase | Result |
|---|-----------|------|-------|--------|
| 1-23 | [Previous BFS operations] | various | COMPLETED | See above |
| 24 | PUSH | magisk-voice-integration | ENTERING | DFS focus on Magisk voice recording |
| 25 | UPDATE | magisk-voice-integration | EXPLORING | Magisk module structure analyzed |
| 26 | UPDATE | magisk-voice-integration | SPAWNING | Child concepts identified |
| 27 | UPDATE | magisk-voice-integration | SYNTHESIZING | Understanding validated |
| 28 | UPDATE | magisk-voice-integration | EXITING | SDD flow created |
| 29 | POP | magisk-voice-integration | DONE | SDD: flows/sdd-magisk-voice-recording/ |

## Current Position

- **Node**: / (root)
- **Phase**: COMPLETED (DFS focus complete)
- **Depth**: 0
- **Path**: /

## Pending Children

> Children identified but not yet explored (LIFO - last added explored first)

```
[none - DFS focus complete]
```

## Visited Nodes

> Completed nodes with their summaries

| Node Path | Summary | Flow Created |
|-----------|---------|--------------|
| core-architecture | Clean Architecture, get_it DI, ErrorHandler | SDD: flows/sdd-core-architecture/ |
| gateway-service | Gateway orchestration, bidirectional routing | SDD: flows/sdd-gateway-service/ |
| telephony-integration | Android telephony via MethodChannel | - |
| sip-protocol | SIP VoIP call handling | - |
| smpp-protocol | SMS/SMPP messaging | - |
| ui-theming | Theme management (Light/Dark/System) | - |
| logging-monitoring | Connection monitoring, latency tracking | - |
| testing-strategy | Unit/widget/integration test coverage | - |
| **magisk-voice-integration** | **Magisk module, CAPTURE_AUDIO_OUTPUT, privapp permissions, Qualcomm restrictions** | **SDD: flows/sdd-magisk-voice-recording/** |

## DFS Focus Summary: Magisk Voice Recording

**Objective**: Document Magisk module for voice call recording from phone line

**Sources Analyzed**:
- `magisk/gateway/` - Magisk module structure
- `magisk/gateway/system/etc/permissions/privapp-permissions-gateway.xml` - Privileged permissions
- `lib/models/line_info.dart` - LineInfo.canRecordVoiceToRadio capability
- `lib/domain/entities/gateway_config.dart` - enableCallRecording config
- `nmpjsip-builder/src/patch_2.9/` - PJSIP Android audio device (VOICE_CALL source)
- `flows/sdd-patch-management/02-specifications.md` - Qualcomm restrictions research

**Key Findings**:
1. Magisk grants CAPTURE_AUDIO_OUTPUT permission (required for VOICE_CALL audio capture)
2. Privapp permissions whitelist enables system-level access for gateway app
3. LineInfo exposes voice recording capabilities (canRecordVoiceToRadio, etc.)
4. Qualcomm restrictions can be disabled via system properties
5. PJSIP uses Android AudioRecord API with VOICE_CALL source

**Flow Created**: `flows/sdd-magisk-voice-recording/`
- 01-requirements.md: Functional/non-functional requirements
- 02-specifications.md: Architecture, components, testing specs
- _status.md: DRAFT status, progress tracking

## Next Action

```
DFS traversal complete. Magisk voice recording integration documented.

Options:
1. Review and approve sdd-magisk-voice-recording flow
2. Continue DFS on other topics (specify with: /legacy path "topic")
3. Resume BFS traversal for remaining domains
4. Create ADR for Magisk integration decision
```

---

## Phase Definitions

### ENTERING
- Just arrived at this node
- Create _node.md file
- Read relevant source files
- Form initial hypothesis

### EXPLORING
- Deep analysis of this node's scope
- Validate/refine hypothesis
- Identify what belongs here vs. children

### SPAWNING
- Identify child concepts that need deeper exploration
- Add children to Pending stack
- Children are LOGICAL concepts, not filesystem paths

### SYNTHESIZING
- All children completed (or no children)
- Combine insights from children
- Update this node's _node.md with full understanding

### EXITING
- Pop from stack
- Bubble up summary to parent
- Mark as visited

---

## Resume Protocol

When `/legacy` starts:
1. Read _traverse.md
2. Find current position (top of stack)
3. Check phase
4. Continue from that phase

If interrupted mid-phase:
- Re-enter same phase (idempotent operations)

---

*Updated by /legacy recursive traversal*
