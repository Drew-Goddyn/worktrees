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
Set TypingSpeed 80ms
Set PlaybackSpeed 1

# Optional: Add some retro VHS effects
Set LoopOffset 50%

# Start recording
Type "# Welcome to worktrees - Hold on tight! 🎢"
Enter
Sleep 1s

Type "worktrees --version"
Enter
Sleep 500ms
Type@500ms "worktrees v0.9.2.1.alpha.rc2.FINAL(2) (EXPERIMENTAL)"
Enter
Type@500ms "⚠️  WARNING: May contain bugs"
Enter
Type@500ms "⚠️  WARNING: Side effects include productivity"
Enter
Sleep 1.5s

Type "clear"
Enter
Sleep 500ms

# Create a worktree
Type "# Let's create a new worktree (fingers crossed! 🤞)"
Enter
Sleep 1s

Type "worktrees create 001-please-work"
Enter
Sleep 500ms
Type@100ms "INITIATING WORKTREE CREATION SEQUENCE..."
Enter
Sleep 300ms

# Progress bar animation
Type "[░░░░░░░░░░░░░░░░░░░░] 0%"
Backspace@50ms 24
Type "[████░░░░░░░░░░░░░░░░] 20%"
Sleep 500ms
Backspace@50ms 25
Type "[████████░░░░░░░░░░░░] 40%"
Sleep 500ms
Backspace@50ms 25
Type "[████████████░░░░░░░░] 60%"
Sleep 500ms
Backspace@50ms 25
Type "[████████████████░░░░] 80%"
Sleep 800ms
Backspace@50ms 25
Type "[████████████████████] 100%"
Enter
Sleep 500ms

Type@100ms "⚠️  ERROR: Coffee levels critically low!"
Enter
Sleep 1s
Type@100ms "☕ INJECTING EMERGENCY CAFFEINE..."
Enter
Sleep 1s
Type@100ms "✓ Worktree 'created' at ~/.worktrees/001-please-work"
Enter
Type@100ms "  Note: Existence not guaranteed"
Enter
Sleep 2s

# List worktrees
Type "# Let's see what we've got..."
Enter
Sleep 1s

Type "worktrees list"
Enter
Sleep 500ms
Type@100ms "SCANNING FOR SURVIVORS..."
Enter
Sleep 500ms
Type@100ms "╔════════════════════════════════════════════╗"
Enter
Type@100ms "║  ID               STATUS    PATH           ║"
Enter
Type@100ms "╠════════════════════════════════════════════╣"
Enter
Type@100ms "║* 001-please-work  zombie    ~/.worktrees/  ║"
Enter
Type@100ms "║  002-help-me      haunted   ~/.worktrees/  ║"
Enter
Type@100ms "║  003-final-final  cursed    ~/.worktrees/  ║"
Enter
Type@100ms "║  999-the-end      ḩ̸ë̷ḽṕ̶     [REDACTED]     ║"
Enter
Type@100ms "╚════════════════════════════════════════════╝"
Enter
Type@100ms "⚠️  4 worktrees found (3 possibly functional)"
Enter
Sleep 2s

# Try to switch
Type "# Let's switch to a worktree!"
Enter
Sleep 1s

Type "worktrees switch 002-help-me"
Enter
Sleep 500ms
Type@100ms "🎲 Rolling dice for success..."
Enter
Sleep 1s
Type@100ms "🎲 Rolled: 4/20 (Not great, not terrible)"
Enter
Sleep 500ms
Type@100ms "✓ Switched to: 002-help-me"
Enter
Type@100ms "  Current reality: Questionable"
Enter
Type@100ms "  Quantum state: Superposition"
Enter
Sleep 2s

# Status check
Type "# Quick status check..."
Enter
Sleep 1s

Type "worktrees status"
Enter
Sleep 500ms
Type@200ms "CURRENT WORKTREE STATUS:"
Enter
Type@100ms "━━━━━━━━━━━━━━━━━━━━━━"
Enter
Type@100ms "Name:        002-help-me"
Enter
Type@100ms "Health:      74% (↓ declining)"
Enter
Type@100ms "Commits:     Yes"
Enter
Type@100ms "Sanity:      404 Not Found"
Enter
Type@100ms "Last Error:  2 minutes ago"
Enter
Type@100ms "Next Error:  ~30 seconds"
Enter
Sleep 2s

# Try to remove (with multiple confirmations)
Type "# Let's try removing that cursed worktree..."
Enter
Sleep 1s

Type "worktrees remove 999-the-end"
Enter
Sleep 500ms
Type@100ms "⚠️  WARNING: This worktree appears to be sentient"
Enter
Sleep 500ms
Type@100ms "Are you SURE you want to remove '999-the-end'? [y/N]: "
Sleep 500ms
Type "y"
Enter
Sleep 300ms
Type@100ms "Are you REALLY sure? [y/N]: "
Sleep 500ms
Type "y"
Enter
Sleep 300ms
Type@100ms "Like, REALLY REALLY sure? [y/N]: "
Sleep 500ms
Type "Y"
Enter
Sleep 300ms
Type@100ms "Please type 'I accept the consequences': "
Sleep 800ms
Type "I accept the consequences"
Enter
Sleep 1s
Type@100ms "Attempting removal..."
Enter
Sleep 500ms
Type@200ms "."
Sleep 500ms
Type@200ms "."
Sleep 500ms
Type@200ms "."
Enter
Sleep 1s
Type@100ms "❌ ERROR: This worktree has rejected your reality"
Enter
Type@100ms "         and substituted its own"
Enter
Type@100ms "Good luck! 🍀"
Enter
Sleep 2s

# Grand finale
Type "# One more thing..."
Enter
Sleep 1s

Type "worktrees --help"
Enter
Sleep 500ms
Type@100ms "HELP? THERE IS NO HELP"
Enter
Type@100ms "Only worktrees."
Enter
Sleep 1s
Type@100ms ""
Enter
Type@100ms "But if you insist:"
Enter
Type@100ms "  create  - May create a worktree"
Enter
Type@100ms "  list    - Shows some worktrees"
Enter
Type@100ms "  switch  - Quantum leap between realities"
Enter
Type@100ms "  remove  - Attempt to destroy (usually fails)"
Enter
Type@100ms "  status  - Check your sanity levels"
Enter
Type@100ms ""
Enter
Type@100ms "Remember: NNN-kebab-case or the naming"
Enter
Type@100ms "          police will find you 🚔"
Enter
Sleep 3s

Type "# Thanks for watching! Install at your own risk! 💀"
Enter
Sleep 2s