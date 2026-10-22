#!/bin/bash
# Restore Lucisword's Arch + Hyprland setup. Run as a normal user on a fresh Arch install.
set -uo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
ask() { read -rp "$1 [y/N] " a; [[ "$a" =~ ^[Yy]$ ]]; }
say() { printf '\n==> %s\n' "$*"; }
need_initrd=1; need_grub=0

[ "$EUID" -ne 0 ] || { echo "Run as your normal user, not root."; exit 1; }
[ -f /etc/arch-release ] || { echo "Arch Linux only."; exit 1; }
[ "$USER" = "lucifer" ] || echo "WARNING: configs reference /home/lucifer; your user is $USER."
echo "This will upgrade the system, install packages, restore configs and enable services."
ask "Continue?" || exit 0
sudo -v

say "Full system upgrade"
sudo pacman -Syu || { echo "Upgrade failed, fix mirrors/network first."; exit 1; }

say "Official packages"
avail=$(comm -12 <(sort "$REPO/packages/pacman.txt") <(pacman -Slq | sort))
missing=$(comm -23 <(sort "$REPO/packages/pacman.txt") <(pacman -Slq | sort))
[ -n "$missing" ] && { echo "Not in repos (skipped):"; echo "$missing"; }
mapfile -t pk <<<"$avail"
sudo pacman -S --needed "${pk[@]}"

say "AUR packages"
aur=$(grep -vE '^yay(-bin|-debug)?$' "$REPO/packages/aur.txt" || true)
if [ -n "$aur" ]; then
  if ! command -v yay >/dev/null; then
    sudo pacman -S --needed base-devel git
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" && (cd "$tmp/yay-bin" && makepkg -si)
  fi
  mapfile -t ap <<<"$aur"
  yay -S --needed "${ap[@]}"
fi

say "Home configs (overwritten files are kept as *.pre-restore)"
rsync -rL --backup --suffix=.pre-restore "$REPO/home/" "$HOME/"
chmod +x "$HOME"/.local/bin/* 2>/dev/null

say "System files"
sudo rsync -rL --backup --suffix=.pre-restore --no-perms --no-owner --no-group "$REPO/system/" /
( cd "$REPO/system" && find . -type f ) | while read -r f; do
  sudo chmod 644 "/${f#./}"; sudo chown root:root "/${f#./}"
done
sudo systemctl daemon-reload; sudo udevadm control --reload; sudo systemd-tmpfiles --create

say "Services"
while read -r u; do [ -n "$u" ] && { sudo systemctl enable "$u" >/dev/null 2>&1 && echo "enabled $u" || echo "skipped $u"; }; done < "$REPO/packages/services-system.txt"
while read -r u; do [ -n "$u" ] && { systemctl --user enable "$u" >/dev/null 2>&1 && echo "enabled (user) $u" || echo "skipped (user) $u"; }; done < "$REPO/packages/services-user.txt"

say "Hibernate: swap detection"
swapdev=$(sudo blkid -t TYPE=swap -o device | grep -v zram | head -1 || true)
if [ -z "$swapdev" ]; then
  echo "No swap partition found, skipping hibernate."
else
  uuid=$(sudo blkid -s UUID -o value "$swapdev")
  echo "Found swap: $swapdev  UUID=$uuid  size=$(lsblk -no SIZE "$swapdev")  RAM=$(free -h | awk '/Mem:/{print $2}')"
  echo "Hibernate needs swap at least as large as RAM."
  if ask "Use it for hibernate (adds resume= and the resume hook)?"; then
    if grep -qE '^HOOKS=.*systemd' /etc/mkinitcpio.conf; then
      echo "systemd-based initramfs detected, skipping hook (needs manual setup)."
    elif ! grep -qE '^HOOKS=.*\bresume\b' /etc/mkinitcpio.conf; then
      sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak
      sudo sed -i -E '/^HOOKS=/ s/\bfilesystems\b/resume filesystems/' /etc/mkinitcpio.conf
    fi
    if [ -f /etc/kernel/cmdline ]; then
      grep -q 'resume=' /etc/kernel/cmdline || { sudo cp /etc/kernel/cmdline /etc/kernel/cmdline.bak; sudo sed -i "1 s|\$| resume=UUID=$uuid|" /etc/kernel/cmdline; }
    elif [ -f /etc/default/grub ]; then
      grep -q 'resume=' /etc/default/grub || { sudo cp /etc/default/grub /etc/default/grub.bak; sudo sed -i "s|^\(GRUB_CMDLINE_LINUX_DEFAULT=\".*\)\"|\1 resume=UUID=$uuid\"|" /etc/default/grub; need_grub=1; }
    else
      echo "No kernel command line file found; add resume=UUID=$uuid manually."
    fi
  fi
fi

say "Shared NTFS drive"
if grep -q ' /mnt/shared ' /etc/fstab; then
  echo "/mnt/shared already in fstab."
else
  mapfile -t parts < <(lsblk -rno UUID,FSTYPE,SIZE,NAME,LABEL | awk '$2=="ntfs"')
  if [ "${#parts[@]}" -eq 0 ]; then echo "No NTFS partitions found."; else
    echo "NTFS partitions (pick your DATA partition, NOT Windows C:):"
    for i in "${!parts[@]}"; do echo "  $((i+1))) ${parts[$i]}   (UUID SIZE NAME LABEL)"; done
    read -rp "Number (empty = skip): " n
    if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#parts[@]}" ]; then
      u=$(awk '{print $1}' <<<"${parts[$((n-1))]}")
      line="UUID=$u /mnt/shared ntfs3 uid=$(id -u),gid=$(id -g),umask=022,nofail,x-systemd.automount 0 0"
      echo "Will append to /etc/fstab:"; echo "  $line"
      if ask "Add it?"; then
        sudo mkdir -p /mnt/shared; sudo cp /etc/fstab /etc/fstab.bak
        echo "$line" | sudo tee -a /etc/fstab >/dev/null
        sudo systemctl daemon-reload; sudo systemctl start mnt-shared.automount; ls /mnt/shared | head -5
      fi
    fi
  fi
fi

say "Rebuilding kernel images"
sudo mkinitcpio -P
[ "$need_grub" = 1 ] && sudo grub-mkconfig -o /boot/grub/grub.cfg

cat <<'NOTE'

Done. Manual steps left (secrets are never stored in this repo):
  1. ssh-keygen -t ed25519 -C "<your email>"   then   gh auth login   and   gh ssh-key add ~/.ssh/id_ed25519.pub
  2. git config --global user.name / user.email
  3. Sign in to browsers and VS Code sync
  4. Check boot entries: sudo efibootmgr  (GRUB first, Windows second)
  5. Reboot
NOTE
