# worktrees Demo Recording
# Run with: vhs worktrees-demo.tape
# 
# Uses the real worktrees executable from exe/ directory

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
Set TypingSpeed 40ms
Set PlaybackSpeed 1

# PATH will be set when running VHS command

# Start recording
Type "# Welcome to worktrees - Hold on tight! 🎢"
Enter
Sleep 1s

Type "worktrees --version"
Enter
Sleep 2s

Type "clear"
Enter
Sleep 500ms

# Create a worktree
Type "# Let's create a new worktree (fingers crossed! 🤞)"
Enter
Sleep 1s

Type "worktrees create 001-please-work"
Enter
Sleep 6s

# List worktrees
Type "# Let's see what we've got..."
Enter
Sleep 1s

Type "worktrees list"
Enter
Sleep 2.5s

# Try to switch
Type "# Let's switch to a worktree!"
Enter
Sleep 1s

Type "worktrees switch 002-help-me"
Enter
Sleep 3.5s

# Status check
Type "# Quick status check..."
Enter
Sleep 1s

Type "worktrees status"
Enter
Sleep 2s

# Try to remove (with multiple confirmations)
Type "# Let's try removing that cursed worktree..."
Enter
Sleep 1s

Type "worktrees remove 999-the-end"
Enter
Sleep 1s
Type "y"
Enter
Sleep 500ms
Type "y"
Enter
Sleep 500ms
Type "Y"
Enter
Sleep 500ms
Type "I accept the consequences"
Enter
Sleep 4s

# Grand finale
Type "# One more thing..."
Enter
Sleep 1s

Type "worktrees --help"
Enter
Sleep 3s

Type "# Thanks for watching! Install at your own risk! 💀"
Enter
Sleep 2s