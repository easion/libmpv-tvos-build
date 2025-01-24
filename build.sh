copy_files(){
  sudo cp patches/mpv-tvos.patch /nix/store/${1}/patches/mpv-tvos.patch
  sudo cp cross-files/tvos-arm64.ini /nix/store/${1}/cross-files/tvos-arm64.ini
}

xcode-select -p

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -version

nix-store --add-fixed --recursive sha256 /Applications/Xcode.app
#/nix/store/3h2bira8d73w7xqxh6icdd84w7iq40g5-Xcode.app

sudo mkdir -m 0755 /nix/var/nix/gcroots/per-user/$USER
sudo chown -R $USER /nix/var/nix/gcroots/per-user/$USER
ln -s /nix/store/3h2bira8d73w7xqxh6icdd84w7iq40g5-Xcode.app /nix/var/nix/gcroots/per-user/$USER/xcode-16-2

nix-store --query --hash /nix/store/3h2bira8d73w7xqxh6icdd84w7iq40g5-Xcode.app
# sha256:1mrwyv7ix5fbggay20z4w41s64r33q1nzh3qz37jpp45bhc43k44
nix --extra-experimental-features nix-command hash convert --to base64 sha256:1mrwyv7ix5fbggay20z4w41s64r33q1nzh3qz37jpp45bhc43k44
# hMxBGFyF3CvP+HjAbwMeIxOjA+HkA+HVe8uVHs/2PNc=

nix --extra-experimental-features "nix-command flakes" flake show
nix --extra-experimental-features "nix-command flakes" build -v

rm /nix/var/nix/gcroots/per-user/$USER/xcode-16-2
