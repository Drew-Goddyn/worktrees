# worktrees Demo Recording
# Run with: PATH="./exe:$PATH" vhs vhs/worktrees-demo.tape
#
# Uses the real worktrees executable from exe/ directory

# VHS configuration
Output worktrees-demo.gif
Output worktrees-demo.mp4

Set FontSize 16
Set Width 900
Set Height 600
Set Theme "Dracula"
Set CursorBlink true
Set WindowBar Rings
Set WindowBarSize 40
Set Padding 20
Set TypingSpeed 80ms
Set PlaybackSpeed 1.2

# Start recording
Type "# worktrees - Git worktree management 🚀"
Enter
Sleep 1s

Type "worktrees --version"
Enter
Sleep 1s

Type "clear"
Enter
Sleep 300ms

# Show current status
Type "worktrees status"
Enter
Sleep 1.5s

# List worktrees
Type "worktrees list"
Enter
Sleep 1s

# Create a worktree
Type "worktrees create 001-demo-feature"
Enter
Sleep 2s

# List again
Type "worktrees list"
Enter
Sleep 1.5s

# Switch to it
Type "worktrees switch 001-demo-feature"
Enter
Sleep 2s

# Check status
Type "worktrees status"
Enter
Sleep 1.5s

# Clean up
Type "worktrees remove 001-demo-feature"
Enter
Sleep 500ms
Type "y"
Enter
Sleep 1.5s

Type "# Done! ✨"
Enter
Sleep 1s