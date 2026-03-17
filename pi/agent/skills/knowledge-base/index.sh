#!/bin/bash
# Indexes all knowledge entries by reading their frontmatter

KNOWLEDGE_DIR="$HOME/.dotfiles/pi/agent/knowledge"

if [ ! -d "$KNOWLEDGE_DIR" ]; then
  echo "Error: knowledge directory not found at $KNOWLEDGE_DIR"
  exit 1
fi

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
