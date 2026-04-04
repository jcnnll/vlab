Output docs/demo/demo.gif
Set Theme "Catppuccin Mocha"
Set FontSize 22
Set Width 1200
Set Height 600

# Start clean
Hide
Type "clear"
Enter
Show

# Step 1: Navigate to the lab environment
Type "cd example"
Enter
Sleep 1s

# Step 2: Current State (Empty)
Type "vlab status"
Enter
Sleep 3s

# Step 3: Orchestrate the Lab (The Core Feature)
Type "vlab up"
Enter
# This shows the sequential boot: DNS -> Node 01 -> Node 02
# Give it enough time to show the 'limactl' output for each
Sleep 30s

# Step 4: Final Verification
Type "vlab status"
Enter
Sleep 5s

Type "ping -c 3 dns.vlab"
Enter
Sleep 5s

Type "dscacheutil -q host -a name dns.vlab"
Enter
Sleep 3s

# Step 4: Graceful Shutdown
Type "vlab down"
Enter
Sleep 8s
