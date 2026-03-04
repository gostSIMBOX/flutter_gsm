# 01-Visual Requirements: Video Calling UI

## Overview

This document describes the visual and interaction requirements for video calling features in applications using react-native-sip2.

## Design Principles

1. **Focus on Content**: Video should dominate the screen
2. **Minimal UI**: Controls should not obstruct video
3. **Clear Affordances**: Call actions should be obvious
4. **Accessibility**: Large touch targets, high contrast
5. **Platform Consistency**: Follow iOS/Android design patterns

## Visual Components

### VC-1: Remote Video Display

**Component**: `RemoteVideoView`

**Purpose**: Display the remote participant's video stream.

**Visual Requirements**:

| Aspect | Requirement |
|--------|-------------|
| **Size** | Full screen or primary content area |
| **Aspect Ratio** | Maintain video aspect ratio (letterbox if needed) |
| **Scaling** | Support 'contain' (full video visible) or 'cover' (fill screen) |
| **Position** | Behind all UI controls (z-index: 0) |
| **Background** | Black or blurred placeholder when video unavailable |
| **Loading State** | Show avatar or spinner while connecting |

**Layout Example**:
```
┌─────────────────────────────────┐
│                                 │
│     [Remote Video Fullscreen]   │
│                                 │
│                                 │
│  [Controls Overlay - Bottom]    │
└─────────────────────────────────┘
```

**Props**:
```javascript
<RemoteVideoView
  windowId={call.getMedia().remoteWindowId}
  objectFit="cover"  // or 'contain'
  style={{ flex: 1 }}
/>
```

### VC-2: Local Video Preview

**Component**: `PreviewVideoView`

**Purpose**: Display self-view (local camera preview).

**Visual Requirements**:

| Aspect | Requirement |
|--------|-------------|
| **Size** | Picture-in-picture (120x160 or 16:9 ratio) |
| **Position** | Top corner (typically top-right) |
| **Border** | Subtle shadow or border for separation |
| **Corner Radius** | 8-12px rounded corners |
| **Z-Index** | Above remote video (overlay) |
| **Draggable** | Optional: user can reposition |
| **Tap to Swap** | Optional: tap to swap camera |

**Layout Example**:
```
┌─────────────────────────────────┐
│                    ┌──────────┐ │
│                    │ [Local]  │ │
│                    │ [Preview]│ │
│                    └──────────┘ │
│                                 │
│     [Remote Video]              │
│                                 │
└─────────────────────────────────┘
```

**Props**:
```javascript
<PreviewVideoView
  deviceId={cameraDeviceId}
  objectFit="contain"
  style={{
    position: 'absolute',
    top: 20,
    right: 20,
    width: 120,
    height: 160,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 5,
  }}
/>
```

### VC-3: Call Controls Bar

**Purpose**: Provide call action buttons.

**Visual Requirements**:

| Aspect | Requirement |
|--------|-------------|
| **Position** | Bottom of screen (thumb zone) |
| **Height** | 80-100dp (includes safe area) |
| **Background** | Semi-transparent blur or solid color |
| **Button Size** | Minimum 44x44dp (accessibility) |
| **Spacing** | 16-24dp between buttons |
| **Icons** | Clear, recognizable symbols |
| **Labels** | Optional text below icons |

**Standard Buttons**:

| Button | Icon | Position | Priority |
|--------|------|----------|----------|
| **End Call** | Red phone hangup | Center | Primary |
| **Mute** | Microphone on/off | Left | High |
| **Speaker** | Speaker on/off | Left | Medium |
| **Video Toggle** | Camera on/off | Left | High |
| **Hold** | Pause icon | Right | Medium |
| **More** | Three dots | Right | Low |

**Layout Example**:
```
┌─────────────────────────────────┐
│                                 │
│     [Remote Video]              │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 🎤  🔊  📹   🔴   ⏸   ⋮  │  │
│  │Mute Spk Vid  End  Hold More│  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**Button States**:

| State | Visual Treatment |
|-------|------------------|
| **Active** | Filled icon, accent color |
| **Inactive** | Outlined icon, white/gray |
| **Disabled** | 50% opacity, no interaction |
| **Pressed** | Scale down to 90%, darker background |

### VC-4: Call Information Overlay

**Purpose**: Display call status and participant info.

**Visual Requirements**:

| Aspect | Requirement |
|--------|-------------|
| **Position** | Top of screen (above video) |
| **Height** | 60-80dp |
| **Background** | Gradient overlay (transparent to black) |
| **Text Color** | White with shadow for contrast |
| **Font Size** | 16-20sp for name, 14sp for status |

**Content**:
```
┌─────────────────────────────────┐
│  ┌─────────────────────────┐    │
│  │ 👤 John Doe             │    │
│  │ 📞 00:42 (connected)    │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

**Information Hierarchy**:
1. **Participant Name/Number** (largest)
2. **Call State** (connected, ringing, on hold)
3. **Duration** (live counter)
4. **Connection Quality** (optional indicator)

### VC-5: Incoming Call Screen

**Purpose**: Display incoming call with answer/decline options.

**Visual Requirements**:

| Aspect | Requirement |
|--------|-------------|
| **Background** | Full screen caller video or avatar |
| **Caller Info** | Large, centered at top |
| **Action Buttons** | Bottom, large touch targets |
| **Answer Button** | Green, prominent, slide-to-answer optional |
| **Decline Button** | Red, secondary position |

**Layout Example**:
```
┌─────────────────────────────────┐
│                                 │
│         👤 John Doe             │
│      +1 (555) 123-4567          │
│         Video Call              │
│                                 │
│                                 │
│      📞           📞            │
│    Decline      Answer          │
│     (red)       (green)         │
│                                 │
└─────────────────────────────────┘
```

**Interaction Patterns**:
- **Slide to Answer**: Swipe green button right (prevents accidental answer)
- **Tap to Decline**: Single tap red button
- **Auto-answer**: Optional after N seconds

### VC-6: Video Quality Indicator

**Purpose**: Show current video quality status.

**Visual Requirements**:

| Aspect | Requirement |
|--------|-------------|
| **Position** | Corner of video (typically top-right) |
| **Size** | Small, unobtrusive (24x24dp) |
| **States** | Excellent, Good, Fair, Poor |

**Quality States**:

| Quality | Icon | Color | Meaning |
|---------|------|-------|---------|
| **Excellent** | 📶📶📶 | Green | HD video, no artifacts |
| **Good** | 📶📶 | Yellow | SD video, minor artifacts |
| **Fair** | 📶 | Orange | Low resolution, some freezing |
| **Poor** | ⚠️ | Red | Video frozen or unavailable |

## Interaction Patterns

### IP-1: Mute/Unmute

**Gesture**: Tap mute button

**Visual Feedback**:
- Button icon changes (mic → mic-off)
- Button color changes (white → red)
- Optional: Toast notification "Muted"

**State Persistence**:
- Mute state persists across screen rotations
- Mute state visible in call info

### IP-2: Camera Switch

**Gesture**: Tap camera button

**Visual Feedback**:
- Icon animates (rotate or flip)
- Preview video switches camera
- Brief loading indicator if needed

**State Persistence**:
- Camera choice persists during call
- Resets to front camera on new call

### IP-3: Speaker Toggle

**Gesture**: Tap speaker button

**Visual Feedback**:
- Button icon changes (speaker → earpiece)
- Icon fills when active
- Audio route changes immediately

**Platform Differences**:
- **iOS**: Uses `AVAudioSession`
- **Android**: Uses `AudioManager.setSpeakerphoneOn()`

### IP-4: End Call

**Gesture**: Tap red end call button

**Visual Feedback**:
- Button scales down on press
- Call ends immediately
- Navigate back to call log or main screen
- Optional: Call duration summary

**Confirmation**:
- No confirmation dialog (immediate action)
- Prevent accidental taps with 500ms debounce

## Accessibility Requirements

### A-1: Touch Targets

- Minimum size: 44x44dp (iOS) / 48x48dp (Android)
- Spacing between targets: 8dp minimum
- Edge targets: 16dp margin from screen edge

### A-2: Color Contrast

- Text on video: 4.5:1 contrast ratio minimum
- Icons: 3:1 contrast ratio minimum
- Use text shadows for readability on video

### A-3: VoiceOver/TalkBack

- All buttons must have accessibility labels
- Video views should announce "Remote video" or "Local preview"
- Call state changes should be announced

### A-4: Dynamic Type

- Support system font size settings
- UI should adapt to larger text sizes
- Minimum font size: 14sp (even if user sets smaller)

## Platform-Specific Patterns

### iOS (Human Interface Guidelines)

- Use SF Symbols for icons
- Follow iOS CallKit UI patterns
- Safe area insets for notch devices
- Haptic feedback on button presses

### Android (Material Design)

- Use Material icons
- Follow Android ConnectionService patterns
- Handle back button properly
- Ripple effects on buttons

## Responsive Layouts

### Small Screens (< 5")

- Reduce control bar height
- Smaller local preview (80x120)
- Fewer visible buttons (use "More" menu)
- Larger touch targets prioritized

### Large Screens (> 6.5")

- Larger control bar
- Bigger local preview (160x200)
- Show all buttons
- More spacing between elements

### Landscape Orientation

```
┌──────────────────────────────────────────────┐
│  [Local]  [Remote Video]                     │
│  [Prev]                                      │
│                                              │
│  🎤  🔊  📹   🔴   ⏸   ⋮                     │
└──────────────────────────────────────────────┘
```

- Controls on right or bottom
- Local preview in corner
- Maintain button sizes

## Related Documents

- **SDD**: flows/sdd-endpoint/ - Technical API for video components
- **ADR-005**: flows/adr-005-video-components/ - Native component architecture
- **Examples**: examples/App.js - Reference implementation

---

*Status: DRAFT | Type: VDD | Generated by /legacy*
