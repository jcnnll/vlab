#!/usr/bin/env bash
set -euo pipefail

# Run the recording from the root context
vhs docs/demo/demo.tape

echo "✔ Demo generated: docs/demo/demo.gif"
