#!/bin/bash
# Double-click to start the Chekin guest app demo (works without internet).
cd "$(dirname "$0")" || exit 1
PORT=7900
if curl -s -o /dev/null "http://localhost:$PORT/index.html"; then
  open "http://localhost:$PORT/"
  echo "The demo was already running. Opened it in the browser."
  exit 0
fi
(sleep 1; open "http://localhost:$PORT/") &
exec perl tools/server.pl "$PORT" .
