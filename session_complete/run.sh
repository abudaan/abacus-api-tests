#!/bin/bash
set -euo pipefail

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P )
backend_dir=${ABACUS_BACKEND:-$script_dir/../../backend}
base=http://localhost:8080

# Cleanup previous results
rm -rf "$script_dir/output"
mkdir "$script_dir/output"

# Separate database so the reset doesn't wipe the regular dev db.sqlite
# (relative to backend/, ignored by backend/.gitignore)
test_db=api-test.sqlite

if curl -s -o /dev/null "$base"; then
#   echo "Something is already running on $base, stop it first" >&2
#   exit 1
    echo "Something is already running on $base, stop it first"
    kill -9 $(lsof -t -i :8080)
fi

(cd "$backend_dir" && exec cargo run -- --database "$test_db" --reset-database) \
  > "$script_dir/server.log" 2>&1 &
server_pid=$!

[[ "${KEEP_SERVER:-}" == 1 ]] || trap 'kill $server_pid 2>/dev/null || true' EXIT

for _ in $(seq 1 60); do
  curl -s -o /dev/null "$base" && break
  kill -0 $server_pid 2>/dev/null || { echo "Server exited, see server.log" >&2; exit 1; }
  sleep 0.5
done
curl -s -o /dev/null "$base" || { echo "Server did not start in time, see server.log" >&2; exit 1; }

# httpyac only accepts files below its cwd, so run from api-test/
cd "$script_dir/.."

httpyac send \
  setup/create_users.http \
  setup/create_election.http \
  session_complete/test.http \
  --all --bail --output short --output-failed exchange


unzip -q -d "$script_dir/output/results-1" "$script_dir/output/results-1.zip"
unzip -q -d "$script_dir/output/results-2" "$script_dir/output/results-2.zip"

chmod 644 "$script_dir/output/results-1/Model_Na31-1.pdf"
chmod 644 "$script_dir/output/results-2/Model_Na31-1.pdf"

pdf_crc1=$(crc32 "$script_dir/output/results-1/Model_Na31-1.pdf")
pdf_crc2=$(crc32 "$script_dir/output/results-2/Model_Na31-1.pdf")

echo $pdf_crc1
echo $pdf_crc2

if [ "$pdf_crc1" = "$pdf_crc2" ]; then
  echo "Generated PDF has not been updated!"
fi