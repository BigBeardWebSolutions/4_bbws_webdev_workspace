#!/bin/bash
################################################################################
# Cron Job Setup for SIT Soak Testing
# Purpose: Set up automated monitoring every 6 hours
# Usage: ./setup_cron_monitoring.sh [install|uninstall|status]
################################################################################

ACTION=${1:-"install"}

SCRIPTS_DIR="/Users/tebogotseka/Documents/agentic_work/2_bbws_agents/scripts"
MONITOR_SCRIPT="$SCRIPTS_DIR/sit_soak_monitor.sh"
SMOKE_TEST_SCRIPT="$SCRIPTS_DIR/run_all_smoke_tests.sh"

# Cron schedule: Every 6 hours (at 2:00, 8:00, 14:00, 20:00)
CRON_SCHEDULE="0 2,8,14,20 * * *"

# Full cron entry
CRON_ENTRY="$CRON_SCHEDULE $MONITOR_SCRIPT auto >> /Users/tebogotseka/Documents/agentic_work/.claude/logs/cron_monitor.log 2>&1"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

################################################################################
# Functions
################################################################################

check_existing_cron() {
  crontab -l 2>/dev/null | grep -q "$MONITOR_SCRIPT" && return 0 || return 1
}

install_cron() {
  echo ""
  echo "=========================================="
  echo "Installing Cron Jobs for SIT Monitoring"
  echo "=========================================="

  # Check if scripts exist
  if [[ ! -f "$MONITOR_SCRIPT" ]]; then
    echo -e "${RED}ERROR: Monitor script not found at $MONITOR_SCRIPT${NC}"
    exit 1
  fi

  if [[ ! -x "$MONITOR_SCRIPT" ]]; then
    echo -e "${YELLOW}Making monitor script executable...${NC}"
    chmod +x "$MONITOR_SCRIPT"
  fi

  # Check if cron job already exists
  if check_existing_cron; then
    echo -e "${YELLOW}WARNING: Cron job already exists!${NC}"
    echo "Run './setup_cron_monitoring.sh uninstall' first to remove it."
    exit 1
  fi

  # Create temporary cron file
  TEMP_CRON=$(mktemp)

  # Get existing crontab (if any)
  crontab -l 2>/dev/null > "$TEMP_CRON" || true

  # Add monitoring job
  echo "" >> "$TEMP_CRON"
  echo "# SIT Soak Testing - Automated Monitoring (every 6 hours)" >> "$TEMP_CRON"
  echo "$CRON_ENTRY" >> "$TEMP_CRON"

  # Install new crontab
  crontab "$TEMP_CRON"

  # Clean up
  rm "$TEMP_CRON"

  echo -e "${GREEN}✅ Cron job installed successfully!${NC}"
  echo ""
  echo "Schedule: Every 6 hours at 02:00, 08:00, 14:00, 20:00"
  echo "Script: $MONITOR_SCRIPT"
  echo "Logs: /Users/tebogotseka/Documents/agentic_work/.claude/logs/"
  echo ""
  echo "To view current cron jobs: crontab -l"
  echo "To remove cron jobs: ./setup_cron_monitoring.sh uninstall"
  echo ""
}

uninstall_cron() {
  echo ""
  echo "=========================================="
  echo "Uninstalling Cron Jobs"
  echo "=========================================="

  # Check if cron job exists
  if ! check_existing_cron; then
    echo -e "${YELLOW}No SIT monitoring cron job found.${NC}"
    exit 0
  fi

  # Create temporary cron file
  TEMP_CRON=$(mktemp)

  # Get existing crontab and remove our entries
  crontab -l 2>/dev/null | grep -v "$MONITOR_SCRIPT" > "$TEMP_CRON" || true

  # Install new crontab
  crontab "$TEMP_CRON"

  # Clean up
  rm "$TEMP_CRON"

  echo -e "${GREEN}✅ Cron job removed successfully!${NC}"
  echo ""
}

show_status() {
  echo ""
  echo "=========================================="
  echo "Cron Monitoring Status"
  echo "=========================================="

  if check_existing_cron; then
    echo -e "${GREEN}✅ Cron job is INSTALLED${NC}"
    echo ""
    echo "Current cron entry:"
    crontab -l | grep "$MONITOR_SCRIPT"
    echo ""
    echo "Next scheduled runs:"
    echo "  - Today at 02:00, 08:00, 14:00, 20:00"
  else
    echo -e "${YELLOW}⚠️  Cron job is NOT installed${NC}"
    echo ""
    echo "Run './setup_cron_monitoring.sh install' to install"
  fi

  echo ""
  echo "Recent logs:"
  if [[ -f "/Users/tebogotseka/Documents/agentic_work/.claude/logs/cron_monitor.log" ]]; then
    tail -20 "/Users/tebogotseka/Documents/agentic_work/.claude/logs/cron_monitor.log"
  else
    echo "  No logs found yet"
  fi
  echo ""
}

show_help() {
  echo ""
  echo "Usage: ./setup_cron_monitoring.sh [install|uninstall|status|help]"
  echo ""
  echo "Commands:"
  echo "  install    - Install cron job for automated monitoring"
  echo "  uninstall  - Remove cron job"
  echo "  status     - Show cron job status and recent logs"
  echo "  help       - Show this help message"
  echo ""
  echo "Schedule:"
  echo "  Runs every 6 hours at: 02:00, 08:00, 14:00, 20:00"
  echo ""
  echo "Logs:"
  echo "  /Users/tebogotseka/Documents/agentic_work/.claude/logs/cron_monitor.log"
  echo "  /Users/tebogotseka/Documents/agentic_work/.claude/logs/soak_checkpoints.log"
  echo ""
}

################################################################################
# Main
################################################################################

case "$ACTION" in
  install)
    install_cron
    ;;
  uninstall)
    uninstall_cron
    ;;
  status)
    show_status
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    echo -e "${RED}ERROR: Unknown action '$ACTION'${NC}"
    show_help
    exit 1
    ;;
esac
