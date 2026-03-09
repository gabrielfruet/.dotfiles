#!/bin/bash
# Indexes all knowledge entries by reading their frontmatter
# Run from ~/.dotfiles/opencode/knowledge/

KNOWLEDGE_DIR="$(cd "$(dirname "$0")/../knowledge" && pwd)"

echo "=== Knowledge Index ==="
echo

find "$KNOWLEDGE_DIR" -name "*.md" | sort | while read -r file; do
  # Get relative path from knowledge dir
  rel="${file#$KNOWLEDGE_DIR/}"
  
  # Extract frontmatter (between first --- pairs)
  awk '/^---$/{p=!p; next} p' "$file" | head -10 | sed 's/^/  /'
  
  echo "  file: $rel"
  echo
done
