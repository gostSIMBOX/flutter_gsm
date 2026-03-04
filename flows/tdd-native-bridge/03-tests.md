# Test Cases: Native Bridge Module Testing

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-03-04
> Requirements: [01-requirements.md](01-requirements.md)

## Overview

Test cases for native bridge module bugs and fixes. Tests are written in Given/When/Then format before implementation (TDD).

---

## Test: Module Name Resolution

**ID**: T001
**Requirement**: Must Have #3
**Type**: Functional

### Scenario

**Given**: React Native bridge is initialized
**When**: JavaScript accesses `NativeModules.ForegroundBackground`
**Then**: Module is found and methods are callable

### Examples

| Module Name Used | Expected Module Name | Result |
|-----------------|---------------------|--------|
| ForegroundBackground | ForegroundBackgroundModule | Found ✓ |
| ReplaceDialerModule | ForegroundBackgroundModule | Not Found ✗ (BUG) |

### Fix Required

Update JavaScript to use correct module name:
```javascript
// BEFORE (BUG)
NativeModules.ReplaceDialerModule.toBackground()

// AFTER (FIX)
NativeModules.ForegroundBackground.toBackground()
```

---

## Test: toForeground Execution

**ID**: T002
**Requirement**: Must Have #1
**Type**: Functional

### Scenario

**Given**: App is in background or suspended
**When**: `toForeground()` is called
**Then**: App launches to foreground with screen awake

### Steps

1. App is in background
2. Call `ForegroundBackground.toForeground()`
3. Verify WakeLock.acquire() called with timeout
4. Verify MainActivity launched with flags:
   - FLAG_ACTIVITY_NEW_TASK
   - CATEGORY_LAUNCHER
5. Verify screen is awake

### Examples

| Device State | Expected Result |
|--------------|-----------------|
| Screen off, app backgrounded | Screen on, app foreground |
| Screen on, app backgrounded | App foreground |
| App already foreground | No error (idempotent) |

---

## Test: toBackground Execution

**ID**: T003
**Requirement**: Must Have #2
**Type**: Functional

### Scenario

**Given**: App is in foreground
**When**: `toBackground()` is called
**Then**: App moves to background without errors

### Steps

1. App is in foreground
2. Call `ForegroundBackground.toBackground()`
3. Verify `moveTaskToBack(true)` called
4. Verify app is in background

### Examples

| App State | Expected Result |
|-----------|-----------------|
| Foreground, screen on | Background, screen unchanged |
| Foreground, WakeLock held | Background, WakeLock released |

---

## Test: Error Handling - Class Not Found

**ID**: E001
**Requirement**: Must Have #4
**Type**: Error

### Scenario

**Given**: MainActivity class cannot be found
**When**: `toForeground()` is called
**Then**: Error is logged, no crash

### Steps

1. Mock Class.forName() to throw ClassNotFoundException
2. Call `toForeground()`
3. Verify error logged: "Failed to open application"
4. Verify no exception propagates to JavaScript

---

## Test: Error Handling - Activity Launch Failure

**ID**: E002
**Requirement**: Must Have #4
**Type**: Error

### Scenario

**Given**: startActivity() throws exception
**When**: `toForeground()` is called
**Then**: Error is caught and logged

### Steps

1. Mock mContext.startActivity() to throw exception
2. Call `toForeground()`
3. Verify warning logged
4. Verify WakeLock still acquired (fallback behavior)

---

## Test: WakeLock Timeout

**ID**: T004
**Requirement**: Should Have
**Type**: Edge Case

### Scenario

**Given**: toForeground() is called
**When**: Operation takes longer than 10 seconds
**Then**: WakeLock releases automatically

### Steps

1. Call `toForeground()`
2. Wait 10+ seconds
3. Verify WakeLock is released

---

## Integration Flow: Foreground-Background Cycle

End-to-end test across full transition cycle:

```
[Background] --> [toForeground()] --> [Foreground] --> [toBackground()] --> [Background]
```

### Scenario

**ID**: I001
**Requirement**: Must Have #1, #2

**Given**: App starts in background
**When**: User calls toForeground(), then toBackground()
**Then**: App returns to background state

### Steps

1. Start with app in background
2. Call `toForeground()`
3. Verify app is in foreground
4. Call `toBackground()`
5. Verify app is in background
6. Verify no errors or exceptions
7. Verify WakeLock released

---

## Test: Multiple Rapid Calls

**ID**: T005
**Requirement**: Should Have
**Type**: Edge Case

### Scenario

**Given**: User rapidly calls toForeground() multiple times
**When**: 5+ calls made within 1 second
**Then**: No crashes, no duplicate activity launches

### Steps

1. Call `toForeground()` 5 times rapidly
2. Verify only one MainActivity launched
3. Verify no exceptions

---

## Test Coverage Matrix

| Requirement ID | Test IDs | Status |
|----------------|----------|--------|
| Must Have #1 | T002, I001 | Covered |
| Must Have #2 | T003, I001 | Covered |
| Must Have #3 | T001 | Covered |
| Must Have #4 | E001, E002 | Covered |
| Should Have | T004, T005 | Covered |

---

## Notes

- Tests should be written **before** fixing bugs (TDD)
- Java tests require Mockito/PowerMock for Android API mocking
- JavaScript tests can use Jest with react-native mock
- Integration tests require physical device or emulator

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
