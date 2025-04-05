setxkbmap -layout br
systemctl enable --now NetworkManager.service
exec i3
