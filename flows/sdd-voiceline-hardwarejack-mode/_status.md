# SDD: Voice Line Hardware Jack Mode - Status

**Type**: SDD (Spec-Driven Development)
**Module**: voiceline-hardwarejack-mode
**Status**: DRAFT
**Created**: 2026-03-06
**Current Phase**: SPECIFICATIONS

---

## Progress

- [x] SDD flow initialized
- [x] Requirements document created (01-requirements.md)
- [ ] Requirements approved
- [x] Specifications document created (02-specifications.md)
- [ ] Specs approved
- [ ] Implementation plan created (03-plan.md)
- [ ] Plan approved
- [ ] Implementation started
- [ ] Tests created
- [ ] Documentation reviewed
- [ ] Approved for production

---

## Summary

Implement a PJSIP custom media port (`HardwareAdapterPort`) that provides "Hardware Adapter" mode for voice line integration. This mode converts mono audio to stereo with inverted right channel, enabling compatibility with hardware adapters that use differential signaling for voice line connection.

---

## Current Phase: SPECIFICATIONS

### What Has Been Specified

**Architecture**:
- Custom `pjmedia_port` subclass (`HardwareAdapterPort`)
- Factory function `create_hardware_adapter_mode()`
- Integration with PJSIP media endpoint

**Audio Transformation**:
- Input: Mono PCM (16-bit, configurable sample rate)
- Output: Stereo PCM (16-bit, same sample rate)
- Processing: Left=original, Right=inverted (-sample)

**Integration**:
- New files: `hardware_adapter_port.c`, `hardware_adapter_port.h`
- Modified: `android_jni_dev.c` (integration with Android audio device)
- Build: CMakeLists.txt updates for PJSIP build system

**Testing**:
- Unit tests for conversion logic
- Integration tests with media endpoint
- Manual verification with hardware adapter

### Open Questions (Specifications)

- [ ] **Pool Management**: One pool per port or shared pool?
- [ ] **Buffer Reuse**: Reuse output buffers to reduce allocations?
- [ ] **Format Negotiation**: Support multiple input formats or fixed?
- [ ] **Logging Level**: DEBUG or INFO for frame processing?

---

## Next Steps

1. **Review requirements** - Confirm acceptance criteria are complete
2. **Review specifications** - Validate architecture and integration approach
3. **Answer open questions** - Resolve design decisions
4. **Create implementation plan** - Break down into atomic tasks
5. **Begin implementation** - Once plan is approved

---

## Documents

| Document | Status | Description |
|----------|--------|-------------|
| `01-requirements.md` | DRAFT | User stories, acceptance criteria, constraints |
| `02-specifications.md` | DRAFT | Architecture, interfaces, integration points |
| `03-plan.md` | NOT STARTED | Implementation tasks, estimates, dependencies |
| `04-implementation-log.md` | NOT STARTED | Progress tracking during implementation |

---

## Blockers

None currently. Waiting for requirements and specs approval before proceeding to planning.

---

## Notes for Handoff

**Context**: This SDD is based on reference code provided by user for PJSIP hardware adapter mode. The implementation enables differential audio signaling for hardware jack connectivity.

**Key Files to Create**:
- `nmpjsip-builder/src/patch_2.9/src/pjsip2/pjmedia/src/pjmedia-audiodev/hardware_adapter_port.c`
- `nmpjsip-builder/src/patch_2.9/src/pjsip2/pjmedia/include/pjmedia-audiodev/hardware_adapter_port.h`

**Key Files to Modify**:
- `nmpjsip-builder/src/patch_2.9/src/pjsip2/pjmedia/src/pjmedia-audiodev/android_jni_dev.c`

**Integration Point**: Between PJSIP media stream and Android audio device for hardware jack output.

---

*Created by /sdd start sdd-voiceline-hardwarejack-mode*
*Last Updated: 2026-03-06*
