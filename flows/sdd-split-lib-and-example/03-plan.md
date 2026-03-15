# Implementation Plan: Split Library and Example

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-03-15
> Estimated Effort: 3-4 hours

## Task Breakdown

### Phase 1: Create Flutter Plugin Structure (30 minutes)

#### Task 1.1: Create flutter_gsmsip Plugin
```bash
flutter create --template=plugin --platforms=android --org=org.telon flutter_gsmsip
```
- **Output**: `flutter_gsmsip/` directory with plugin structure
- **Verification**: `flutter pub get` succeeds

#### Task 1.2: Update Library pubspec.yaml
- **File**: `flutter_gsmsip/pubspec.yaml`
- **Changes**:
  - Add `dartz`, `equatable`, `logger` dependencies
  - Update description
- **Verification**: `flutter pub get` succeeds

---

### Phase 2: Move Native Kotlin Code (45 minutes)

#### Task 2.1: Copy Kotlin SIP Code
- **Source**: `android/app/src/main/kotlin/.../sip/`
- **Destination**: `flutter_gsmsip/android/src/main/kotlin/org/telon/flutter_gsmsip/sip/`
- **Verification**: Files copied

#### Task 2.2: Copy Kotlin GSM Code
- **Source**: `android/app/src/main/kotlin/.../gsm/`
- **Destination**: `flutter_gsmsip/android/src/main/kotlin/org/telon/flutter_gsmsip/gsm/`
- **Verification**: Files copied

#### Task 2.3: Copy Kotlin SMPP Code
- **Source**: `android/app/src/main/kotlin/.../smpp/`
- **Destination**: `flutter_gsmsip/android/src/main/kotlin/org/telon/flutter_gsmsip/smpp/`
- **Verification**: Files copied

#### Task 2.4: Update Plugin Entry Point
- **File**: `flutter_gsmsip/android/src/main/kotlin/org/telon/flutter_gsmsip/FlutterGsmSipPlugin.kt`
- **Changes**: Integrate existing native code with plugin structure
- **Verification**: Kotlin compiles

#### Task 2.5: Update Android Build Config
- **File**: `flutter_gsmsip/android/build.gradle`
- **Changes**: Add PJSIP dependencies, configure native libs
- **Verification**: Gradle sync succeeds

---

### Phase 3: Move Dart Library Code (45 minutes)

#### Task 3.1: Copy Domain Layer
- **Source**: `lib/domain/`
- **Destination**: `flutter_gsmsip/lib/src/domain/`
- **Verification**: All entities, repositories, use cases copied

#### Task 3.2: Copy Data Layer
- **Source**: `lib/data/repositories/`, `lib/data/services/`
- **Destination**: `flutter_gsmsip/lib/src/data/`
- **Verification**: All repositories and services copied

#### Task 3.3: Copy Core Services
- **Source**: `lib/services/sms_service.dart`, `smpp_service.dart`, `telephony_service.dart`
- **Destination**: `flutter_gsmsip/lib/src/data/services/`
- **Verification**: Services copied

#### Task 3.4: Update Imports in Library Code
- **Files**: All files in `flutter_gsmsip/lib/src/`
- **Changes**: Fix import paths to use relative imports within library
- **Verification**: No import errors

#### Task 3.5: Create Main Export File
- **File**: `flutter_gsmsip/lib/flutter_gsmsip.dart`
- **Content**: Export all public API classes
- **Verification**: Exports resolve correctly

---

### Phase 4: Create Example App (60 minutes)

#### Task 4.1: Copy Presentation Layer
- **Source**: `lib/presentation/`, `lib/screens/`, `lib/widgets/`
- **Destination**: `flutter_gsmsip/example/lib/`
- **Verification**: UI code copied

#### Task 4.2: Copy App Services
- **Source**: `lib/services/theme_service.dart`, `storage_service.dart`, etc.
- **Destination**: `flutter_gsmsip/example/lib/services/`
- **Verification**: Services copied

#### Task 4.3: Copy Dependency Injection
- **Source**: `lib/core/di/`
- **Destination**: `flutter_gsmsip/example/lib/core/di/`
- **Changes**: Update to use library classes
- **Verification**: DI config updated

#### Task 4.4: Copy Main Entry Point
- **Source**: `lib/main.dart`
- **Destination**: `flutter_gsmsip/example/lib/main.dart`
- **Verification**: App entry copied

#### Task 4.5: Update Example pubspec.yaml
- **File**: `flutter_gsmsip/example/pubspec.yaml`
- **Changes**:
  - Add `flutter_gsmsip` dependency (path: ../)
  - Keep app-specific dependencies
- **Verification**: `flutter pub get` succeeds

#### Task 4.6: Copy Android App Config
- **Source**: `android/app/build.gradle`, `AndroidManifest.xml`
- **Destination**: `flutter_gsmsip/example/android/app/`
- **Verification**: Android config copied

---

### Phase 5: Fix Integration Issues (45 minutes)

#### Task 5.1: Fix Library Imports
- **Action**: Run `flutter analyze` on library
- **Fix**: Resolve all import errors
- **Verification**: No errors in `flutter_gsmsip/`

#### Task 5.2: Fix Example Imports
- **Action**: Run `flutter analyze` on example
- **Fix**: Update imports to use library API
- **Verification**: No errors in `flutter_gsmsip/example/`

#### Task 5.3: Fix Method Channel Names
- **Action**: Ensure method channel names match between Dart and Kotlin
- **Verification**: Channels registered correctly

#### Task 5.4: Test Library Build
```bash
cd flutter_gsmsip && flutter build apk --debug
```
- **Verification**: Build succeeds

#### Task 5.5: Test Example App
```bash
cd flutter_gsmsip/example && flutter run
```
- **Verification**: App launches on device

---

### Phase 6: Cleanup and Documentation (30 minutes)

#### Task 6.1: Add Library Documentation
- **File**: `flutter_gsmsip/README.md`
- **Content**: Usage examples, API documentation
- **Verification**: README complete

#### Task 6.2: Add Example App Documentation
- **File**: `flutter_gsmsip/example/README.md`
- **Content**: How to run example
- **Verification**: README complete

#### Task 6.3: Cleanup Original Project
- **Action**: Optionally remove original project or mark as deprecated
- **Verification**: Clean workspace

---

## File Structure After Migration

```
GOSTsimbox_androidgateway/
├── flutter_gsmsip/           # NEW: Library plugin
│   ├── lib/
│   │   ├── flutter_gsmsip.dart
│   │   └── src/
│   │       ├── domain/
│   │       ├── data/
│   │       └── gsm_sip_bridge.dart
│   ├── android/
│   │   └── src/main/kotlin/org/telon/flutter_gsmsip/
│   │       ├── FlutterGsmSipPlugin.kt
│   │       ├── sip/
│   │       ├── gsm/
│   │       └── smpp/
│   ├── example/
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── services/
│   │   └── android/
│   ├── pubspec.yaml
│   └── README.md
└── (original project - may be removed)
```

## Risk Assessment

### High Risk
- **PJSIP native library integration**: May require build config adjustments
  - **Mitigation**: Test early, keep backup of working config

### Medium Risk
- **Method channel naming**: Mismatch between Dart and Kotlin
  - **Mitigation**: Use consistent naming convention, test each channel

### Low Risk
- **Import path fixes**: Mechanical work
- **pubspec.yaml updates**: Straightforward

## Rollback Plan

If issues occur:
```bash
# Keep original project intact until verified
git stash  # Save changes
# Original project remains functional
```

## Success Criteria

- [ ] `flutter_gsmsip` plugin created with correct structure
- [ ] Native Kotlin code moved and compiles
- [ ] Dart library code moved and analyzes clean
- [ ] Example app builds and runs
- [ ] Library can be imported: `import 'package:flutter_gsmsip/flutter_gsmsip.dart';`
- [ ] Example app uses library via dependency
- [ ] No circular dependencies

---

## Approval

- [ ] Plan reviewed by: [name]
- [ ] Plan approved on: [date]
- [ ] Notes: [any conditions or concerns]
