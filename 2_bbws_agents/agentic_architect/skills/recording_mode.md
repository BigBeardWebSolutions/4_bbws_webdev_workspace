# Recording Mode Skill

**Version**: 1.0.0
**Created**: 2025-12-27
**Purpose**: Persistent conversation logging for Agentic Architect sessions

---

## Overview

Recording Mode creates timestamped log files that capture the complete conversation between user and agent. Once activated, all interactions are logged to `logs/recording_[Timestamp].log` in the execution folder's `.claude/` directory until explicitly deactivated.

## Activation

**Command**: `start recording` or `enable recording mode`

**Behavior**:
1. Check if recording is already active
2. Create timestamp: `YYYY_MM_DD_HH_MM_SS` (e.g., `2025_12_27_14_30_45`)
3. Create log file: `.claude/logs/recording_[Timestamp].log`
4. Initialize log with session metadata
5. Set recording state to ACTIVE
6. Confirm activation to user

**Initial Log Entry**:
```markdown
# Recording Session: [Timestamp]

**Started**: 2025-12-27 14:30:45
**Agent**: Agentic Architect
**Mode**: ACTIVE
**Location**: [absolute path to .claude/logs/recording_[Timestamp].log]

---

## Conversation Log

```

## Logging Format

Each conversation turn is logged with:
- Timestamp
- Speaker (USER or AGENT)
- Message content
- Tool calls (if any)
- File operations (if any)

**Entry Format**:
```markdown
### [HH:MM:SS] USER
[User's message verbatim]

### [HH:MM:SS] AGENT
[Agent's response verbatim]

**Tools Used**:
- Read: file.ts (lines 1-50)
- Edit: config.json
- Bash: npm run build

**Files Modified**:
- src/component.ts (edited)
- README.md (created)
```

## Active Recording Behavior

While recording is ACTIVE:

1. **Before each response**: Append user message to log
2. **After each response**: Append agent response, tools used, files modified
3. **On tool execution**: Log tool name, parameters, duration
4. **On file changes**: Log file path, operation type (read/edit/write)
5. **On errors**: Log error message and stack trace
6. **Flush**: Write to disk after each turn (don't buffer)

## Deactivation

**Command**: `stop recording` or `disable recording mode`

**Behavior**:
1. Append final log entry with session summary
2. Set recording state to INACTIVE
3. Close log file
4. Confirm deactivation to user
5. Provide log file location

**Final Log Entry**:
```markdown
---

## Session Summary

**Ended**: 2025-12-27 15:45:30
**Duration**: 1h 14m 45s
**Total Turns**: 47
**Tools Used**: 23
**Files Modified**: 8
**Errors**: 0

**Status**: COMPLETE
```

## State Management

**Recording State**:
- `INACTIVE` - No active recording
- `ACTIVE` - Currently logging all interactions

**State Persistence**:
- State stored in memory (per session)
- Log file location stored in state
- Automatically deactivate on session end

**State Checking**:
```markdown
User: "is recording active?"

Agent:
Recording Mode: ACTIVE
Log File: .claude/logs/recording_2025_12_27_14_30_45.log
Started: 2025-12-27 14:30:45
Duration: 15m 23s
Turns Logged: 12
```

## Log File Location

**Path Resolution**:
1. Check if current working directory has `.claude/logs/`
2. If not, create `.claude/logs/` directory structure
3. Store log in: `[CWD]/.claude/logs/recording_[Timestamp].log`

**Example Paths**:
```
# Working in project root
/Users/sellots/Documents/project/.claude/logs/recording_2025_12_27_14_30_45.log

# Working in subdirectory
/Users/sellots/Documents/project/subdir/.claude/logs/recording_2025_12_27_14_30_45.log
```

## Error Handling

**Scenarios**:

1. **Already Recording**:
   ```
   User: "start recording"
   Agent: "Recording already active since 14:30:45
           Log: .claude/logs/recording_2025_12_27_14_30_45.log
           Continue current session or stop first?"
   ```

2. **Not Recording (when stopping)**:
   ```
   User: "stop recording"
   Agent: "No active recording to stop."
   ```

3. **Log File Write Error**:
   ```
   Agent: "⚠️ Failed to write to log file: [error message]
           Recording automatically deactivated.
           Partial log saved: [path]"
   ```

4. **.claude/ Directory Missing**:
   ```
   Agent: "Creating .claude/logs/ directory structure..."
   [Creates .claude/logs/]
   Agent: "✓ Recording started: .claude/logs/recording_2025_12_27_14_30_45.log"
   ```

## Usage Examples

### Example 1: Basic Session

```markdown
User: "start recording"

Agent:
✓ Recording started
Log: .claude/logs/recording_2025_12_27_14_30_45.log
Mode: ACTIVE
All interactions will be logged until recording is stopped.

---

User: "Create a TypeScript interface for User"

Agent:
I'll create a TypeScript interface for User.
[Creates file with Write tool]

[Logged to recording_2025_12_27_14_30_45.log]:
### [14:31:12] USER
Create a TypeScript interface for User

### [14:31:15] AGENT
I'll create a TypeScript interface for User.

**Tools Used**:
- Write: src/types.ts

**Files Modified**:
- src/types.ts (created)

---

User: "stop recording"

Agent:
✓ Recording stopped
Duration: 3m 42s
Turns: 4
Log: .claude/logs/recording_2025_12_27_14_30_45.log
```

### Example 2: Multi-File Project

```markdown
User: "start recording"
Agent: ✓ Recording started
Log: .claude/logs/recording_2025_12_27_15_00_00.log

[User works on complex refactoring for 45 minutes]

User: "is recording active?"
Agent:
Recording Mode: ACTIVE
Log: .claude/logs/recording_2025_12_27_15_00_00.log
Started: 2025-12-27 15:00:00
Duration: 45m 12s
Turns: 67
Files Modified: 12

User: "stop recording"
Agent:
✓ Recording stopped
Duration: 45m 30s
Turns: 68
Files Modified: 12
Log: .claude/logs/recording_2025_12_27_15_00_00.log

Session captured successfully.
```

### Example 3: Error Recovery

```markdown
User: "start recording"
Agent: ✓ Recording started
Log: .claude/logs/recording_2025_12_27_16_00_00.log

[Disk runs out of space]

Agent:
⚠️ Failed to write to log file: No space left on device
Recording automatically deactivated.
Partial log saved: .claude/logs/recording_2025_12_27_16_00_00.log

Please free up disk space to continue logging.
```

## Implementation Notes

**Technical Details**:
- Use append mode for log file (`fs.appendFile` or equivalent)
- Flush after every turn (don't buffer)
- Handle file system errors gracefully
- Timestamp format: ISO 8601 with local time
- Log file encoding: UTF-8
- Line endings: Platform-specific (LF on Unix, CRLF on Windows)

**Performance**:
- Minimal overhead (<5ms per turn)
- Async file writes (non-blocking)
- No impact on response time
- Log rotation not required (separate file per session)

**Security**:
- Logs stored locally only
- Contains full conversation history (including sensitive data)
- User responsible for log file security
- No automatic encryption
- No automatic upload/sharing

## Best Practices

**When to Use Recording Mode**:
1. Complex architectural discussions for later reference
2. Multi-stage projects requiring full audit trail
3. Debugging complex issues
4. Learning/training sessions to review later
5. Compliance/documentation requirements

**When NOT to Use**:
1. Quick one-off questions
2. Sensitive projects (logs contain everything)
3. Low disk space environments
4. Sessions with frequent file operations (large logs)

**Log Management**:
- Review and delete old recordings regularly
- Store important recordings in archive location
- Don't commit log files to git (add to .gitignore)
- Compress old logs if keeping for long term

## Integration with TBT Workflow

Recording Mode is **independent** of TBT workflow:

- **TBT history.log**: Commands with XML structure, sequence numbers
- **Recording log**: Complete conversation verbatim, chronological

**Both can run simultaneously**:
- TBT tracks command execution and state
- Recording captures full conversational context

**Use together for**:
- Complete project documentation
- Audit trail (TBT) + narrative (Recording)
- Debugging (command sequence + conversation flow)

---

## Quick Reference

| Command | Action |
|---------|--------|
| `start recording` | Activate recording mode |
| `stop recording` | Deactivate recording mode |
| `is recording active?` | Check recording status |
| `show recording path` | Display log file location |

**Default Location**: `.claude/logs/recording_[Timestamp].log`
**Format**: Markdown with timestamped conversation turns
**State**: In-memory, auto-deactivate on session end
**Flush**: After every turn (immediate write)

---

**Use this skill when the user requests conversation logging, session recording, or audit trail documentation.**
