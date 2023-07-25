readpass() {
  local password=
  local verification=different
  local algo="${1:?}"
  local target="${2:?}"
  local message="${3:-password ($target)}"
  while [[ $password != "$verification" ]]; do
    echo >&2
    IFS= read -rsp "Enter $message: " password
    echo >&2
    IFS= read -rsp "Repeat $message: " verification
    echo >&2
  done
  if [[ $algo == plain ]]; then
    hashfunc=cat
  else
    hashfunc="mkpasswd -m $algo -s"
  fi
  printf %s "$password" | $hashfunc | sudo bash -c "umask 0377; cat > $target"
}
