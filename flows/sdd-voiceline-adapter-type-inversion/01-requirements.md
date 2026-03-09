# Requirements: Voiceline Adapter Type Inversion

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-03-09

---

## Problem Statement

When coupling SIP audio to phone lines via acoustic or direct electrical connection, **echo feedback** occurs because the phone's microphone picks up the speaker output. This creates an unpleasant feedback loop that degrades call quality.

**Type Inversion** solves this by:
1. Inverting the right audio channel before output
2. Creating a differential signal (L - R) that phones interpret correctly
3. Leveraging the phone's built-in echo canceller to prevent feedback

### Why This Matters

- Enables clean acoustic coupling between SIP and GSM/phone lines
- Prevents echo without requiring additional hardware
- Works with existing phone echo cancellers (no phone modification needed)

---

## User Stories

### Primary

**As a** system integrator
**I want** right-channel inversion for audio output
**So that** I can couple SIP audio to phone lines without echo feedback

### Secondary

**As a** developer
**I want** clear datasheet-style documentation for the inversion type
**So that** I can implement and test it correctly

**As a** hardware designer
**I want** to understand the electrical characteristics
**So that** I can design compatible adapter circuits

---

## Acceptance Criteria

### Must Have

1. **Given** mono audio input [L]
   **When** processed by Type Inversion
   **Then** output is differential [L, -L]

2. **Given** stereo audio input [L, R]
   **When** processed by Type Inversion
   **Then** output is [L, -R] (right channel inverted)

3. **Given** any audio input
   **When** processed
   **Then** signal stays within [-1.0, 1.0] range (no clipping)

4. **Given** the InversionPort interface
   **When** documented
   **Then** it reads like a datasheet with electrical specs, timing, and pinouts

### Should Have

- Configurable gain control
- Statistics tracking (peak, RMS, clip count)
- Support for multiple sample rates (8k, 16k, 44.1k, 48k, 96k, 192k Hz)

### Won't Have (This Iteration)

- Hardware inversion (software-only)
- Left channel inversion option (right-channel is standard)
- Multi-channel (>2) support

---

## Constraints

- **Technical**: Must integrate with PJSIP 2.9+ media port framework
- **Performance**: Processing latency < 5ms
- **Platform**: Android API 21+, works with Audio HAL
- **Dependencies**: Requires `sdd-pjsip-mode-inversion` base implementation

---

## Open Questions

- [ ] Should we support configurable inversion polarity?
- [ ] Should we support dynamic channel routing (swap L/R before inversion)?
- [ ] What's the acceptable THD (Total Harmonic Distortion) threshold?

---

## References

- `flows/sdd-pjsip-mode-inversion/` - InversionPort implementation
- `flows/sdd-voiceline-adapter-interface-trrs/` - TRRS hardware adapter
- CTIA Accessory Specification v2.2 - TRRS pinout standard

---

## Hardware Schematic (4R+1C Differential Coupling)

```
    LEFT    ──────────────────────────┬──────────────────┐
                                      │                  │
                                     ┌┴┐                 │
                                     │ │ R1 10k          │
                                     └┬┘                 │
                                      │                  │
                                      │                  │
                                      │                  │
                                      │                  │
    RIGHT   ────────┐                 │                  │
                    │                 │                  │
                   ┌┴┐                │                  │
                   │ │ R2 10k         │                  │
                   └┬┘                │                  │
                    │                 │                  │
                    │                 │                  │
                    │                 │                  │
                    │                 │                 ┌┴┐
                    │                 │                 │ │ R3 47k
                    │                 │                 └┬┘
                    │                 │                  │
                    │                 │                 ─┴─
                    │                 │                 ─┬─ C1 47nF
                    │                 │                  │
                    │                 │                  │
                    │                 │                  │
    GND     ────────┼─────────────────┘                  │
                    │                                    │
                   ┌┴┐                                   │
                   │ │ R4 10k                            │
                   └┬┘                                   │
                    │                                    │
    MIC     ────────┴────────────────────────────────────┘
```

### Component Values

| Component | Value | Function |
|-----------|-------|----------|
| R1 | 10kΩ | Left channel series resistor |
| R2 | 10kΩ | Right channel series resistor |
| R3 | 47kΩ | Differential mixing resistor |
| R4 | 10kΩ | Microphone bias resistor |
| C1 | 47nF | AC coupling capacitor |

### Design Notes

- **R1, R2**: Match impedance for balanced L/R paths
- **R3**: Sets differential gain and mixing ratio
- **C1**: Blocks DC, passes 300Hz-3.4kHz voice band
- **R4**: Provides microphone bias for phone input

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
