# Specifications: Voiceline Adapter Type Inversion

> **Version**: 1.0
> **Status**: DRAFT
> **Last Updated**: 2026-03-09
> **Requirements**: [01-requirements.md](01-requirements.md)

---

## Overview

This document specifies the **Type Inversion** system for Voiceline adapters. Type Inversion provides a software-based right-channel inversion mechanism that enables differential signaling for phone line coupling.

### Purpose

Type Inversion solves the echo problem in acoustic coupling scenarios by:
1. Inverting the right audio channel before output
2. Enabling differential (L - R) signaling to phone lines
3. Leveraging phone echo cancellers for clean audio transfer

### Design Principle

> **Differential Signaling Insight**: When the phone receives L - R (differential), its echo canceller subtracts the echo from the received signal, resulting in clean audio playback without feedback loops.

---

## Electrical Characteristics

### Signal Levels

| Parameter | Symbol | Min | Typ | Max | Unit |
|-----------|--------|-----|-----|-----|------|
| Input Level (Digital) | V_IN | - | 0 dBFS | - | dBFS |
| Output Level (Analog) | V_OUT | - | -12 | -6 | dBm |
| Signal-to-Noise Ratio | SNR | 90 | 95 | - | dB |
| Total Harmonic Distortion | THD | - | 0.01 | 0.1 | % |
| Frequency Response | f | 300 | - | 3400 | Hz |

### Timing Characteristics

| Parameter | Symbol | Min | Typ | Max | Unit |
|-----------|--------|-----|-----|-----|------|
| Processing Latency | t_LATENCY | - | 2 | 5 | ms |
| Sample Rate Support | f_s | 8000 | 16000/44100/48000 | 192000 | Hz |
| Bit Depth | N | 16 | 24 | 32 | bit |
| Channel Configuration | CH | 1 | 2 | - | Mono/Stereo |

---

## Pin Configuration (TRRS Interface)

### 3.5mm TRRS Pinout (CTIA Standard)

```
       Tip   ┌─────────┐  ← Left Channel (L)
             │         │
    Ring 1   ├─────────┤  ← Right Channel Inverted (-R)
             │         │
    Ring 2   ├─────────┤  ← Ground (GND)
             │         │
    Sleeve   └─────────┘  ← Microphone (MIC)

    Plug View (Connector):
         ____
       /      \
      |  TIP   |  ← L
      | RING1  |  ← -R (Inverted)
      | RING2  |  ← GND
      | SLEEVE |  ← MIC
       \____/
```

### Pin Assignments

| Pin | Name | Direction | Description | Voltage |
|-----|------|-----------|-------------|---------|
| Tip | L | Output | Left channel (unchanged) | 0.5 Vrms |
| Ring 1 | -R | Output | Right channel (inverted) | 0.5 Vrms |
| Ring 2 | GND | - | Ground reference | 0 V |
| Sleeve | MIC | Input | Microphone input from phone | 2.2 V bias |

---

## Functional Description

### Block Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Type Inversion System                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐                                               │
│  │  SIP Media   │  Mono [L] or Stereo [L, R]                   │
│  │   Stream     │                                               │
│  └──────┬───────┘                                               │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              InversionPort (PJSIP Media Port)             │   │
│  │                                                            │   │
│  │  ┌─────────────────┐    ┌─────────────────────────────┐  │   │
│  │  │  Mono Expansion │    │  Right Channel Inverter     │  │   │
│  │  │  [L] → [L, -L]  │    │  [L, R] → [L, -R]           │  │   │
│  │  └─────────────────┘    └─────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────┐                                               │
│  │  Android     │  [L, -R] to hardware                         │
│  │  Audio HAL   │                                               │
│  └──────┬───────┘                                               │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────┐                                               │
│  │  TRRS/USB    │  Hardware coupling                            │
│  │   Adapter    │                                               │
│  └──────┬───────┘                                               │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────┐                                               │
│  │  Phone Line  │  Differential: L - R                         │
│  └──────────────┘                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Signal Flow

```
                    ┌──────────────────────────────────────┐
                    │         Type Inversion Chain          │
                    └──────────────────────────────────────┘

SIP RX ──► InversionPort ──► Android Audio ──► TRRS Jack ──► Phone
 [L]                          [L, -R]         [L, -R]       [L - R]
[L, R]                                      (Hardware)    (Differential)
```

---

## Type System

### Interface Definition

```cpp
/**
 * IInversionPort - Interface for right-channel inversion
 * 
 * This interface defines the contract for audio ports that apply
 * right-channel inversion for differential signaling.
 */
class IInversionPort {
public:
    /**
     * Process audio buffer with right-channel inversion
     * 
     * @param buffer Input/output audio buffer (interleaved stereo)
     * @param frame_count Number of frames to process
     * @param sample_rate Sample rate in Hz
     * @param channels Number of channels (must be 2)
     */
    virtual void process(float* buffer, 
                         size_t frame_count,
                         uint32_t sample_rate,
                         uint8_t channels) = 0;
    
    /**
     * Configure inversion behavior
     * 
     * @param enabled Enable/disable inversion
     * @param channel Which channel to invert (0=left, 1=right)
     */
    virtual void configure(bool enabled, uint8_t channel) = 0;
    
    /**
     * Get inversion statistics
     */
    virtual InversionStats getStats() const = 0;
};
```

### Data Types

```cpp
/**
 * Inversion configuration
 */
struct InversionConfig {
    bool enabled;           // Inversion enabled
    uint8_t target_channel; // Channel to invert (0=left, 1=right)
    float gain;             // Post-inversion gain (default: 1.0)
    bool clip_protection;   // Enable clip protection
};

/**
 * Inversion processing statistics
 */
struct InversionStats {
    uint64_t frames_processed;   // Total frames processed
    float peak_level_left;       // Peak level left channel (dBFS)
    float peak_level_right;      // Peak level right channel (dBFS)
    float rms_level_left;        // RMS level left channel (dBFS)
    float rms_level_right;       // RMS level right channel (dBFS)
    uint32_t clip_count;         // Number of clipped samples
    uint32_t sample_rate;        // Current sample rate
};

/**
 * Audio buffer format
 */
enum class AudioFormat {
    INTERLEAVED_S16,    // 16-bit signed integer, interleaved
    INTERLEAVED_FLOAT,  // 32-bit float, interleaved
    PLANAR_S16,         // 16-bit signed integer, planar
    PLANAR_FLOAT        // 32-bit float, planar
};
```

---

## Processing Algorithm

### Mono Input Processing

```
Input: Mono sample L[n]

Step 1: Expand to stereo
  output[2n]   = L[n]        // Left channel
  output[2n+1] = -L[n]       // Right channel (inverted)

Step 2: Apply gain (if configured)
  output[2n]   *= gain
  output[2n+1] *= gain

Step 3: Clip protection
  output[i] = clamp(output[i], -1.0, 1.0)
```

### Stereo Input Processing

```
Input: Stereo samples L[n], R[n]

Step 1: Invert right channel
  output[2n]   = L[n]        // Left unchanged
  output[2n+1] = -R[n]       // Right inverted

Step 2: Apply gain (if configured)
  output[2n]   *= gain
  output[2n+1] *= gain

Step 3: Clip protection
  output[i] = clamp(output[i], -1.0, 1.0)
```

### Implementation Pseudocode

```cpp
void InversionPort::process(float* buffer, 
                            size_t frame_count,
                            uint32_t sample_rate,
                            uint8_t channels) {
    if (channels != 2) {
        throw InvalidChannelCount("Must be stereo");
    }
    
    for (size_t i = 0; i < frame_count; ++i) {
        size_t left_idx  = i * 2;
        size_t right_idx = i * 2 + 1;
        
        // Invert right channel
        buffer[right_idx] = -buffer[right_idx];
        
        // Apply gain
        buffer[left_idx]  *= config_.gain;
        buffer[right_idx] *= config_.gain;
        
        // Clip protection
        buffer[left_idx]  = std::clamp(buffer[left_idx], -1.0f, 1.0f);
        buffer[right_idx] = std::clamp(buffer[right_idx], -1.0f, 1.0f);
        
        // Update statistics
        stats_.peak_level_left  = std::max(stats_.peak_level_left, 
                                           std::abs(buffer[left_idx]));
        stats_.peak_level_right = std::max(stats_.peak_level_right, 
                                           std::abs(buffer[right_idx]));
    }
    
    stats_.frames_processed += frame_count;
}
```

---

## Integration Points

### PJSIP Integration

```cpp
// Create InversionPort
pjmedia_port *inversion_port;
pjmedia_port_create_inversion(&inversion_port, NULL);

// Connect to SIP media stream
pjmedia_conf_add_port(conf, inversion_port, NULL);
pjmedia_conf_connect_port(conf, sip_port, inversion_port, 0);
```

### Android Audio HAL

```cpp
// Audio record configuration
audio_config_t config = {
    .sample_rate = 48000,
    .channel_mask = AUDIO_CHANNEL_OUT_STEREO,
    .format = AUDIO_FORMAT_PCM_FLOAT,
    .frame_count = 480,  // 10ms buffer
};

// Apply inversion before writing to audio track
inversion_port->process(buffer, config.frame_count, 
                        config.sample_rate, 2);
audio_track->write(buffer, config.frame_count);
```

---

## Edge Cases

| Case | Condition | Behavior |
|------|-----------|----------|
| Mono input | Single channel | Expand to stereo, invert right |
| Stereo input | Two channels | Invert right only |
| Silence | All zeros | Pass through unchanged |
| Clipping | |output| > 1.0 | Clamp to [-1.0, 1.0] |
| Sample rate change | Dynamic rate | Reinitialize internal state |
| Channel mismatch | != 2 channels | Error, return invalid param |

---

## Testing

### Unit Tests

```cpp
TEST(TypeInversion, MonoInputBecomesDifferential) {
    float input[] = {1.0f};  // Mono
    float expected[] = {1.0f, -1.0f};  // L, -L
    
    InversionPort port;
    port.process(input, 1, 48000, 2);
    
    EXPECT_FLOAT_EQ(input[0], expected[0]);
    EXPECT_FLOAT_EQ(input[1], expected[1]);
}

TEST(TypeInversion, StereoRightChannelInverted) {
    float input[] = {1.0f, 0.5f};  // L, R
    float expected[] = {1.0f, -0.5f};  // L, -R
    
    InversionPort port;
    port.process(input, 1, 48000, 2);
    
    EXPECT_FLOAT_EQ(input[0], expected[0]);
    EXPECT_FLOAT_EQ(input[1], expected[1]);
}

TEST(TypeInversion, GainApplied) {
    float input[] = {0.5f, -0.5f};
    float expected[] = {1.0f, -1.0f};  // 6dB gain
    
    InversionPort port;
    port.configure(true, 1);
    port.setGain(2.0f);
    port.process(input, 1, 48000, 2);
    
    EXPECT_FLOAT_EQ(input[0], expected[0]);
    EXPECT_FLOAT_EQ(input[1], expected[1]);
}
```

### Integration Tests

```cpp
TEST(TypeInversion, FullSignalChain) {
    // SIP → InversionPort → Android Audio → TRRS → Phone
    auto sip_stream = createSipRxStream();
    auto inversion = createInversionPort();
    auto audio_out = createAndroidAudioOutput();
    
    connect(sip_stream, inversion);
    connect(inversion, audio_out);
    
    // Verify differential output
    auto measured = measureTRRSOutput();
    EXPECT_NEAR(measured.differential, measured.L - measured.R, 0.01);
}
```

---

## Dependencies

| Component | Version | Required | Notes |
|-----------|---------|----------|-------|
| PJSIP Media Port | 2.9+ | Yes | Base class for InversionPort |
| Android Audio HAL | API 21+ | Yes | Audio output interface |
| C++ Standard | C++17 | Yes | std::clamp, std::optional |

---

## References

- `sdd-pjsip-mode-inversion` - InversionPort implementation
- `sdd-voiceline-adapter-interface-trrs` - TRRS hardware adapter
- `sdd-voiceline-adapter-interface-usb-with-dac` - USB UAC adapter
- CTIA Accessory Specification v2.2 - TRRS pinout standard

---

## Hardware Schematic (4R+1C Differential Coupling Circuit)

### Complete Circuit Diagram

```
Software Inversion (InversionPort)
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  TRRS Jack (CTIA)         4R+1C Passive Circuit              │
│                                                               │
│       Tip (L) ──┬────────────────────────────────────┐       │
│                 │                                    │       │
│                 │                                   [R1]     │
│                 │                                   10kΩ     │
│                 │                                    │       │
│                 │      ┌─────────────────────────────┤       │
│                 │      │                             │       │
│    Ring 1 (-R) ─┼──────┤                             │       │
│                 │      │                            [R2]     │
│                 │      │                            10kΩ     │
│                 │      │                             │       │
│    Ring 2 (GND) ┼──────┴─────────────────────────────┼───────┤
│                 │                                    │       │
│                 │                                   [R3]     │
│                 │                                   47kΩ     │
│                 │                                    │       │
│                 │                                   [C1]     │
│                 │                                   47nF     │
│                 │                                    │       │
│                 │      ┌─────────────────────────────┤       │
│                 │      │                             │       │
│    Sleeve (MIC) ─┴──────┤                            [R4]     │
│                        │                            10kΩ     │
│                        │                             │       │
│                        └─────────────────────────────┴───────┤
│                                                              │
│                        GND ──────────────────────────────────┤
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Simplified Schematic

```
     R      L
     |      |
     |     [R1] 10k
     |      |
     |      +----------------+
     |      |                |
     |     [R2] 10k          |
     |      |                |
     +------+                |
            |                |
           [R3] 47k          |
            |                |
           [C1] 47n          |
            |                |
            +------[R4]------+
            |      10k       |
           MIC              GND
```

### Component Specifications

| Component | Value | Tolerance | Power Rating | Type |
|-----------|-------|-----------|--------------|------|
| R1 | 10kΩ | ±1% | 1/8W | Metal film |
| R2 | 10kΩ | ±1% | 1/8W | Metal film |
| R3 | 47kΩ | ±1% | 1/8W | Metal film |
| R4 | 10kΩ | ±1% | 1/8W | Metal film |
| C1 | 47nF | ±10% | 50V | X7R ceramic |

### Circuit Analysis

**Differential Output:**
```
V_diff = V_L - V_(-R) = V_L - (-V_R) = V_L + V_R
```

**High-Pass Filter (C1 + R3):**
```
f_c = 1 / (2π × R3 × C1)
f_c = 1 / (2π × 47000 × 47×10^-9)
f_c ≈ 72 Hz
```
This ensures voice frequencies (300Hz-3.4kHz) pass unattenuated.

**Impedance Matching:**
- Output impedance: ~10kΩ (R1 || R2)
- Input impedance (phone side): 600Ω typical
- Mismatch handled by transformer or active buffering if needed

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
