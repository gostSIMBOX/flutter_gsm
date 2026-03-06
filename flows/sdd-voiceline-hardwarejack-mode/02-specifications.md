# Specifications: Voice Line Hardware Jack Mode

> **Version**: 1.0
> **Status**: DRAFT
> **Last Updated**: 2026-03-06
> **Requirements**: [01-requirements.md](01-requirements.md)

---

## Overview

This document specifies the implementation of a custom PJSIP media port (`HardwareAdapterPort`) that converts mono audio to stereo with inverted right channel. This enables connectivity with hardware adapters that use differential signaling for voice line connection via TRRS jack.

The implementation is based on provided reference code and will be integrated into the PJSIP media endpoint within the GOSTsimbox Android Gateway.

---

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `pjmedia` | Modify | Custom media port integration |
| `android_jni_dev.c` | Modify | Integration with Android audio device |
| `nmpjsip-builder/patch_*` | Modify | Add to PJSIP patch structure |
| Gateway audio path | Modify | Insert HardwareAdapterPort in audio chain |

---

## Architecture

### Component Diagram

```
┌──────────────────────────────────────────────────────────────┐
│  PJSIP Media Endpoint                                         │
│                                                               │
│  ┌─────────────────┐     ┌──────────────────────────────┐   │
│  │  Upstream Port  │────►│  HardwareAdapterPort          │   │
│  │  (SIP Stream /  │     │                               │   │
│  │   Audio Device) │     │  ┌─────────────────────────┐  │   │
│  │  Mono Input     │     │  │  Mono → Stereo Converter │  │   │
│  └─────────────────┘     │  │  Right Channel Inverter  │  │   │
│                          │  └─────────────────────────┘  │   │
│                          │                               │   │
│                          │  Stereo Output (L+R-)         │   │
│                          └───────────────────────────────┘   │
│                                               │               │
└───────────────────────────────────────────────┼───────────────┘
                                                │
                                                ▼
                                    ┌───────────────────────┐
                                    │  Hardware Jack (TRRS) │
                                    │  Differential Input   │
                                    └───────────────────────┘
```

### Data Flow

```
1. SIP Call Established
         │
         ▼
2. PJSIP Media Stream Created
         │
         ▼
3. Audio Frames Flow (Mono, 16-bit PCM)
         │
         ▼
4. HardwareAdapterPort::GetFrame()
         │
         ├─► Read mono frame from upstream
         ├─► Allocate stereo buffer (from pool)
         ├─► For each sample i:
         │     output[i*2]   = input[i]        // Left = original
         │     output[i*2+1] = -input[i]       // Right = inverted
         └─► Update frame buffer pointer
         │
         ▼
5. Stereo Frame Output (L+R-)
         │
         ▼
6. To Hardware Jack / Audio Device
```

---

## Interfaces

### Custom Media Port Interface

```cpp
class HardwareAdapterPort : public pjmedia_port {
public:
    // Constructor
    HardwareAdapterPort(pjmedia_port *upstream_port);
    
    // Static callback functions (PJSIP C interface)
    static pj_status_t GetFrame(pjmedia_port *port, pjmedia_frame *frame);
    static pj_status_t PutFrame(pjmedia_port *port, pjmedia_frame *frame);
    static pj_status_t OnDestroy(pjmedia_port *port);

private:
    pjmedia_port *upstream_port;   // Upstream audio source
    pj_pool_t *pool;               // Memory pool for buffers
};
```

### Factory Function

```cpp
/**
 * Create Hardware Adapter mode port
 * 
 * @param med_endpt     PJSIP media endpoint
 * @param upstream_port Upstream audio port (SIP stream or audio device)
 * @param p_port        Output: created hardware adapter port
 * @return              PJ_SUCCESS on success
 */
pj_status_t create_hardware_adapter_mode(
    pjmedia_endpt *med_endpt,
    pjmedia_port *upstream_port,
    pjmedia_port **p_port
);
```

---

## Data Models

### Audio Frame Format

**Input Format** (from upstream):
```
Format: PJMEDIA_TYPE_AUDIO
Channels: 1 (Mono)
Sample Rate: 8000, 16000, or 48000 Hz
Bit Depth: 16-bit PCM
Samples per Frame: Variable (typically 10ms worth of samples)
```

**Output Format** (to hardware):
```
Format: PJMEDIA_TYPE_AUDIO
Channels: 2 (Stereo)
Sample Rate: Same as input
Bit Depth: 16-bit PCM
Samples per Frame: 2x input samples (stereo = 2 channels)
```

### Frame Structure

```cpp
// Input mono frame
struct MonoFrame {
    pj_int16_t samples[N];  // N mono samples
};

// Output stereo frame
struct StereoFrame {
    struct {
        pj_int16_t left;    // Original sample
        pj_int16_t right;   // Inverted sample (-left)
    } pairs[N];             // N stereo pairs
};
```

---

## Behavior Specifications

### Happy Path

1. **Initialization**
   - `create_hardware_adapter_mode()` called with media endpoint and upstream port
   - Memory pool created for buffer allocation
   - `HardwareAdapterPort` instance allocated and initialized
   - Port interface functions set (get_frame, put_frame, destroy)
   - Port registered with media endpoint

2. **Frame Processing (GetFrame)**
   - Upstream port returns mono audio frame
   - Input buffer: `int16_t[N]` (N mono samples)
   - Output buffer allocated from pool: `int16_t[N*2]` (N stereo pairs)
   - For each sample `i` from 0 to N-1:
     - `output[i*2] = input[i]` (Left channel = original)
     - `output[i*2+1] = -input[i]` (Right channel = inverted)
   - Frame buffer pointer updated to output buffer
   - Frame size updated to `N*2*sizeof(int16_t)`
   - Return `PJ_SUCCESS`

3. **Frame Playback (PutFrame)**
   - No-op (playback-only port)
   - Return `PJ_SUCCESS`

4. **Destruction**
   - `OnDestroy()` called
   - Memory pool released
   - Resources cleaned up

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Empty frame | Upstream returns empty buffer | Pass through unchanged, return success |
| Non-audio frame | Frame type != `PJMEDIA_FRAME_TYPE_AUDIO` | Pass through unchanged, return success |
| Upstream error | Upstream `GetFrame()` returns error | Propagate error code to caller |
| Pool exhaustion | Memory pool cannot allocate buffer | Return `PJ_ENOMEM` error |
| Null pointers | port or frame is NULL | Return `PJ_EINVAL` error |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| `PJ_ENOMEM` | Memory pool exhausted | Log error, return error code |
| `PJ_EINVAL` | Invalid parameters (NULL) | Return error code immediately |
| Upstream error | Upstream port failed | Propagate error code |
| Frame type mismatch | Non-audio frame | Pass through without transformation |

---

## Dependencies

### Requires

- **PJSIP 2.9+** - Media endpoint and port API
- **Android JNI Audio Device** - Upstream/downstream audio path
- **nmpjsip-builder** - Build system integration

### Blocks

- **Hardware Jack Integration** - Requires this to be complete first
- **Voice Line Testing** - Cannot test hardware without this

---

## Integration Points

### External Systems

- **Hardware Adapter** - Physical TRRS jack with differential input
- **GSM Radio** - External hardware connected via jack

### Internal Systems

| Component | Integration Point | File |
|-----------|------------------|------|
| PJSIP Media Endpoint | Port registration | `pjmedia_endpt_create_port()` |
| Android Audio Device | Upstream/Downstream port | `android_jni_dev.c` |
| SIP Call Stream | Media stream connection | `pjsua_call_media_start()` |
| Build System | Patch integration | `nmpjsip-builder/src/patch_2.9/` |

---

## Implementation Location

### New Files

```
nmpjsip-builder/src/patch_2.9/src/pjsip2/pjmedia/src/pjmedia-audiodev/hardware_adapter_port.c
nmpjsip-builder/src/patch_2.9/src/pjsip2/pjmedia/include/pjmedia-audiodev/hardware_adapter_port.h
```

### Modified Files

```
nmpjsip-builder/src/patch_2.9/src/pjsip2/pjmedia/src/pjmedia-audiodev/android_jni_dev.c
  - Include hardware_adapter_port.h
  - Create HardwareAdapterPort when hardware mode enabled
  - Connect port in audio path
```

---

## Testing Strategy

### Unit Tests

```cpp
// Test mono-to-stereo conversion
TEST(HardwareAdapterPort, MonoToStereoConversion) {
    // Create test mono frame: [1, 2, 3, 4]
    // Expected output: [1, -1, 2, -2, 3, -3, 4, -4]
}

// Test error handling
TEST(HardwareAdapterPort, NullParameterHandling) {
    // Verify PJ_EINVAL returned for NULL parameters
}

// Test memory management
TEST(HardwareAdapterPort, PoolAllocation) {
    // Verify no memory leaks on destroy
}
```

### Integration Tests

```cpp
// Test with PJSIP media endpoint
TEST(HardwareAdapterPortIntegration, MediaEndpointIntegration) {
    // Create port, connect to media endpoint, verify audio flows
}

// Test with Android audio device
TEST(HardwareAdapterPortIntegration, AndroidAudioDevice) {
    // Integrate with android_jni_dev, verify end-to-end audio
}
```

### Manual Verification

1. Build GOSTsimbox with hardware adapter mode
2. Connect hardware adapter to device headphone jack
3. Make SIP call
4. Verify audio quality on both ends
5. Verify no audio artifacts or dropouts

---

## Build Integration

### CMakeLists.txt Addition

```cmake
# Add hardware adapter port to PJSIP build
pjmedia_audiodev_src(hardware_adapter_port.c)
```

### Header Include Path

```cmake
include_directories(
    ${PJMEDIA_INCLUDE_DIR}
    ${PJMEDIA_AUDIODEV_INCLUDE_DIR}
)
```

---

## Configuration

### Compile-Time Options

```cpp
// Enable/disable hardware adapter mode
#define PJMEDIA_HARDWARE_ADAPTER_ENABLED 1

// Default pool size
#define HARDWARE_ADAPTER_POOL_SIZE 1024

// Default pool increment
#define HARDWARE_ADAPTER_POOL_INC 1024
```

### Runtime Configuration

```cpp
typedef struct hardware_adapter_config {
    pj_bool_t enabled;        // Enable hardware adapter mode
    pjmedia_format_id format; // Audio format (default: PJMEDIA_FORMAT_PCM)
} hardware_adapter_config_t;
```

---

## Open Design Questions

- [ ] **Pool Management**: Should we use one pool per port or shared pool?
- [ ] **Buffer Reuse**: Should we reuse output buffers to reduce allocations?
- [ ] **Format Negotiation**: Should we support multiple input formats or fixed format?
- [ ] **Logging Level**: What log level for frame processing? (DEBUG, INFO?)

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]

---

*Created by /sdd - Specifications based on provided reference code*
