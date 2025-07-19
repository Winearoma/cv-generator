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
TMP_DIR=${OUTPUT_DIR}tmp/
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

#Function to build Experience block
build_exp() {
  local tmp=${TMP_DIR}tmp.exp
  [ "$LANG" == "es" ] && AT="en" || AT="at"
  local count=0
  local task_count=0
  local title=""
  local company=""
  local location=""
  local start=""
  local end=""
  local period=""
  local task=""
  local output=""
  count=$(jq '. | length' $tmp)
  for (( i=0; i<count; i++ )); do
    title=$(jq -r ".[$i].title" $tmp)
    company=$(jq -r ".[$i].company" $tmp)
    location=$(jq -r ".[$i].location" $tmp)
    start=$(jq -r ".[$i].startDate" $tmp)
    end=$(jq -r ".[$i].endDate" $tmp)
    period="$start -- $end"
    output+="\\\\textbf{$title} $AT \\\\textit{$company} \\hfill $period\\\\\ $location\n\\\\begin{itemize}[topsep=8pt,itemsep=0pt]\n"
    task_count=$(jq ".[$i].tasks | length" $tmp)
    for (( j=0; j<task_count; j++ )); do
      task=$(jq -r ".[$i].tasks[$j]" $tmp)
      output+="  \\item $task\n"
    done
    output+="\\end{itemize}\n"
  done
  echo "$output"
}
#Function to build Education block
build_edu() {
  local tmp=${TMP_DIR}tmp.edu
  [ "$LANG" == "es" ] && AT="en" || AT="at"
  local count=0
  local output=""
  local degree=""
  local institution=""
  local start=""
  local end=""
  local period=""
  count=$(jq '. | length' $tmp)
  for (( i=0; i<count; i++ )); do
    degree=$(jq -r ".[$i].degree" $tmp)
    institution=$(jq -r ".[$i].institution" $tmp)
    location=$(jq -r ".[$i].location" $tmp)
    start=$(jq -r ".[$i].startDate" $tmp)
    end=$(jq -r ".[$i].endDate" $tmp)
    period="$start -- $end"
    output+="\\\\textbf{$degree} $AT \\\\textit{$institution} \\hfill $period\\\\\ $location \\\\\ "
  done
  echo "$output"
}
#Function to build Skills block
build_sk() {
  local tmp=${TMP_DIR}tmp.sk
  local count=0
  local output=""
  local category=""
  local skillset=""
  count=$(jq '. | length' $tmp)
  for (( i=0; i<count; i++ )); do
    category=$(jq -r ". | keys | nth($i)" $tmp)
    skillset=$(jq ".$category | join(\", \")" $tmp)
    output+="  \\item $category:  $skillset\n"
  done
  echo "$output"
}
#Function to build Languages block
build_lang() {
  local tmp=${TMP_DIR}tmp.lang
  local count=0
  local output=""
  local lang=""
  local proficiency=""
  count=$(jq '. | length' $tmp)
  for (( i=0; i<count; i++ )); do
    lang=$(jq -r ".[$i].language" $tmp)
    proficiency=$(jq -r ".[$i].proficiency" $tmp)
    output+="  \\item $lang ($proficiency)\n"
  done
  echo "$output"
}

#Function to extract plain string from JSON value
extract_plain_string() {
  local tmp="$1"
  local key="$2"
  local var=""
  var=$(jq -r ".${key}" $tmp)
  if [[ -z "$var" ]]; then
    echo "Error: 'contact.${key}' is empty in $JSON_FILE"
    exit 1
  fi
  echo $(escape_latex "$var")
}

#TODO: implement data integrity checks
#Generate tmp section files
jq -c '.experiences' "$JSON_FILE" > ${TMP_DIR}tmp.exp
jq -c '.education' "$JSON_FILE" > ${TMP_DIR}tmp.edu
jq -c '.skills' "$JSON_FILE" > ${TMP_DIR}tmp.sk
jq -c '.languages' "$JSON_FILE" > ${TMP_DIR}tmp.lang
jq -c '.contact' "$JSON_FILE" > ${TMP_DIR}tmp.con

# Generate experience block
EXP_BLOCK=$(build_exp)
# Generate education block
EDU_BLOCK=$(build_edu)
# Generate skills block
SK_BLOCK=$(build_sk)
# Generate languages block
LANG_BLOCK=$(build_lang)

# Copy template to output
cp "$TEMPLATE_FILE" "${OUTPUT_DIR}$TEX"

# Extract contact info
TMP_CON=${TMP_DIR}tmp.con
NAME=$(extract_plain_string "$TMP_CON" "name")
EMAIL=$(extract_plain_string "$TMP_CON" "email")
PHONE=$(extract_plain_string "$TMP_CON" "phone")
LINKEDIN=$(extract_plain_string "$TMP_CON" "linkedin")
SUMMARY=$(extract_plain_string "$JSON_FILE" "summary")

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
  echo "Error: Failed to compile $TEX. Check LaTeX errors in ${OUTPUT_DIR}${TEX%.tex}.log."
  exit 1
fi

# Clean up auxiliary files
rm -f "${OUTPUT_DIR}${TEX%.tex}".{aux,log,out}
