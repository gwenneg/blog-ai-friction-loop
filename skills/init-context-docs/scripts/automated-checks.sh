#!/bin/bash
# Structural validation for init-context-docs generated files
set -eu

REPO_ROOT=${1:-.}
ERRORS=0

echo "Running automated validation checks..."
echo ""

check_exists() {
    local file=$1
    if [ -f "$file" ]; then
        echo "✅ $file: exists"
        return 0
    else
        echo "❌ $file: not found"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

check_size() {
    local file=$1
    local max=$2
    local lines
    lines=$(wc -l < "$file")
    if [ "$lines" -gt "$max" ]; then
        echo "❌ $file: $lines lines (max: $max)"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ $file: $lines lines (within limit)"
    fi
}

check_secrets() {
    local file=$1
    local matches
    # Require an assignment pattern (key = "value" or key: 'value' or key=longvalue) to avoid
    # false positives from documentation prose that merely mentions these words.
    matches=$(grep -iE "(api_key|password|secret|token|credential)\s*[:=]\s*(\"[^\"]{4,}\"|'[^']{4,}'|[A-Za-z0-9+/_-]{20,})" "$file" 2>/dev/null || true)
    if [ -n "$matches" ]; then
        echo "❌ $file: possible hardcoded secrets detected"
        echo "$matches"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ $file: no hardcoded secrets detected"
    fi
}

# AGENTS.md
echo "=== AGENTS.md ==="
if check_exists "$REPO_ROOT/AGENTS.md"; then
    check_size "$REPO_ROOT/AGENTS.md" 200
    check_secrets "$REPO_ROOT/AGENTS.md"
    if grep -q "docs.*guidelines" "$REPO_ROOT/AGENTS.md"; then
        echo "✅ AGENTS.md: contains docs index"
    else
        echo "❌ AGENTS.md: missing docs index reference"
        ERRORS=$((ERRORS + 1))
    fi
fi
echo ""

# CLAUDE.md
echo "=== CLAUDE.md ==="
if check_exists "$REPO_ROOT/CLAUDE.md"; then
    check_size "$REPO_ROOT/CLAUDE.md" 100
    check_secrets "$REPO_ROOT/CLAUDE.md"
    if grep -q "@AGENTS.md" "$REPO_ROOT/CLAUDE.md"; then
        echo "✅ CLAUDE.md: contains @AGENTS.md import"
    else
        echo "❌ CLAUDE.md: missing @AGENTS.md import"
        ERRORS=$((ERRORS + 1))
    fi
fi
echo ""

# Guideline files
echo "=== Domain Guidelines ==="
guideline_count=$(find "$REPO_ROOT/docs" -name "*-guidelines.md" 2>/dev/null | wc -l)
if [ "$guideline_count" -gt 0 ]; then
    echo "✅ Found $guideline_count guideline file(s)"
    while IFS= read -r guideline; do
        check_size "$guideline" 200
        check_secrets "$guideline"
    done < <(find "$REPO_ROOT/docs" -name "*-guidelines.md" | sort)
else
    echo "⚠️  No guideline files found in docs/"
fi
echo ""

# README.md
echo "=== README.md ==="
if check_exists "$REPO_ROOT/README.md"; then
    check_secrets "$REPO_ROOT/README.md"
    if grep -qiE "^##? .*(install|build|getting started|usage|quick start)" "$REPO_ROOT/README.md"; then
        echo "✅ README.md: onboarding content present — agents can build and run without exploring the codebase"
    else
        echo "⚠️  README.md: missing install/build/getting started section"
    fi
fi
echo ""

# Summary
echo "========================================"
if [ "$ERRORS" -eq 0 ]; then
    echo "✅ All checks passed"
    exit 0
else
    echo "❌ $ERRORS error(s) found — fix before creating PR"
    exit 1
fi
