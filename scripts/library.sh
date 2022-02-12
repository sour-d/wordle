#! /bin/bash

TODAYS_WORD="PAUSE"

# function change_todays_word(){
#   local word="$1"
#   TODAYS_WORD=$word
# }
function string_to_array() {
  local string="$1"

  local arr=( $( sed "s:\(.\)\(.\):\1 \2 :g" <<< ${string} ) )

  echo "${arr[*]}"
}

function generate_attribute() {
  local attribute=$1
  local value=$2
  if [[ -z ${value} ]];
  then
    echo ""
    return
  fi
  echo "${attribute}=\"${value}\""
}

function generate_tag() {
  local tag=$1
  local content="${2}"
  local attributes="${3}"

  echo "<${tag} ${attributes}>${content}</${tag}>"
}

function validate_letter() {
  local letter="$1"
  local position="$2"

  local TODAYS_WORD=( $( string_to_array "$TODAYS_WORD" ) )
  letter=$( tr "[:lower:]" "[:upper:]" <<< $letter )

  if [[ ${TODAYS_WORD[$position]} == ${letter} ]]; then
    return 0
  elif grep -q "$letter" <<< "${TODAYS_WORD[@]}"; then 
    return 1
  else
    return 2
  fi
}

function generate_letter_div(){
  local letter="$1"
  local position="$2"
  local letter_attr_value="letter wrong"
  local validity_status=2 letter_attr="" letter_div=""

  validate_letter $letter $position
  validity_status=$?

  if [[ $validity_status -eq 0 ]]; then
    letter_attr_value="letter right"
  elif [[ $validity_status -eq 1 ]]; then
    letter_attr_value="letter partially-right"
  fi
  letter_attr="$( generate_attribute "class" "$letter_attr_value" )"
  letter_div="$( generate_tag "div" "${letter}" "${letter_attr}" )"
  echo "$letter_div"
}

function create_word_row() {
  local word=$1
  local letters=( $(string_to_array "$word" ) )
  local word_attr="$( generate_attribute "class" "word" )"
  local letter_div="" word_content="" position="0"

  for letter in ${letters[*]}
  do
    letter_div="$( generate_letter_div $letter $position )"
    word_content+="${letter_div}"

    position=$(( $position + 1 ))
  done

  local word_div="$( generate_tag "div" "${word_content}" "${word_attr}" )"
  echo ${word_div}
}

function validate_input(){
  local input="$1"
  if ( grep -q " " <<< "$input" ) || [[ ${#input} != 5 ]] ; then
    return 1
  fi
  return 0
}

function main() {
  local default_row='<div class="word"><div class="letter"></div><div class="letter"></div><div class="letter"></div><div class="letter"></div><div class="letter"></div></div>'
  local template="$( cat ./template/wordle.html )"
  local row=1

  while [[ $row -lt 7 ]]; do
    local word=""
    read -p "Enter your word : " word
    validate_input $word
    local validity_status=$?
    if [[ $validity_status -eq 1 ]]; then
      echo "provide valid input"
      continue
    fi
    local word_rows=$( create_word_row "${word}" )
    template="$( sed "s:__WORD_ROWS${row}__:${word_rows}:" <<< "$template" )"
    local page_content="$( sed "s:__WORD_ROWS.__:${default_row}:g" <<< "$template" )"
    echo "$page_content" > ./html/wordle.html
    open ./html/wordle.html
    row=$(( $row + 1 ))
  done
}
