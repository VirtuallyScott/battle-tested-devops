# ~/.zlogout — Cleanup on shell exit

# Kill all ssh-agent processes owned by the user
if command -v pkill >/dev/null 2>&1; then
  pkill -u "$USER" ssh-agent
else
  killall ssh-agent 2>/dev/null
fi

# Optional: log the logout cleanup
echo "[zlogout] SSH agents terminated at $(date)" >> ~/.zsh_logout.log
