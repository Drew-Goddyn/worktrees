# worktrees Demo Recording
# Run with: vhs worktrees-demo.tape

# VHS configuration
Output worktrees-demo.gif
Output worktrees-demo.mp4

Set FontSize 18
Set Width 800
Set Height 600
Set Theme "Dracula"
Set CursorBlink true
Set WindowBar Rings
Set WindowBarSize 40
Set Padding 20
Set TypingSpeed 50ms

# Start recording
Type "# Welcome to worktrees - Hold on tight! 🎢"
Enter
Sleep 1s

# Create alias for demo (won't error)
Hide
Type "alias worktrees='echo'"
Enter
Show

Type "# Check version"
Enter
Sleep 500ms

Type "echo 'worktrees v0.9.2.1.alpha.rc2.FINAL(2)'"
Enter
Sleep 300ms
Type "echo '⚠️  WARNING: May contain bugs'"
Enter
Type "echo '⚠️  WARNING: Side effects include productivity'"
Enter
Sleep 1.5s

Type "clear"
Enter
Sleep 500ms

# Create a worktree
Type "# Let's create a new worktree (fingers crossed! 🤞)"
Enter
Sleep 1s

Type "echo 'INITIATING WORKTREE CREATION SEQUENCE...'"
Enter
Sleep 500ms

Type "echo '[████░░░░░░░░░░░░░░░░] 20%'"
Enter
Sleep 500ms
Type "echo '[████████░░░░░░░░░░░░] 40%'"
Enter
Sleep 500ms
Type "echo '[████████████░░░░░░░░] 60%'"
Enter
Sleep 500ms
Type "echo '[████████████████░░░░] 87% ...'"
Enter
Sleep 1s
Type "echo '⚠️  ERROR: Coffee levels critically low!'"
Enter
Sleep 1s
Type "echo '☕ INJECTING EMERGENCY CAFFEINE...'"
Enter
Sleep 1s
Type "echo '[████████████████████] 100%'"
Enter
Type "echo '✓ Worktree created at ~/.worktrees/001-please-work'"
Enter
Type "echo '  Note: Existence not guaranteed'"
Enter
Sleep 2s

# List worktrees
Type "# Let's see what we've got..."
Enter
Sleep 1s

Type "echo 'SCANNING FOR SURVIVORS...'"
Enter
Sleep 500ms

Type "cat << 'EOF'"
Enter
Type "╔════════════════════════════════════════════╗"
Enter
Type "║  ID               STATUS    PATH           ║"
Enter
Type "╠════════════════════════════════════════════╣"
Enter
Type "║* 001-please-work  zombie    ~/.worktrees/  ║"
Enter
Type "║  002-help-me      haunted   ~/.worktrees/  ║"
Enter
Type "║  003-final-final  cursed    ~/.worktrees/  ║"
Enter
Type "║  999-the-end      ḩ̸ë̷ḽṕ̶     [REDACTED]     ║"
Enter
Type "╚════════════════════════════════════════════╝"
Enter
Type "⚠️  4 worktrees found (3 possibly functional)"
Enter
Type "EOF"
Enter
Sleep 2s

# Try to switch
Type "# Let's switch to a worktree!"
Enter
Sleep 1s

Type "echo '🎲 Rolling dice for success...'"
Enter
Sleep 1s
Type "echo '🎲 Rolled: 4/20 (Not great, not terrible)'"
Enter
Sleep 500ms
Type "echo '✓ Switched to: 002-help-me'"
Enter
Type "echo '  Current reality: Questionable'"
Enter
Type "echo '  Quantum state: Superposition'"
Enter
Sleep 2s

# Status check
Type "# Quick status check..."
Enter
Sleep 1s

Type "cat << 'EOF'"
Enter
Type "CURRENT WORKTREE STATUS:"
Enter
Type "━━━━━━━━━━━━━━━━━━━━━━"
Enter
Type "Name:        002-help-me"
Enter
Type "Health:      74% (↓ declining)"
Enter
Type "Commits:     Yes"
Enter
Type "Sanity:      404 Not Found"
Enter
Type "Last Error:  2 minutes ago"
Enter
Type "Next Error:  ~30 seconds"
Enter
Type "EOF"
Enter
Sleep 2s

# Try to remove (with multiple confirmations)
Type "# Let's try removing that cursed worktree..."
Enter
Sleep 1s

Type "echo '⚠️  WARNING: This worktree appears to be sentient'"
Enter
Type "echo -n 'Are you SURE? [y/N]: '; read -r ans; echo $ans"
Enter
Sleep 500ms
Type "y"
Enter
Sleep 300ms

Type "echo -n 'Are you REALLY sure? [y/N]: '; read -r ans; echo $ans"
Enter
Sleep 500ms
Type "y"
Enter
Sleep 300ms

Type "echo -n 'Like, REALLY REALLY sure? [y/N]: '; read -r ans; echo $ans"
Enter
Sleep 500ms
Type "Y"
Enter
Sleep 300ms

Type "echo 'Attempting removal...'"
Enter
Sleep 500ms
Type "echo -n '.'; sleep 0.5; echo -n '.'; sleep 0.5; echo '.'"
Enter
Sleep 2s
Type "echo '❌ ERROR: This worktree has rejected your reality'"
Enter
Type "echo '         and substituted its own'"
Enter
Type "echo 'Good luck! 🍀'"
Enter
Sleep 2s

# Grand finale
Type "# One more thing..."
Enter
Sleep 1s

Type "cat << 'EOF'"
Enter
Type "HELP? THERE IS NO HELP"
Enter
Type "Only worktrees."
Enter
Type ""
Enter
Type "But if you insist:"
Enter
Type "  create  - May create a worktree"
Enter
Type "  list    - Shows some worktrees"
Enter
Type "  switch  - Quantum leap between realities"
Enter
Type "  remove  - Attempt to destroy (usually fails)"
Enter
Type "  status  - Check your sanity levels"
Enter
Type ""
Enter
Type "Remember: NNN-kebab-case or the naming"
Enter
Type "          police will find you 🚔"
Enter
Type "EOF"
Enter
Sleep 3s

Type "# Thanks for watching! Install at your own risk! 💀"
Enter
Sleep 2s