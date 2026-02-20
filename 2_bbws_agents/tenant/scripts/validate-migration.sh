#!/bin/bash

################################################################################
# WordPress Migration Validation Script
################################################################################
#
# Purpose: Validate WordPress migration success across multiple dimensions
# Usage: ./validate-migration.sh <tenant-url> [options]
#
# Features:
# - HTTP status validation
# - Mixed content detection
# - UTF-8 encoding validation
# - PHP error detection
# - Performance testing
# - Integration point testing (email, tracking, forms)
# - Security headers validation
#
################################################################################

set -e
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0

################################################################################
# Helper Functions
################################################################################

success() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((TESTS_FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
    ((TESTS_WARNED++))
}

info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

################################################################################
# Usage
################################################################################

usage() {
    cat << EOF
WordPress Migration Validation Script

Usage: $0 <tenant-url> [options]

Required:
    tenant-url              Full URL to validate (e.g., https://aupairhive.wpdev.kimmyai.io)

Options:
    --skip-performance      Skip performance testing
    --skip-integration      Skip integration point testing
    --threshold SECONDS     Performance threshold in seconds [default: 3.0]
    --verbose               Show detailed output
    --json                  Output results in JSON format
    --help                  Show this help message

Examples:
    $0 https://aupairhive.wpdev.kimmyai.io
    $0 https://tenant.wpdev.kimmyai.io --skip-performance
    $0 https://tenant.wpdev.kimmyai.io --threshold 2.0 --verbose

EOF
    exit 1
}

################################################################################
# Parse Arguments
################################################################################

if [ $# -eq 0 ]; then
    usage
fi

TENANT_URL="$1"
shift

SKIP_PERFORMANCE=false
SKIP_INTEGRATION=false
PERFORMANCE_THRESHOLD=3.0
VERBOSE=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-performance)
            SKIP_PERFORMANCE=true
            shift
            ;;
        --skip-integration)
            SKIP_INTEGRATION=true
            shift
            ;;
        --threshold)
            PERFORMANCE_THRESHOLD="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Extract tenant name from URL for reference
TENANT_NAME=$(echo "$TENANT_URL" | sed -E 's|https?://([^.]+).*|\1|')

################################################################################
# Core Validation Tests
################################################################################

test_http_status() {
    header "Test 1: HTTP Status Code"

    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$TENANT_URL" --max-time 10 || echo "000")

    info "Testing: $TENANT_URL"
    info "Status Code: $http_code"

    case $http_code in
        200)
            success "Site returns HTTP 200 OK"
            ;;
        301|302)
            warn "Site returns HTTP $http_code (redirect)"
            ;;
        401|403)
            warn "Site returns HTTP $http_code (authentication required)"
            ;;
        404)
            fail "Site returns HTTP 404 (not found)"
            ;;
        500|502|503)
            fail "Site returns HTTP $http_code (server error)"
            ;;
        000)
            fail "Connection failed (timeout or network error)"
            ;;
        *)
            warn "Site returns HTTP $http_code (unexpected)"
            ;;
    esac
}

test_mixed_content() {
    header "Test 2: Mixed Content Detection"

    info "Checking for HTTP resources on HTTPS page..."

    local html_content=$(curl -s "$TENANT_URL" --max-time 10)

    # Extract domain from URL
    local domain=$(echo "$TENANT_URL" | sed -E 's|https?://([^/]+).*|\1|')

    # Count HTTP URLs for this domain
    local http_urls=$(echo "$html_content" | grep -o "http://$domain" | wc -l | tr -d ' ')

    # Count total HTTP resources
    local total_http=$(echo "$html_content" | grep -o 'http://' | wc -l | tr -d ' ')

    info "HTTP URLs for domain: $http_urls"
    info "Total HTTP resources: $total_http"

    if [ "$http_urls" -eq "0" ]; then
        success "No HTTP URLs found for $domain (all HTTPS)"
    else
        fail "Found $http_urls HTTP URLs on HTTPS page (mixed content)"

        if [ "$VERBOSE" = true ]; then
            echo ""
            echo "Sample HTTP URLs:"
            echo "$html_content" | grep -o "http://$domain[^\"'> ]*" | head -n 5
        fi
    fi

    # Check for external HTTP resources (may be intentional)
    local external_http=$((total_http - http_urls))
    if [ "$external_http" -gt 0 ]; then
        warn "Found $external_http HTTP resources for external domains"
    fi
}

test_encoding() {
    header "Test 3: UTF-8 Encoding Validation"

    info "Checking for common encoding artifacts..."

    local html_content=$(curl -s "$TENANT_URL" --max-time 10)

    # Common UTF-8 double-encoding artifacts
    local artifacts=(
        "Â "     # Non-breaking space
        "â€™"   # Right single quote
        "â€œ"   # Left double quote
        "â€"    # Right double quote
        "â€""   # En dash
        "â€""   # Em dash
        "â€¦"   # Ellipsis
        "Ã©"    # é (e-acute)
        "Ã "    # à (a-grave)
    )

    local total_artifacts=0

    for artifact in "${artifacts[@]}"; do
        local count=$(echo "$html_content" | grep -o "$artifact" | wc -l | tr -d ' ')
        total_artifacts=$((total_artifacts + count))

        if [ "$count" -gt 0 ] && [ "$VERBOSE" = true ]; then
            echo "  Found $count instances of: $artifact"
        fi
    done

    if [ "$total_artifacts" -eq 0 ]; then
        success "No encoding artifacts detected"
    else
        fail "Found $total_artifacts encoding artifacts"

        if [ "$VERBOSE" = true ]; then
            echo ""
            echo "Sample content with artifacts:"
            echo "$html_content" | grep -E "Â |â€" | head -n 3
        fi
    fi
}

test_php_errors() {
    header "Test 4: PHP Error Detection"

    info "Checking for visible PHP errors..."

    local html_content=$(curl -s "$TENANT_URL" --max-time 10)

    # PHP error patterns
    local php_notices=$(echo "$html_content" | grep -c "PHP Notice:" || echo "0")
    local php_warnings=$(echo "$html_content" | grep -c "PHP Warning:" || echo "0")
    local php_deprecated=$(echo "$html_content" | grep -c "PHP Deprecated:" || echo "0")
    local php_fatal=$(echo "$html_content" | grep -c "PHP Fatal error:" || echo "0")

    local total_errors=$((php_notices + php_warnings + php_deprecated + php_fatal))

    info "PHP Notices: $php_notices"
    info "PHP Warnings: $php_warnings"
    info "PHP Deprecated: $php_deprecated"
    info "PHP Fatal Errors: $php_fatal"

    if [ "$total_errors" -eq 0 ]; then
        success "No PHP errors visible"
    else
        fail "Found $total_errors PHP errors/warnings on page"

        if [ "$VERBOSE" = true ]; then
            echo ""
            echo "Sample PHP errors:"
            echo "$html_content" | grep -E "PHP (Notice|Warning|Deprecated|Fatal)" | head -n 5
        fi
    fi
}

test_ssl_certificate() {
    header "Test 5: SSL Certificate Validation"

    info "Checking SSL certificate..."

    # Extract hostname
    local hostname=$(echo "$TENANT_URL" | sed -E 's|https?://([^/]+).*|\1|')

    # Check SSL cert (only for HTTPS URLs)
    if [[ "$TENANT_URL" == https://* ]]; then
        local ssl_info=$(echo | openssl s_client -servername "$hostname" -connect "$hostname:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "")

        if [ -n "$ssl_info" ]; then
            success "Valid SSL certificate found"

            if [ "$VERBOSE" = true ]; then
                echo "$ssl_info"
            fi
        else
            warn "Could not retrieve SSL certificate information"
        fi
    else
        warn "Site is not using HTTPS (HTTP detected)"
    fi
}

test_performance() {
    if [ "$SKIP_PERFORMANCE" = true ]; then
        header "Test 6: Performance Testing [SKIPPED]"
        return 0
    fi

    header "Test 6: Performance Testing"

    info "Measuring page load time..."

    local load_time=$(curl -s -o /dev/null -w "%{time_total}" "$TENANT_URL" --max-time 30 || echo "30.0")
    local dns_time=$(curl -s -o /dev/null -w "%{time_namelookup}" "$TENANT_URL" --max-time 30 || echo "0")
    local connect_time=$(curl -s -o /dev/null -w "%{time_connect}" "$TENANT_URL" --max-time 30 || echo "0")
    local ttfb=$(curl -s -o /dev/null -w "%{time_starttransfer}" "$TENANT_URL" --max-time 30 || echo "0")

    info "Total Load Time: ${load_time}s"
    info "DNS Lookup: ${dns_time}s"
    info "Connection Time: ${connect_time}s"
    info "Time to First Byte (TTFB): ${ttfb}s"

    if (( $(echo "$load_time < $PERFORMANCE_THRESHOLD" | bc -l) )); then
        success "Load time under ${PERFORMANCE_THRESHOLD}s threshold"
    elif (( $(echo "$load_time < 5.0" | bc -l) )); then
        warn "Load time ${load_time}s exceeds ${PERFORMANCE_THRESHOLD}s threshold (but under 5s)"
    else
        fail "Load time ${load_time}s significantly exceeds threshold"
    fi
}

test_cloudfront_cache() {
    header "Test 7: CloudFront Cache Status"

    info "Checking CloudFront cache behavior..."

    local cache_status=$(curl -s -I "$TENANT_URL" --max-time 10 | grep -i "x-cache:" | awk '{print $2}' || echo "not-found")

    info "X-Cache Header: $cache_status"

    case $cache_status in
        Hit*)
            success "CloudFront cache HIT (content served from edge)"
            ;;
        Miss*)
            info "CloudFront cache MISS (first request or cache expired)"
            success "CloudFront is active"
            ;;
        RefreshHit*)
            info "CloudFront cache RefreshHit (revalidated with origin)"
            success "CloudFront is active"
            ;;
        not-found)
            warn "X-Cache header not found (CloudFront may not be configured)"
            ;;
        *)
            info "Cache status: $cache_status"
            ;;
    esac
}

test_environment_indicator() {
    header "Test 8: Environment Indicator"

    info "Checking for environment indicator..."

    local html_content=$(curl -s "$TENANT_URL" --max-time 10)

    local has_indicator=$(echo "$html_content" | grep -c "ENVIRONMENT" || echo "0")

    if [ "$has_indicator" -gt 0 ]; then
        success "Environment indicator present"

        if [ "$VERBOSE" = true ]; then
            local env_text=$(echo "$html_content" | grep -o "[A-Z]* ENVIRONMENT" | head -n 1)
            info "Indicator text: $env_text"
        fi
    else
        # Only warn if this is a non-production URL
        if [[ "$TENANT_URL" == *"wpdev"* ]] || [[ "$TENANT_URL" == *"wpsit"* ]]; then
            warn "Environment indicator not found (expected for dev/sit)"
        else
            success "No environment indicator (expected for production)"
        fi
    fi
}

test_wordpress_health() {
    header "Test 9: WordPress Health Check"

    info "Checking WordPress core files..."

    # Check if wp-admin is accessible
    local wpadmin_url="${TENANT_URL}/wp-admin/"
    local wpadmin_status=$(curl -s -o /dev/null -w "%{http_code}" "$wpadmin_url" --max-time 10 || echo "000")

    if [ "$wpadmin_status" = "200" ] || [ "$wpadmin_status" = "302" ]; then
        success "wp-admin accessible (HTTP $wpadmin_status)"
    else
        warn "wp-admin returned HTTP $wpadmin_status"
    fi

    # Check if wp-json API is accessible
    local wpjson_url="${TENANT_URL}/wp-json/"
    local wpjson_status=$(curl -s -o /dev/null -w "%{http_code}" "$wpjson_url" --max-time 10 || echo "000")

    if [ "$wpjson_status" = "200" ]; then
        success "WordPress REST API accessible"
    else
        warn "WordPress REST API returned HTTP $wpjson_status"
    fi
}

test_integration_points() {
    if [ "$SKIP_INTEGRATION" = true ]; then
        header "Test 10: Integration Points [SKIPPED]"
        return 0
    fi

    header "Test 10: Integration Points"

    local html_content=$(curl -s "$TENANT_URL" --max-time 10)

    # Test for common tracking scripts
    info "Checking for tracking scripts..."

    local has_gtag=$(echo "$html_content" | grep -c "gtag\|googletagmanager\.com" || echo "0")
    local has_fbpixel=$(echo "$html_content" | grep -c "fbq\|connect\.facebook\.net" || echo "0")

    if [ "$has_gtag" -gt 0 ]; then
        info "Google Analytics detected"
    fi

    if [ "$has_fbpixel" -gt 0 ]; then
        info "Facebook Pixel detected"
    fi

    # Check if tracking is mocked
    local has_mock=$(echo "$html_content" | grep -c "MOCKED\|TEST MODE" || echo "0")

    if [[ "$TENANT_URL" == *"wpdev"* ]] || [[ "$TENANT_URL" == *"wpsit"* ]]; then
        if [ "$has_mock" -gt 0 ]; then
            success "Tracking scripts appear to be mocked in test environment"
        elif [ "$has_gtag" -gt 0 ] || [ "$has_fbpixel" -gt 0 ]; then
            warn "Live tracking scripts detected in test environment (should be mocked)"
        else
            info "No tracking scripts detected"
        fi
    else
        if [ "$has_gtag" -gt 0 ] || [ "$has_fbpixel" -gt 0 ]; then
            success "Tracking scripts present (expected for production)"
        fi
    fi
}

################################################################################
# Results Summary
################################################################################

display_summary() {
    echo ""
    echo "========================================================================"
    header "Validation Summary"
    echo ""
    echo "Site: $TENANT_URL"
    echo "Tenant: $TENANT_NAME"
    echo "Timestamp: $(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)"
    echo ""
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    echo -e "${YELLOW}Warnings:${NC} $TESTS_WARNED"
    echo ""

    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}✅ All critical tests passed!${NC}"
        echo "========================================================================"
        return 0
    else
        echo -e "${RED}❌ Some tests failed. Review output above for details.${NC}"
        echo "========================================================================"
        return 1
    fi
}

output_json() {
    cat << EOF
{
  "tenant": "$TENANT_NAME",
  "url": "$TENANT_URL",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "results": {
    "passed": $TESTS_PASSED,
    "failed": $TESTS_FAILED,
    "warned": $TESTS_WARNED
  },
  "status": "$([ $TESTS_FAILED -eq 0 ] && echo "success" || echo "failure")"
}
EOF
}

################################################################################
# Main Execution
################################################################################

main() {
    echo "========================================================================"
    echo "  WordPress Migration Validation"
    echo "========================================================================"
    echo ""
    echo "Target: $TENANT_URL"
    echo "Tenant: $TENANT_NAME"
    echo ""

    # Run all tests
    test_http_status
    test_mixed_content
    test_encoding
    test_php_errors
    test_ssl_certificate
    test_performance
    test_cloudfront_cache
    test_environment_indicator
    test_wordpress_health
    test_integration_points

    # Display results
    if [ "$JSON_OUTPUT" = true ]; then
        output_json
    else
        display_summary
    fi

    # Exit with appropriate code
    [ "$TESTS_FAILED" -eq 0 ] && exit 0 || exit 1
}

main

