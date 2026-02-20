#!/bin/bash
# Generate worker instructions.md template

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <stage-number> <worker-number> <task-name> <task-title>"
    echo "Example: $0 1 1 lld-analysis 'LLD Analysis'"
    exit 1
fi

STAGE_NUM=$1
WORKER_NUM=$2
TASK_NAME=$3
TASK_TITLE=$4

STAGE_DIR="stage-${STAGE_NUM}-*"
WORKER_DIR=$(ls -d ${STAGE_DIR}/worker-${WORKER_NUM}-${TASK_NAME} 2>/dev/null | head -1)

if [ -z "$WORKER_DIR" ]; then
    echo "Error: Worker directory not found"
    exit 1
fi

cat > "${WORKER_DIR}/instructions.md" << TEMPLATE
# Worker Instructions: ${TASK_TITLE}

**Worker ID**: worker-${WORKER_NUM}-${TASK_NAME}
**Stage**: Stage ${STAGE_NUM}
**Project**: project-plan-4 (Marketing Lambda Implementation)

---

## Task Description

TODO: Describe the task

---

## Inputs

- TODO: List input files and documents

---

## Deliverables

- \`output.md\` containing:
  - TODO: Define sections

---

## Expected Output Format

\`\`\`markdown
# ${TASK_TITLE} - Output

## Section 1

TODO: Define structure

\`\`\`

---

## Success Criteria

- [ ] TODO: Define success criteria

---

## Execution Steps

1. Read input documents
2. TODO: Define steps
3. Create output.md
4. Update work.state to COMPLETE

---

**Created**: $(date +%Y-%m-%d)
TEMPLATE

echo "Created: ${WORKER_DIR}/instructions.md"
