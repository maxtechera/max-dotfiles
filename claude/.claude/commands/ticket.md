**Purpose**: Complete tickets systematically with progress tracking and learning capture

---

@include shared/universal-constants.yml#Universal_Legend

## Ticket Workflow Command

Complete tickets from Linear (personal) or Jira (--client) with systematic tracking and reflection.

Usage: 
- `/ticket [ticket-id]` - Work on a Linear ticket
- `/ticket [ticket-id] --client` - Work on a Jira ticket  
- `/ticket [ticket-id] --continue` - Resume previous work

Examples:
- `/ticket LINEAR-123` - Complete a Linear ticket
- `/ticket PROJ-456 --client` - Complete a Jira ticket
- `/ticket LINEAR-123 --continue` - Resume work on LINEAR-123

## Current Context
- Git status: !`git status -s`
- Current branch: !`git branch --show-current`
- Working directory: !`pwd`

## Workflow Process

### 1. Load & Understand
- Fetch ticket details from Linear/Jira
- Review requirements and acceptance criteria
- Check for related tickets or dependencies
- Assess complexity and approach

### 2. Plan & Decompose
- Break work into concrete todos
- Each todo should be independently verifiable
- Order by logical progression
- Include testing and documentation tasks

### 3. Execute & Track
- Work through todos systematically
- Update progress in real-time
- Commit code with ticket reference
- Run tests after implementation
- Document decisions as you go

### 4. Complete & Reflect
- Update ticket status to Done/Resolved
- Add completion comment with:
  - Summary of work done
  - Time taken
  - What worked well
  - Lessons learned
  - Next steps with @solo pattern

## Ticket Comment Template

When completing, add comment:
```
✅ Completed: [Brief summary]

**Time:** [Duration]
**Approach:** [What strategy was used]

**What worked:**
- [Key success factors]

**Lessons learned:**
- [Insights for next time]

**Next steps:**
@solo [specific next action with context]
```

## Integration Notes

@include shared/flag-inheritance.yml#Universal_Always
@include shared/ticket-patterns.yml#Common_Patterns

Works with:
- Linear MCP for personal project tickets
- Jira MCP for client work (use --client flag)
- TodoWrite for task tracking
- Git for version control
- Notion for pattern extraction (future)

## Auto-Continue Support

If using --continue flag:
- Check for existing todos
- Resume from last completed item
- Maintain context from previous session
- Update ticket with continuation note

## Best Practices

- Keep todos small and specific
- Test after each significant change
- Commit regularly with ticket ID
- Document surprises immediately
- Complete reflection even if rushed

@include shared/universal-constants.yml#Standard_Messages_Templates