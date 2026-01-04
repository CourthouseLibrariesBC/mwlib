#!/usr/bin/env bash
set -euo pipefail

# ===============================================================
# Config
# ===============================================================

BASE_URL="https://dev.wiki.clicklaw.bc.ca"
CATEGORY_URL="$BASE_URL/index.php?title=Category:Books"
USER_AGENT="ClicklawBookFetcher/2.1"

POLL_INTERVAL=10          # seconds between polls
POLL_TIMEOUT=$((30*60))   # give up after 60 minutes

# Optional: where to save PDFs
OUTPUT_DIR="pdfs"
mkdir -p "$OUTPUT_DIR"

# ===============================================================
# Dependencies check
# ===============================================================
for cmd in curl htmlq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

echo "Fetching category page: $CATEGORY_URL"
CATEGORY_HTML=$(curl -fsSL -A "$USER_AGENT" "$CATEGORY_URL")

echo "Parsing collection links..."

# Extract all Clicklaw_Wikibooks:Books/<collection> page titles
mapfile -t COLLECTIONS < <(
  printf '%s\n' "$CATEGORY_HTML" \
    | htmlq -a href 'a[href*="Clicklaw_Wikibooks:Books/"]' \
    | sed -n 's#.*title=Clicklaw_Wikibooks:Books/\(.*\)#\1#p' \
    | sed 's/&.*//' \
    | sort -u
)

if [ "${#COLLECTIONS[@]}" -eq 0 ]; then
  echo "No collections found."
  exit 0
fi

echo "Found ${#COLLECTIONS[@]} collections:"
printf '  - %s\n' "${COLLECTIONS[@]}"
echo

# ===============================================================
# Main loop
# ===============================================================

for COLLECTION in "${COLLECTIONS[@]}"; do
  echo
  echo "=============================================================="
  echo "Processing collection: $COLLECTION"
  echo "=============================================================="

  # URL to TRIGGER the PDF render (job creation)
  RENDER_URL="$BASE_URL/index.php?title=Special:Book&bookcmd=render_collection&colltitle=Clicklaw_Wikibooks:Books/$COLLECTION&writer=rl"

  echo "Triggering render:"
  echo "  $RENDER_URL"

  TMP_HTML=$(mktemp)

  # Trigger the render ONCE and capture the final status URL after redirects
  STATUS_URL=$(
    curl -fsSL -A "$USER_AGENT" \
         -w '%{url_effective}' \
         -o "$TMP_HTML" \
         "$RENDER_URL"
  )

  if [ -z "$STATUS_URL" ]; then
    echo "Warning: could not determine status URL, falling back to render URL."
    STATUS_URL="$RENDER_URL"
  fi

  echo "Status URL:"
  echo "  $STATUS_URL"

  echo "Polling for 'Download the file' link every $POLL_INTERVAL seconds..."

  START_TIME=$(date +%s)
  DOWNLOAD_URL=""
  FIRST=1

  while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if (( ELAPSED > POLL_TIMEOUT )); then
      echo "ERROR: Timed out waiting for render ($POLL_TIMEOUT seconds). Skipping $COLLECTION."
      break
    fi

    # First iteration: reuse HTML from the trigger response.
    # Subsequent iterations: fetch fresh HTML from the status URL.
    if [ "$FIRST" -eq 1 ]; then
      RENDER_HTML=$(cat "$TMP_HTML")
      FIRST=0
    else
      RENDER_HTML=$(curl -fsSL -A "$USER_AGENT" "$STATUS_URL")
    fi

    # ---- NEW: detect render failure ----
    if printf '%s\n' "$RENDER_HTML" | grep -qi "render failed"; then
      echo "ERROR: Render failed for $COLLECTION. Skipping this collection."
      DOWNLOAD_URL=""
      break
    fi
    # -----------------------------------

    # Flatten HTML to one line and extract href of link whose text includes "Download the file"
    DOWNLOAD_PATH=$(
      printf '%s\n' "$RENDER_HTML" \
        | tr '\n' ' ' \
        | sed -n 's/.*<a[^>]*href="\([^"]*\)"[^>]*>[^<]*Download the file[^<]*<.*/\1/p' \
        | head -n 1
    )

    if [ -n "$DOWNLOAD_PATH" ]; then
      case "$DOWNLOAD_PATH" in
        http://*|https://*)
          DOWNLOAD_URL="$DOWNLOAD_PATH"
          ;;
        /*)
          DOWNLOAD_URL="$BASE_URL$DOWNLOAD_PATH"
          ;;
        *)
          DOWNLOAD_URL="$BASE_URL/$DOWNLOAD_PATH"
          ;;
      esac

      echo "Download link detected:"
      echo "  $DOWNLOAD_URL"
      break
    fi

    echo "$(date '+%H:%M:%S'): Still rendering… (elapsed ${ELAPSED}s)"
    sleep "$POLL_INTERVAL"
  done

  rm -f "$TMP_HTML"

  if [ -z "${DOWNLOAD_URL:-}" ]; then
    echo "Skipping download for $COLLECTION (no download URL)."
    continue
  fi

  OUT_FILE="${OUTPUT_DIR}/${COLLECTION}.pdf"
  echo "Downloading PDF to $OUT_FILE..."
  if curl -fSL -A "$USER_AGENT" -o "$OUT_FILE" "$DOWNLOAD_URL"; then
    echo "Saved: $OUT_FILE"
  else
    echo "ERROR: failed downloading $OUT_FILE"
  fi
done

echo
echo "============================================"
echo "All done."
echo "============================================"

