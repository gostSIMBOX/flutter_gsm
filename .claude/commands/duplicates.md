# Duplicates Detection and Merge Flow

## Command: /duplicates

Analyzes all SDD/DDD/TDD/VDD/ADR flows to find duplicates, merges content, and archives less informative duplicates.

## Usage

```bash
/duplicates                    # Full scan and merge
/duplicates scan               # Scan only, report duplicates
/duplicates merge [name]       # Merge specific duplicate pair
/duplicates status             # Show duplicates folder status
```

## Initialization

**Before any execution**, check if `flows/duplicates/` exists:

```
IF flows/duplicates/ does NOT exist:
  1. Copy flows/.templates/duplicates/ → flows/duplicates/
  2. Create MERGED_TEMPLATE.md if missing
  3. Create README.md if missing
  4. Create .gitkeep if missing
  5. Inform user: "Initialized duplicates archive from templates"
  6. Continue with execution
```

## Algorithm

### Step 1: Scan for Potential Duplicates

**Similarity Detection:**

1. **Name-based matching:**
   - Similar directory names (e.g., `sdd-call` vs `sdd-calls`)
   - Similar file names within directories

2. **Content-based matching:**
   - Compare requirements/specifications using text similarity
   - Check for overlapping functional requirements
   - Identify duplicate interfaces/types

3. **Purpose-based matching:**
   - Compare overview sections
   - Check for same business problem being solved

**Similarity Score Calculation:**
```
score = (name_similarity * 0.3) + 
        (content_similarity * 0.5) + 
        (purpose_similarity * 0.2)

If score > 0.7: Mark as potential duplicate
```

### Step 2: Analyze Duplicate Pairs

For each potential duplicate pair:

1. **Compare completeness:**
   - Count requirements in each
   - Count specifications in each
   - Check for implementation logs
   - Compare section coverage

2. **Identify unique content:**
   - Requirements only in A
   - Requirements only in B
   - Specifications only in A
   - Specifications only in B
   - Unique sections in each

3. **Determine primary:**
   - More requirements → primary
   - More specifications → primary
   - More recent updates → primary
   - More complete sections → primary

### Step 3: Merge Content

**Before moving duplicate:**

1. **Extract unique content from duplicate:**
   ```bash
   # For each section in duplicate
   - If section doesn't exist in primary → copy entire section
   - If section exists but has unique subsections → merge subsections
   - If section has unique requirements/specs → add to primary
   ```

2. **Update primary with merged content:**
   ```markdown
   ## Merged from [duplicate-name]
   
   [Unique content from duplicate]
   ```

3. **Add merge log to primary:**
   ```markdown
   ## Merge History
   
   | Date | Source | Content Merged |
   |------|--------|----------------|
   | 2026-03-04 | sdd-call-old | Requirements FR-5 to FR-8, Specifications section 3.2 |
   ```

### Step 4: Archive Duplicate

**Create duplicate record:**

1. **Move directory to `flows/duplicates/`:**
   ```bash
   mv flows/sdd-call-old/ flows/duplicates/sdd-call-old/
   ```

2. **Create `MERGED.md` in duplicate directory:**
   ```markdown
   # Merged into [primary-name]
   
   **Date**: 2026-03-04
   **Merged by**: /duplicates command
   
   **Content transferred:**
   - Requirements: FR-5, FR-6, FR-7, FR-8
   - Specifications: Section 3.2, Appendix A
   - Other: [list unique content]
   
   **Primary location**: `flows/sdd-call/`
   
   **Reason for merge**: Duplicate functionality, primary has more complete coverage
   
   ---
   *This directory is archived. Refer to primary for current specification.*
   ```

3. **Update status files:**
   - Mark duplicate `_status.md` as MERGED
   - Update primary `_status.md` with merge note

### Step 5: Update Indexes

**Update relevant index files:**

1. **SDD index** (if SDD flow): Remove duplicate entry
2. **DDD index** (if DDD flow): Remove duplicate entry
3. **TDD index** (if TDD flow): Remove duplicate entry
4. **VDD index** (if VDD flow): Remove duplicate entry
5. **Waterfall status**: Update compiled status if affected

---

## Duplicate Detection Rules

### High Confidence (>0.8)

- Same functional requirements with >80% text similarity
- Same interface definitions
- Same business problem in overview

### Medium Confidence (0.5-0.8)

- Overlapping but not identical requirements
- Similar but scoped differently
- One is subset of another

### Low Confidence (<0.5)

- Similar names but different purposes
- Shared concepts but different implementations
- **Do not auto-merge, flag for manual review**

---

## Merge Safety Checks

**Before merging, verify:**

1. ✅ All unique requirements identified
2. ✅ All unique specifications identified
3. ✅ No orphaned references (check other flows)
4. ✅ Implementation logs preserved or merged
5. ✅ Related ADRs updated if needed

**Block merge if:**

- ❌ Duplicate has approved implementation in progress
- ❌ Duplicate is referenced by approved ADR
- ❌ Content conflict cannot be auto-resolved
- ❌ User has pending changes in either flow

---

## Output Format

### Scan Results

```
Duplicates Scan Results
=======================

Found 3 potential duplicate pairs:

1. sdd-call vs sdd-calls (confidence: 0.85)
   Primary candidate: sdd-call (more complete)
   Unique in sdd-calls: FR-7, FR-8, Specifications 4.1
   Action: Merge recommended

2. ddd-voip vs sdd-voip-calling (confidence: 0.72)
   Primary candidate: sdd-voip-calling (more recent)
   Unique in ddd-voip: Stakeholder requirements SR-9
   Action: Merge recommended

3. tdd-testing vs tdd-tests (confidence: 0.45)
   Different scope - manual review recommended
   Action: Flag for review
```

### Merge Results

```
Merge Complete
==============

Merged: sdd-calls → sdd-call

Content transferred:
  ✅ Requirements: FR-7, FR-8
  ✅ Specifications: Section 4.1 (Video call handling)
  ✅ Implementation notes: Testing considerations

Archived to: flows/duplicates/sdd-calls/
Merge record: flows/duplicates/sdd-calls/MERGED.md

Primary updated: flows/sdd-call/
  - Added 2 requirements
  - Added 1 specification section
  - Updated merge history

Indexes updated:
  ✅ flows/sdd.md
  ✅ flows/waterfall/_status.md
```

---

## Files Modified

| File | Purpose |
|------|---------|
| `flows/duplicates/[name]/` | Archived duplicate |
| `flows/duplicates/[name]/MERGED.md` | Merge record |
| `flows/[primary]/04-implementation-log.md` | Merge history |
| `flows/[type].md` | Index updates |
| `flows/waterfall/_status.md` | Status sync |

---

## Rollback Procedure

If merge needs to be undone:

1. **Restore from duplicates:**
   ```bash
   mv flows/duplicates/[name]/ flows/[name]/
   ```

2. **Revert primary changes:**
   - Check git history for merged content
   - Remove merged sections
   - Restore original state

3. **Update indexes:**
   - Re-add duplicate to indexes
   - Remove merge history from primary

---

## Best Practices

### Do
- Always verify unique content before merging
- Preserve all requirements and specifications
- Document what was merged and why
- Keep duplicate directory with MERGED.md record
- Update all relevant indexes

### Don't
- Merge without checking for unique content
- Delete duplicate without creating MERGED.md
- Merge flows with different statuses (one approved, one draft)
- Merge ADRs that are already APPROVED
- Forget to update waterfall status

---

## Edge Cases

### Multiple Duplicates

If 3+ flows are duplicates:
1. Select most complete as primary
2. Merge all others into primary
3. Archive all duplicates
4. Create single MERGED.md for each

### Circular References

If flows reference each other:
1. Update all references to point to primary
2. Document reference changes in MERGED.md

### Partial Overlap

If flows overlap 50% but have unique content:
1. Consider keeping both with clear scope documentation
2. Or merge and clearly mark merged sections
3. Add "Scope" section clarifying what each covers

---

*Created: 2026-03-04*
*Version: 1.0*
