#!/bin/bash

# -------------------------------
# Repo directory
# -------------------------------
REPO_DIR="$HOME/JavaScript-Learning"
cd "$REPO_DIR" || { echo "Repo folder not found!"; exit 1; }

# -------------------------------
# Ask for folder
# -------------------------------
read -p "Enter folder name (01_basic, 02_arrays, or new): " folder
FOLDER_PATH="$REPO_DIR/$folder"
mkdir -p "$FOLDER_PATH"

# -------------------------------
# Ask for file name
# -------------------------------
read -p "Enter file name (without extension): " filename

# -------------------------------
# Ask for file type
# -------------------------------
read -p "File type? (js/html): " filetype
FILE_PATH="$FOLDER_PATH/$filename.$filetype"

# -------------------------------
# Create file and open editor
# -------------------------------
nano "$FILE_PATH"

# -------------------------------
# Update README.md
# -------------------------------
DATE=$(date +"%Y-%m-%d")
README="$REPO_DIR/README.md"

# Ensure README exists
if [ ! -f "$README" ]; then
    echo "# 🧠 JavaScript Learning Journey 🚀" > "$README"
fi

# -------------------------------
# 1. Add badges
# -------------------------------
EXAMPLE_COUNT=$(find "$REPO_DIR" -type f -name "*.js" -o -name "*.html" | wc -l)
LAST_UPDATE=$(date +"%Y-%m-%d")
sed -i "2i ![Last Updated](https://img.shields.io/badge/Last%20Updated-$LAST_UPDATE-blue)\n![Examples](https://img.shields.io/badge/Examples-$EXAMPLE_COUNT-green)" "$README"

# -------------------------------
# 2. Ensure daily summary section exists
# -------------------------------
if ! grep -q "## 📅 Daily Summary" "$README"; then
    echo -e "\n## 📅 Daily Summary\n" >> "$README"
fi

# -------------------------------
# 3. Update daily summary
# -------------------------------
if grep -q "$DATE.*$folder" "$README"; then
    sed -i "/$DATE.*$folder/ s/$/ , '$filename'/" "$README"
else
    echo "- $DATE [$folder]: '$filename'" >> "$README"
fi

# -------------------------------
# 4. Update folder section
# -------------------------------
if ! grep -q "## $folder" "$README"; then
    echo -e "\n## $folder 📁\n<a name=\"$folder\"></a>" >> "$README"
    echo "| Date | Example |" >> "$README"
    echo "|------|--------|" >> "$README"
fi

# Add new entry to folder table
echo "| <span style=\"color:green\">$DATE</span> | 📄 [$filename](#$folder-$filename) |" >> "$README"

# Sort folder table alphabetically by example
awk -v folder="$folder" '
BEGIN {print_flag=0}
/## '"$folder"'/{print_flag=1; print; next}
/## /{if(print_flag){print_flag=0}}
{if(print_flag) print}
' "$README" > folder_table.tmp
head -n 2 folder_table.tmp > header.tmp
tail -n +3 folder_table.tmp | sort -k3 > body.tmp
cat header.tmp body.tmp > folder_table_sorted.tmp

awk -v folder="$folder" '
BEGIN {print_flag=0}
/## '"$folder"'/{print_flag=1; print; getline; getline; next}
/## /{if(print_flag){print_flag=0}}
{print}
' "$README" > tmp_readme.tmp

sed -i "/## $folder/r folder_table_sorted.tmp" tmp_readme.tmp
sed -i "/## $folder/,/## /{//!d}" tmp_readme.tmp
mv tmp_readme.tmp "$README"

# -------------------------------
# 5. Add code snippet with motivational banner
# -------------------------------
ANCHOR_NAME="${folder}-${filename}"
echo -e "\n### 🧩 $filename Example ($folder)\n<a name=\"$ANCHOR_NAME\"></a>\n<!-- 🔥 Keep going! You coded this on $DATE 🔥 -->" >> "$README"
if [ "$filetype" == "js" ]; then
    echo '```js' >> "$README"
else
    echo '```html' >> "$README"
fi
cat "$FILE_PATH" >> "$README"
echo '```' >> "$README"

# -------------------------------
# 6. Generate clickable, sorted index table
# -------------------------------
INDEX_HEADER="## 📑 Index of Examples"
INDEX_CONTENT="| Folder | Examples Count |\n|--------|----------------|"
for f in $(ls -1d */ | sort); do
    folder_name=$(basename "$f")
    count=$(find "$f" -maxdepth 1 -type f | wc -l)
    INDEX_CONTENT="$INDEX_CONTENT\n| [$folder_name](#$folder_name) | $count |"
done

# Remove old index and insert new
if grep -q "## 📑 Index of Examples" "$README"; then
    sed -i '/## 📑 Index of Examples/,/## 📅 Daily Summary/d' "$README"
fi
sed -i "3i $INDEX_HEADER\n$INDEX_CONTENT\n" "$README"

# -------------------------------
# 7. Generate Table of Contents (TOC) with emojis
# -------------------------------
TOC_HEADER="## 🗂️ Table of Contents"
TOC_CONTENT=""
for f in $(ls -1d */ | sort); do
    folder_name=$(basename "$f")
    TOC_CONTENT="$TOC_CONTENT\n- 📁 [$folder_name](#$folder_name)"
    for ex in $(ls "$f" | sort); do
        ex_name="${ex%.*}"
        TOC_CONTENT="$TOC_CONTENT\n  - 📄 [$ex_name](#$folder_name-$ex_name)"
    done
done

# Remove old TOC and insert new
if grep -q "## 🗂️ Table of Contents" "$README"; then
    sed -i '/## 🗂️ Table of Contents/,/## 📑 Index of Examples/d' "$README"
fi
sed -i "2i $TOC_HEADER\n$TOC_CONTENT\n" "$README"

# -------------------------------
# 8. Git add, commit, push
# -------------------------------
git add .
git commit -m "Add $filename example with dashboard, badges, TOC, motivational banner"
git push

echo "✅ Example '$filename.$filetype' added with full interactive dashboard and pushed!"
