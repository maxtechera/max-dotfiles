# /commit - Intelligent Git Commit Analyzer

## Purpose
Analyzes working directory changes, understands context from Linear/Jira tickets, git history, and creates atomic, well-structured commits following best practices.

## Usage
```
/commit [options]
```

## Options
- `--ticket [TICKET-ID]` - Link commits to specific ticket
- `--dry-run` - Preview commit plan without executing
- `--push` - Auto-push after commits
- `--pr` - Create pull request after commits

## Workflow

### 1. Context Gathering
- Run `git status` to see all changes
- Run `git diff --cached` and `git diff` to analyze modifications
- Check for Linear/Jira ticket context (from branch name or --ticket flag)
- Analyze recent commit history for style patterns
- Look for TODO/FIXME comments that were addressed

### 2. Change Analysis
- Group related changes by:
  - Feature/functionality
  - File type (backend/frontend/config/docs)
  - Logical units (e.g., API endpoint + tests + docs)
- Identify dependencies between changes
- Detect refactoring vs new features vs bug fixes

### 3. Commit Strategy
- Create atomic commits that:
  - Have single, clear purpose
  - Can be reverted independently
  - Include all related changes (code + tests + docs)
- Order commits logically (dependencies first)
- Follow conventional commit format

### 4. Commit Message Generation
Format:
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: feat, fix, docs, style, refactor, test, chore, perf
Scope: Component or area affected
Subject: Imperative mood, lowercase, no period
Body: What changed and why (not how)
Footer: Breaking changes, issue references

### 5. Safety Checks
- Ensure no sensitive data (API keys, passwords)
- Verify tests pass (if test command configured)
- Check linting passes
- Confirm no debug code left behind

### 6. Execution Plan
Present plan to user:
```
📋 Commit Plan
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Detected Context:
- Ticket: LINEAR-123 (Add user authentication)
- Branch: feature/user-auth
- Type: Feature implementation

Proposed Commits:

1️⃣ feat(auth): add JWT token generation and validation
   Files: 
   - src/auth/jwt.service.ts (new)
   - src/auth/jwt.service.spec.ts (new)
   - src/config/auth.config.ts (modified)
   
2️⃣ feat(api): add authentication middleware
   Files:
   - src/middleware/auth.middleware.ts (new)
   - src/middleware/index.ts (modified)
   
3️⃣ test(auth): add integration tests for auth flow
   Files:
   - tests/integration/auth.test.ts (new)
   - tests/fixtures/users.json (new)

4️⃣ docs(api): update API documentation with auth endpoints
   Files:
   - docs/api/authentication.md (new)
   - README.md (modified)

Proceed with commits? [y/n/edit]
```

### 7. Interactive Editing
If user chooses 'edit':
- Allow reordering commits
- Edit commit messages
- Split or merge commits
- Exclude certain changes

### 8. Execution
- Stage files for each commit
- Create commits with generated messages
- Add Linear/Jira references
- Run post-commit hooks
- Optional: push and create PR

## Example Implementation

```bash
# Analyze current state
git status --porcelain
git diff --name-status
git log --oneline -10

# Group changes
# Group 1: Authentication core
# - src/auth/jwt.service.ts
# - src/auth/jwt.service.spec.ts
# - src/config/auth.config.ts

# Group 2: API integration
# - src/middleware/auth.middleware.ts
# - src/routes/auth.routes.ts

# Generate commits
git add src/auth/jwt.service.ts src/auth/jwt.service.spec.ts src/config/auth.config.ts
git commit -m "feat(auth): implement JWT token service

- Add JWT token generation with RS256 algorithm
- Add token validation with expiry checking
- Configure auth settings in config module

Refs: LINEAR-123"

# Continue for other groups...
```

## Best Practices Enforced

1. **Atomic Commits**: Each commit does one thing well
2. **Logical Ordering**: Dependencies committed first
3. **Complete Changes**: Related files committed together
4. **Clear Messages**: Follow conventional commit format
5. **Ticket Linking**: Auto-reference Linear/Jira tickets
6. **No Mixing**: Don't mix features, fixes, and refactoring
7. **Test Together**: Tests committed with their implementation

## Configuration

Add to CLAUDE.md:
```yaml
commit:
  conventions: conventional # or custom format
  test_command: "npm test"
  lint_command: "npm run lint"
  ticket_pattern: "(LINEAR|JIRA|MAX)-\\d+"
  auto_stage: true
  sign_commits: true
```

## Error Handling

- If uncommitted changes conflict, offer to stash
- If tests fail, show which commit would break
- If lint fails, offer to fix automatically
- If no changes, inform user gracefully