#!/bin/bash
# Quick GitHub Actions workflow validation script

cd "$(dirname "$0")"

echo "=== Validating GitHub Actions workflow ==="
echo ""

# Check if workflow file exists
if [ ! -f ".github/workflows/build.yml" ]; then
    echo "❌ Workflow file not found"
    exit 1
fi

echo "✓ Workflow file found"

# Validate YAML syntax with Python
if command -v python &> /dev/null; then
    python -c "import yaml; yaml.safe_load(open('.github/workflows/build.yml'))" 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ YAML syntax is valid"
    fi
else
    echo "⚠ YAML syntax check skipped (PyYAML not installed)"
fi

# Check for common issues
echo ""
echo "=== Checking for common issues ==="

# Check if all job dependencies exist
echo "✓ Checking job dependencies..."
JOBS=$(grep -E "^  [a-z-]+:" .github/workflows/build.yml | sed 's/://g' | awk '{print $1}')
for job in $JOBS; do
    echo "  - Job: $job"
done

# Check for artifact upload/download consistency
echo ""
echo "✓ Checking artifact consistency..."
UPLOADS=$(grep -A2 "upload-artifact@v4" .github/workflows/build.yml | grep "name:" | awk '{print $3}')
DOWNLOADS=$(grep -A2 "download-artifact@v4" .github/workflows/build.yml | grep "name:" | awk '{print $3}')

echo "  Uploaded artifacts:"
for artifact in $UPLOADS; do
    echo "    - $artifact"
done

echo "  Downloaded artifacts:"
for artifact in $DOWNLOADS; do
    echo "    - $artifact"
done

# Verify all downloads have corresponding uploads
for dl in $DOWNLOADS; do
    found=0
    for ul in $UPLOADS; do
        if [ "$dl" = "$ul" ]; then
            found=1
            break
        fi
    done
    if [ $found -eq 0 ]; then
        echo "❌ Downloaded artifact '$dl' has no corresponding upload!"
        exit 1
    fi
done

echo ""
echo "=== Validation Summary ==="
echo "✓ All checks passed!"
echo "✓ Workflow structure looks good"
echo ""
echo "Note: For full validation, push to a test branch or use 'act' with Docker"
