# 0_utilities Repository Reorganization Proposal

**Date**: November 26, 2025
**Status**: Awaiting Approval
**Impact Level**: Medium-High (structural changes, path updates required)

---

## Executive Summary

The 0_utilities repository contains 1,927 files across 6.3GB, with active development on 641 files in the last 30 days. The repository currently has organizational issues that make it difficult to locate files, understand relationships between components, and maintain consistent structure.

**Primary Issues Identified**:
1. Multiple overlapping terraform hierarchies (3 locations)
2. Extracted websites (500MB+) mixed with scripts
3. Documentation scattered across 12 locations
4. Scripts at 5 different hierarchy levels
5. Legacy/deprecated code not clearly marked

**Proposed Solution**: Restructure into 8 clear categories with consolidated locations for each type of asset.

---

## Current vs. Proposed Structure

### Current Structure (Simplified)
```
0_utilities/
├── terraform/modules/                  # Root terraform
├── website_extractor/
│   ├── terraform/                      # Legacy terraform
│   ├── terraform-sit/                  # Legacy SIT terraform
│   ├── cloudfront-prod-setup/          # Setup scripts
│   ├── cloudfront-sit-setup/           # Setup scripts
│   ├── cloudfront-optimize/            # Optimization scripts
│   ├── lambda-basic-auth/              # Lambda auth
│   └── website-migrator/
│       ├── scripts/
│       │   ├── bigbeard/ (223MB)      # Extracted site
│       │   ├── euroconcepts/ (118MB)  # Extracted site
│       │   ├── *.py                    # Python scripts
│       │   └── *.sh                    # Shell scripts
│       ├── terraform/environments/     # Active terraform
│       ├── domain-update/             # Domain scripts
│       ├── comprehensive_testing/      # Testing toolkit
│       ├── lambda/                     # Lambda functions
│       └── *.md                        # Documentation
├── *.sh                                # Root scripts
└── *.md                                # Root docs
```

### Proposed Structure
```
0_utilities/
├── README.md                           # Repository overview
├── docs/                               # ALL DOCUMENTATION
│   ├── migration/                      # Migration guides
│   ├── performance/                    # Performance docs
│   ├── terraform/                      # Infrastructure docs
│   └── testing/                        # Testing guides
│
├── scripts/                            # ALL SCRIPTS
│   ├── extraction/                     # Website extraction
│   ├── cloudfront/                     # CloudFront ops
│   ├── domain/                         # DNS management
│   ├── security/                       # Security ops
│   └── deployment/                     # Deployment automation
│
├── terraform/                          # UNIFIED TERRAFORM
│   ├── modules/                        # Reusable modules
│   └── environments/                   # Environment configs
│       ├── dev/
│       ├── sit/
│       └── prod/
│
├── lambda/                             # LAMBDA FUNCTIONS
│   ├── basic-auth/
│   └── form-handler/
│
├── config/                             # CONFIGURATION FILES
│   └── cloudfront/                     # 44 CloudFront configs
│
├── testing/                            # UNIFIED TESTING
│   ├── performance/
│   ├── monitoring/
│   └── results/
│
├── artifacts/ (git-ignored)            # DEPLOYMENT ARTIFACTS
│   ├── extracted-sites/                # Extracted websites
│   ├── archives/                       # Site archives
│   └── deployments/                    # Deployment packages
│
├── logs/ (git-ignored)                 # CENTRALIZED LOGS
│   ├── extraction/
│   ├── terraform/
│   └── archive/
│
└── archive/                            # DEPRECATED CODE
    ├── legacy-terraform/
    ├── old-scripts/
    └── docx-extraction/
```

---

## Detailed File Movements

### 1. Documentation Consolidation → `docs/`

#### docs/migration/
- ← website-migrator/MIGRATION_RUNBOOK.md
- ← website-migrator/scripts/MIGRATION_WORKFLOW.md
- ← website-migrator/scripts/Run-Migration.md
- ← website_extractor/Prod_Ready_Migrator.md
- ← website_extractor/Testing_Runbook.md

#### docs/performance/
- ← CLOUDFRONT_ANALYSIS_REPORT.md (root)
- ← website-migrator/CLOUDFRONT_OPTIMIZATION.md
- ← website-migrator/ORIGIN_SHIELD_AUDIT_REPORT.md
- ← website-migrator/JEANIQUE_PERFORMANCE_FIX.md

#### docs/terraform/
- ← terraform/environments/prod/BACKEND_SETUP_GUIDE.md
- ← terraform/environments/prod/TERRAFORM_SETUP_FEEDBACK.md
- ← terraform/environments/prod/UPDATE_SCRIPT_README.md

#### docs/testing/
- ← comprehensive_testing/TOOLKIT_OVERVIEW.md
- ← comprehensive_testing/USAGE_GUIDE.md
- ← comprehensive_testing/QUICKSTART.md
- ← comprehensive_testing/README.md

### 2. Script Organization → `scripts/`

#### scripts/extraction/
- ← website-migrator/scripts/website_extractor_ultimate.py
- ← website-migrator/scripts/website_extractor_v4_css_fix_1.py
- ← website-migrator/scripts/extraction_validator.py
- ← website-migrator/scripts/extractor_fix.py
- ← website-migrator/scripts/fix_paths.py

#### scripts/cloudfront/
- ← website-migrator/scripts/warm_cloudfront_cache.sh
- ← website-migrator/scripts/diagnose_cloudfront_access.sh
- ← website-migrator/scripts/fix_cloudfront_access.sh
- ← cloudfront-optimize/* (entire directory)

#### scripts/domain/
- ← domain-update/invalidate_site_cache.sh
- ← domain-update/invalidate_all_cache.sh
- ← domain-update/check_invalidation_status.sh
- ← domain-update/add_all_cloudfront_aliases.sh
- ← domain-update/backup_dns_records.sh
- ← domain-update/check_dns_status.sh
- ← domain-update/verify_all_aliases.sh
- ← domain-update/request_acm_certificates.sh
- ← domain-update/* (all 19 scripts)

#### scripts/security/
- ← security_hub.sh (root)
- ← update_source_bucket_policy.sh (root)

#### scripts/deployment/
- ← website-migrator/scripts/deploy-site.sh
- ← website-migrator/scripts/deploy-environment.sh
- ← website-migrator/scripts/apply_form_interception.sh
- ← website-migrator/scripts/bootstrap-dev.sh
- ← website-migrator/scripts/bootstrap-environment.sh
- ← promote_s3_prefixes.sh (root)

### 3. Terraform Consolidation → `terraform/`

#### Keep in Place (already correct):
- terraform/environments/dev/
- terraform/environments/sit/
- terraform/environments/prod/
- terraform/modules/cloudfront-site/
- terraform/modules/s3-bucket/
- terraform/modules/iam/
- terraform/modules/lambda/

#### Archive (deprecated):
- website_extractor/terraform/ → archive/legacy-terraform/
- website_extractor/terraform-sit/ → archive/legacy-terraform-sit/
- terraform/modules/cloudfront-site/ (root) → consolidated into main terraform/

### 4. Lambda Functions → `lambda/`

#### lambda/basic-auth/
- ← website_extractor/lambda-basic-auth/*
- Structure: src/, deploy.sh, README.md, trust-policy.json

#### lambda/form-handler/
- ← website-migrator/lambda/index.py
- New structure

### 5. Configuration Files → `config/`

#### config/cloudfront/
- ← CloudFront Configurations/*.json (44 files)
- ← cloudfront-prod-setup/configs-af-south-1/*.json
- ← cloudfront-prod-setup/configs-eu-west-1/*.json
- ← cloudfront-sit-setup/cloudfront-configs/*.json

**Note**: Will need to deduplicate and determine which configs are active

### 6. Testing Consolidation → `testing/`

#### testing/performance/
- ← comprehensive_testing/enhanced-cf-performance-test.sh
- ← comprehensive_testing/analyze-performance.sh
- ← comprehensive_testing/compare-optimization.sh
- ← website_extractor/testing/prod-test-suite.sh

#### testing/monitoring/
- ← comprehensive_testing/monitor-cloudfront.sh
- ← comprehensive_testing/generate-dashboard.sh

#### testing/setup
- ← comprehensive_testing/setup-toolkit.sh

### 7. Deployment Artifacts → `artifacts/` (git-ignored)

#### artifacts/extracted-sites/
- ← scripts/bigbeard/ (223MB)
- ← scripts/euroconcepts/ (118MB)
- ← scripts/bullocksbeans/ (17MB)
- ← scripts/manufacturing-websites/ (9.5MB)

#### artifacts/archives/
- ← scripts/bigbeard.zip (181MB)

#### artifacts/deployments/
- New directory for deployment packages

### 8. Centralized Logs → `logs/` (git-ignored)

#### logs/extraction/
- ← scripts/website_extractor.log
- ← scripts/output.json

#### logs/terraform/
- ← terraform/environments/prod/*.log (4 files)

#### logs/archive/
- Archive old logs by month

### 9. Archive Deprecated Code → `archive/`

#### archive/legacy-terraform/
- ← website_extractor/terraform/
- ← website_extractor/terraform-sit/

#### archive/docx-extraction/
- ← website_extractor/docx/

#### archive/old-setups/
- ← cloudfront-prod-setup/ (consolidate configs into config/, archive scripts)
- ← cloudfront-sit-setup/ (consolidate configs into config/, archive scripts)

---

## Path Updates Required

The following files reference paths that will change and need updates:

### Documentation Files
- [ ] MIGRATION_RUNBOOK.md - references to scripts paths
- [ ] MIGRATION_WORKFLOW.md - script paths
- [ ] Run-Migration.md - script paths
- [ ] CLOUDFRONT_OPTIMIZATION.md - terraform paths
- [ ] Testing docs - script paths

### Terraform Files
- [ ] environments/*/main.tf - module source paths
- [ ] GitHub Actions workflows - script paths

### Shell Scripts
- [ ] Scripts that source other scripts
- [ ] Scripts with hardcoded paths

### .gitignore
- [ ] Update patterns for new artifacts/ and logs/ directories
- [ ] Remove old patterns for deprecated locations

---

## Migration Plan

### Phase 1: Documentation (Low Risk) - 30 minutes
**Steps**:
1. Create `docs/` directory structure
2. Move all .md files to appropriate subdirectories
3. Update cross-references in documentation
4. Create master docs/README.md

**Risk**: Low - documentation moves don't break functionality
**Validation**: Manual review of moved files, check links

### Phase 2: Archive Deprecated (Low Risk) - 15 minutes
**Steps**:
1. Create `archive/` directory
2. Move legacy terraform directories
3. Move docx/ directory
4. Add archive/README.md explaining contents

**Risk**: Low - moving already-unused code
**Validation**: Verify terraform modules don't reference old paths

### Phase 3: Create Git-Ignored Directories (Zero Risk) - 5 minutes
**Steps**:
1. Create `artifacts/` with subdirectories
2. Create `logs/` with subdirectories
3. Update .gitignore

**Risk**: Zero - creating new empty directories
**Validation**: Verify .gitignore patterns work

### Phase 4: Scripts Organization (Medium Risk) - 1 hour
**Steps**:
1. Create `scripts/` subdirectories
2. Move scripts to new locations
3. Update script internal paths (grep for hardcoded paths)
4. Test script execution from new locations

**Risk**: Medium - scripts may have hardcoded paths
**Validation**: Run key scripts in test mode, verify they execute

### Phase 5: Configuration Consolidation (Low Risk) - 30 minutes
**Steps**:
1. Create `config/cloudfront/`
2. Move CloudFront JSON configs
3. Deduplicate (compare prod-af-south-1, prod-eu-west-1, sit configs)
4. Update scripts that reference configs

**Risk**: Low - configs are data files
**Validation**: Verify JSON syntax, compare file counts

### Phase 6: Artifacts Movement (Medium Risk) - 1 hour
**Steps**:
1. Move extracted sites to artifacts/extracted-sites/
2. Move archives to artifacts/archives/
3. Update extraction scripts to output to new location
4. Update .gitignore patterns

**Risk**: Medium - extracted sites are large, scripts reference them
**Validation**: Verify extracted sites integrity, test extraction script

### Phase 7: Testing Consolidation (Low-Medium Risk) - 30 minutes
**Steps**:
1. Create `testing/` structure
2. Move testing files
3. Merge comprehensive_testing/ and testing/
4. Update script paths

**Risk**: Low-Medium - testing doesn't affect production
**Validation**: Run test suite to verify it works

### Phase 8: Lambda Organization (Medium Risk) - 45 minutes
**Steps**:
1. Create `lambda/` structure
2. Move Lambda functions
3. Update terraform module paths
4. Test terraform plan

**Risk**: Medium - affects infrastructure deployment
**Validation**: Terraform plan, verify Lambda deployment packages

### Phase 9: Logs Consolidation (Low Risk) - 15 minutes
**Steps**:
1. Move existing logs to logs/
2. Update scripts to write to new location
3. Archive old logs

**Risk**: Low - logs are output only
**Validation**: Verify log paths in scripts

### Phase 10: Final Cleanup (Zero Risk) - 15 minutes
**Steps**:
1. Remove .DS_Store files
2. Clean up empty directories
3. Verify .gitignore
4. Create root README.md
5. Create MIGRATION_SUMMARY.md

**Risk**: Zero - cleanup only
**Validation**: Visual inspection, git status check

---

## File Deletion Candidates (Require Approval)

### Safe to Delete (Pending Confirmation)
1. **Old Log Files** (archive instead):
   - terraform/environments/prod/optimize_lambda_edge_*.log (41K)
   - terraform/environments/prod/disable_basic_auth_*.log (multiple, <10K each)
   - terraform/environments/prod/origin_shield_fix_live.log (1K)

2. **Large Security Hub Report** (archive externally):
   - security_hub.md (6.4MB) - very large, likely superseded

3. **System Files**:
   - All .DS_Store files (7 files) - auto-generated by macOS

4. **Duplicate Python Scripts** (keep latest only):
   - website_extractor_v4_css_fix_1.py (variant, if ultimate.py includes fixes)
   - extractor_fix.py (older version)
   - **Action**: Need to verify which is current

5. **Old CloudFront Setup Directories** (after config consolidation):
   - cloudfront-prod-setup/scripts (keep configs, archive scripts)
   - cloudfront-sit-setup/scripts (keep configs, archive scripts)

### DO NOT Delete (Keep After Move)
1. Extracted website directories (move to artifacts/)
2. Site archives .zip files (move to artifacts/)
3. Any terraform .tfstate files
4. Active Python/shell scripts
5. Documentation files
6. CloudFront configuration JSONs

---

## Questions for Approval

### Q1: Terraform Module Consolidation
**Question**: The root `terraform/modules/cloudfront-site/` appears to be a duplicate of `website_extractor/website-migrator/terraform/modules/cloudfront-site/`. Should we:
- A) Keep only the website-migrator version (active)
- B) Keep both and clarify usage
- C) Consolidate into unified terraform/modules/

**Recommendation**: Option C - consolidate into unified terraform/modules/

### Q2: CloudFront Config Deduplication
**Question**: There are CloudFront configs in 4 locations:
- CloudFront Configurations/ (44 files)
- cloudfront-prod-setup/configs-af-south-1/ (46 files)
- cloudfront-prod-setup/configs-eu-west-1/ (46 files)
- cloudfront-sit-setup/cloudfront-configs/ (45 files)

Should we:
- A) Keep all (181 total files) in separate directories by environment
- B) Consolidate to config/cloudfront/{dev,sit,prod-af,prod-eu}/
- C) Keep only latest/active and archive old

**Recommendation**: Option B - organize by environment

### Q3: Extracted Website Storage
**Question**: Extracted websites (bigbeard 223MB, euroconcepts 118MB, etc.) are currently in scripts/. Should we:
- A) Move to artifacts/ and exclude from git (preferred)
- B) Keep in separate repository
- C) Delete after deployment and re-extract when needed

**Recommendation**: Option A - move to artifacts/ (already git-ignored)

### Q4: Old Python Script Versions
**Question**: There are 3 extraction scripts:
- website_extractor_ultimate.py (40K, Nov 25) - latest
- website_extractor_v4_css_fix_1.py (34K, Nov 20) - variant
- extractor_fix.py (51K, Nov 18) - older

Should we:
- A) Keep all for reference
- B) Keep only ultimate.py and archive others
- C) Consolidate fixes into ultimate.py and delete others

**Recommendation**: Option B - keep ultimate.py active, archive others

### Q5: Legacy Terraform Directories
**Question**: Legacy terraform in website_extractor/terraform/ and terraform-sit/. Should we:
- A) Delete completely
- B) Archive in archive/legacy-terraform/
- C) Keep for historical reference

**Recommendation**: Option B - archive, don't delete (safe keeping)

### Q6: security_hub.md (6.4MB)
**Question**: This file is very large (6.4MB). Should we:
- A) Archive externally and delete from repo
- B) Move to logs/archive/
- C) Keep in archive/

**Recommendation**: Option B - move to logs/archive/

---

## Rollback Plan

If reorganization causes issues:

1. **Git Revert**: All changes tracked in git, can revert
2. **Backup**: Create backup of entire repository before starting
3. **Staged Approach**: Each phase can be rolled back independently
4. **Path Mapping Document**: Maintain OLD_PATH → NEW_PATH mapping

---

## Success Criteria

- [ ] All documentation in docs/ with clear structure
- [ ] All scripts in scripts/ organized by function
- [ ] Single terraform hierarchy at terraform/
- [ ] Large artifacts excluded from git in artifacts/
- [ ] Logs centralized in logs/
- [ ] All deprecated code clearly marked in archive/
- [ ] No broken paths in scripts or documentation
- [ ] All terraform plans succeed
- [ ] All critical scripts execute successfully
- [ ] Repository size reduced (git history cleaned of moved large files)

---

## Timeline Estimate

| Phase | Duration | Risk | Can Run in Parallel |
|-------|----------|------|---------------------|
| 1. Documentation | 30 min | Low | Yes |
| 2. Archive Deprecated | 15 min | Low | Yes |
| 3. Git-Ignored Dirs | 5 min | Zero | Yes |
| 4. Scripts Organization | 1 hour | Medium | No |
| 5. Config Consolidation | 30 min | Low | Yes (with 4) |
| 6. Artifacts Movement | 1 hour | Medium | No |
| 7. Testing Consolidation | 30 min | Low-Medium | Yes (with 6) |
| 8. Lambda Organization | 45 min | Medium | No |
| 9. Logs Consolidation | 15 min | Low | Yes |
| 10. Final Cleanup | 15 min | Zero | Yes |

**Total Sequential Time**: ~3-4 hours
**Total with Parallelization**: ~2-3 hours

---

## Next Steps

**Awaiting Your Approval On**:
1. Overall proposed structure - approve/modify?
2. Answers to Q1-Q6 above
3. Permission to proceed with Phase 1-3 (low risk)
4. Permission to delete .DS_Store files
5. Permission to archive old logs

**Once Approved, I Will**:
1. Create backup of repository
2. Execute reorganization in phases
3. Update all path references
4. Test critical functionality
5. Generate MIGRATION_SUMMARY.md with complete change log
6. Create updated root README.md

---

**Review this proposal and let me know**:
- ✅ Approve as-is and proceed
- 🔄 Approve with modifications (specify changes)
- ❌ Reject and keep current structure
- ❓ Questions/concerns about specific aspects
