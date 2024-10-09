#!/bin/bash

# ANSI escapes
RED='\033[31m'
GREEN='\033[32m'
BOLD='\033[1m'
ITALIC='\033[3m'
STRIKETHROUGH='\033[9m'
RESET='\033[0m'

repeat() {
  for ((i = 1; i < $2; i++)); do
    echo -n "$1"
  done
}

step() {
  echo -e "${BOLD}$1${RESET}" &&
    eval "$2"

  if [ "${PIPESTATUS[0]}" -gt 0 ]; then
    echo -e "${RED}${ITALIC}${STRIKETHROUGH}$1${RESET}${RED} error!${RESET}" &&
      exit 1
  else
    TEXT="${GREEN}${ITALIC}${STRIKETHROUGH}$1${RESET}${GREEN} done!${RESET}"
    echo -e "$TEXT"
  fi

  echo -e "${BOLD}$(repeat "=" "$(echo "$TEXT" | sed -E 's/\\033[^\\]*m//g' | wc -c)")${RESET}"
}

build() {
  step "Creating build directory..." "mkdir -p /tmp/isobuild/airootfs/root"
  step "Adding notes to .zprofile file..." "
		cat <<-EOL >>/tmp/isobuild/airootfs/root/.zprofile
			. /usr/share/makepkg/util/message.sh
			colorize
			echo ''
			msg \"This is an unofficial ISO created by GitHub Actions on $DATE from run ID $GITHUB_RUN_ID\"
			msg2 \"Check $GITHUB_SERVER_URL/$GITHUB_REPOSITORY#readme for more details\"
			echo ''
		EOL
  "
  step "Updating packages and installing archiso..." "pacman -Syu --noconfirm archiso git grub"
  step "Git clone archzfsiso repository from my github..." "git clone --depth 1 https://github.com/hertz-hwang/archzfsiso /tmp/archzfsiso"
  step "Copying releng profile to build directory..." "cp -r /tmp/archzfsiso/* /tmp/isobuild"
  step "Building ISO..." "mkarchiso -v -w work/ -o ./ /tmp/isobuild"
  step "Generating checksums text file..." "
		cat <<-EOL >CHECKSUMS.txt
			b2sum  $(b2sum "archlinux_zfs-$DATE-x86_64.iso")
			md5sum  $(md5sum "archlinux_zfs-$DATE-x86_64.iso")
			sha1sum  $(sha1sum "archlinux_zfs-$DATE-x86_64.iso")
			sha256sum  $(sha256sum "archlinux_zfs-$DATE-x86_64.iso")
		EOL
  "
}

main() {
  if [ -z ${DATE+x} ]; then
    echo -e "${RED}DATE variable not set!${RESET}" &&
      exit 1
  else
    build
  fi
}

main
