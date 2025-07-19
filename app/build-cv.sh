#!/bin/bash

# Exit on errors
set -e

# Default language
LANG="en"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --lang)
      if [[ "$2" == "en" || "$2" == "es" ]]; then
        LANG="$2"
      else
        echo "Error: --lang must be 'en' or 'es'"
        exit 1
      fi
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

# File paths
JSON_FILE="./data/aboutMe-$LANG.json"
TEMPLATE_FILE="./templates/template-$LANG.tex"
TEX="cv-$LANG.tex"
OUTPUT_DIR="./output/"
PDF="cv-$LANG.pdf"
TMP_DIR=${OUTPUT_DIR}/tmp/
mkdir -p ${TMP_DIR}

# Check dependencies
command -v jq >/dev/null 2>&1 || { echo "Error: 'jq' is required but not installed."; exit 1; }
command -v pdflatex >/dev/null 2>&1 || { echo "Error: 'pdflatex' is required but not installed."; exit 1; }

# Check if JSON file exists
if [[ ! -f "$JSON_FILE" ]]; then
  echo "Error: JSON file '$JSON_FILE' not found."
  exit 1
fi

# Check if template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "Error: Template file '$TEMPLATE_FILE' not found."
  exit 1
fi

# Ensure Unix line endings in template
#sed -i 's/\r$//' "$TEMPLATE_FILE"

# Function to escape LaTeX special characters and handle non-ASCII
escape_latex() {
  local input="$1"
  # Convert to UTF-8, escape special characters, and remove newlines
  echo -n "$input" | sed -e 's/&/\\\&/g' -e 's/%/\\%/g' -e 's/#/\\#/g' -e 's/{/\\{/g' -e 's/}/\\}/g' -e 's/~/\\~/g' -e 's/\\/\\textbackslash{}/g' -e 's/\n//g'
}

#TODO: implement data integrity checks
#Generate tmp section files

echo "--test--67"
echo ${TMP_DIR}tmp.exp


jq -c '.experiences' "$JSON_FILE" > ${TMP_DIR}tmp.exp
jq -c '.education' "$JSON_FILE" > ${TMP_DIR}tmp.edu
jq -c '.skills' "$JSON_FILE" > ${TMP_DIR}tmp.sk
jq -c '.languages' "$JSON_FILE" > ${TMP_DIR}tmp.lang
jq -c '.contact' "$JSON_FILE" > ${TMP_DIR}tmp.con

# Generate experience block
EXP_BLOCK=""
TMP_EXP=${TMP_DIR}tmp.exp
count=$(jq '. | length' $TMP_EXP)
for (( i=0; i<count; i++ )); do
  TITLE=$(jq -r ".[$i].title" $TMP_EXP)
  COMPANY=$(jq -r ".[$i].company" $TMP_EXP)
  LOCATION=$(jq -r ".[$i].location" $TMP_EXP)
  START=$(jq -r ".[$i].startDate" $TMP_EXP)
  END=$(jq -r ".[$i].endDate" $TMP_EXP)
  PERIOD="$START -- $END"
  EXP_BLOCK+="\\\\textbf{$TITLE} at \\\\textit{$COMPANY} \\hfill $PERIOD\\\\\ $LOCATION\n\\\\begin{itemize}[topsep=8pt,itemsep=0pt]\n"
  task_count=$(jq ".[$i].tasks | length" $TMP_EXP)
  for (( j=0; j<task_count; j++ )); do
    TASK=$(jq -r ".[$i].tasks[$j]" $TMP_EXP)
    EXP_BLOCK+="  \\item $TASK\n"
  done
  EXP_BLOCK+="\\end{itemize}\n"
done
# Generate education block
EDU_BLOCK=""
TMP_EDU=${TMP_DIR}tmp.edu
count=$(jq '. | length' $TMP_EDU)
for (( i=0; i<count; i++ )); do
  DEGREE=$(jq -r ".[$i].degree" $TMP_EDU)
  INSTITUTION=$(jq -r ".[$i].institution" $TMP_EDU)
  LOCATION=$(jq -r ".[$i].location" $TMP_EDU)
  START=$(jq -r ".[$i].startDate" $TMP_EDU)
  END=$(jq -r ".[$i].endDate" $TMP_EDU)
  PERIOD="$START -- $END"
  EDU_BLOCK+="\\\\textbf{$DEGREE} at \\\\textit{$INSTITUTION} \\hfill $PERIOD\\\\\ $LOCATION\n"
done
# Generate skills block
SK_BLOCK=""
TMP_SK=${TMP_DIR}tmp.sk
count=$(jq '. | length' $TMP_SK)
for (( i=0; i<count; i++ )); do
  CATEGORY=$(jq -r ". | keys | nth($i)" $TMP_SK)
  SKILLSET=$(jq ".$CATEGORY | join(\", \")" $TMP_SK)
  SK_BLOCK+="  \\item $CATEGORY:  $SKILLSET\n"
done
# Generate languages block
LANG_BLOCK=""
TMP_LANG=${TMP_DIR}tmp.lang
lang_count=$(jq '. | length' $TMP_LANG)
for (( i=0; i<lang_count; i++ )); do
  LANGUAGE=$(jq -r ".[$i].language" $TMP_LANG)
  PROFICIENCY=$(jq -r ".[$i].proficiency" $TMP_LANG)
  LANG_BLOCK+="  \\item $LANGUAGE ($PROFICIENCY)\n"
done

# Copy template to output
cp "$TEMPLATE_FILE" "${OUTPUT_DIR}$TEX"

# Extract contact info
TMP_CON=${TMP_DIR}tmp.con
NAME=$(jq -r '.name' $TMP_CON)
if [[ -z "$NAME" ]]; then
  echo "Error: 'contact.name' is empty in $JSON_FILE"
  exit 1
fi
NAME=$(escape_latex "$NAME")

EMAIL=$(jq -r '.email' $TMP_CON)
if [[ -z "$EMAIL" ]]; then
  echo "Error: 'contact.email' is empty in $JSON_FILE"
  exit 1
fi
EMAIL=$(escape_latex "$EMAIL")

PHONE=$(jq -r '.phone' $TMP_CON)
if [[ -z "$PHONE" ]]; then
  echo "Error: 'contact.phone' is empty in $JSON_FILE"
  exit 1
fi
PHONE=$(escape_latex "$PHONE")

LINKEDIN=$(jq -r '.linkedin' $TMP_CON)
if [[ -z "$LINKEDIN" ]]; then
  echo "Error: 'contact.linkedin' is empty in $JSON_FILE"
  exit 1
fi
LINKEDIN=$(escape_latex "$LINKEDIN")

SUMMARY=$(jq -r '.summary' $JSON_FILE)
if [[ -z "$SUMMARY" ]]; then
  echo "Error: 'summary' is empty in $JSON_FILE"
  exit 1
fi
SUMMARY=$(escape_latex "$SUMMARY")

#Clean tmp files
rm -rf $TMP_DIR

# Replace placeholders
sed -i \
  -e "s|{{name}}|$NAME|g" \
  -e "s|{{email}}|$EMAIL|g" \
  -e "s|{{phone}}|$PHONE|g" \
  -e "s|{{linkedin}}|$LINKEDIN|g" \
  -e "s|{{summary}}|$SUMMARY|g" \
  "${OUTPUT_DIR}$TEX"

# Append experience block (replace {% for job in experience %}...{% endfor %})
awk -v expBlock="$(sed 's/\(.*\)\\n/\1/' <<< $EXP_BLOCK)" '
  BEGIN {skip=0}
  /{% for job in experience %}/ {skip=1; print expBlock; next}
  /{% endfor experience %}/ {skip=0; next}
  skip==0 {print}
' "${OUTPUT_DIR}$TEX" > tmp.tex && cp tmp.tex "${OUTPUT_DIR}$TEX"

# Append languages block (replace {% for lang in languages %}...{% endfor %})
awk -v langBlock="$(sed 's/\(.*\)\\n/\1/' <<< $LANG_BLOCK)" '
  BEGIN {skip=0}
  /{% for lang in languages %}/ {skip=1; print langBlock; next}
  /{% endfor languages %}/ {skip=0; next}
  skip==0 {print}
' "${OUTPUT_DIR}$TEX" > tmp.tex && mv tmp.tex "${OUTPUT_DIR}$TEX"

# Append education block (replace {% for ed in education %}...{% endfor %})
awk -v eduBlock="$(sed 's/\(.*\)\\n/\1/' <<< $EDU_BLOCK)" '
  BEGIN {skip=0}
  /{% for ed in education %}/ {skip=1; print eduBlock; next}
  /{% endfor education %}/ {skip=0; next}
  skip==0 {print}
' "${OUTPUT_DIR}$TEX" > tmp.tex && mv tmp.tex "${OUTPUT_DIR}$TEX"

# Append skills block (replace {% for skillset in skills %}...{% endfor %})
awk -v skBlock="$(sed 's/\(.*\)\\n/\1/' <<< $SK_BLOCK)" '
  BEGIN {skip=0}
  /{% for skillset in skills %}/ {skip=1; print skBlock; next}
  /{% endfor skills %}/ {skip=0; next}
  skip==0 {print}
' "${OUTPUT_DIR}$TEX" > tmp.tex && mv tmp.tex "${OUTPUT_DIR}$TEX"

# Compile LaTeX to PDF
if pdflatex -interaction=nonstopmode -output-directory=$OUTPUT_DIR "${OUTPUT_DIR}$TEX"; then
  echo "Generated $PDF successfully. You can find this file along with the .tex file used to generate it in the output folder."
else
  echo "Error: Failed to compile $OUTPUT_TEX. Check LaTeX errors in ${OUTPUT_TEX%.tex}.log."
  exit 1
fi

# Clean up auxiliary files
rm -f "${OUTPUT_DIR}${TEX%.tex}".{aux,log,out}
