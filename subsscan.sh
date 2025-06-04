#!/bin/bash

# Comprobamos si se ha pasado el parámetro -d
while getopts ":d:" opt; do
  case $opt in
    d) DOMAIN="$OPTARG"
    ;;
    \?) echo "Uso: $0 -d <dominio>"; exit 1
    ;;
  esac
done

if [ -z "$DOMAIN" ]; then
  echo "Debes especificar un dominio con -d"
  exit 1
fi

TMP_SUBS="subdomains_tmp"
TMP_CLEAN="subdomains_clean_tmp"
FINAL_FILE="subdominios_${DOMAIN}.txt"

curl -s "https://crt.sh/?q=${DOMAIN}&output=json" | \
jq . | grep name | cut -d":" -f2 | grep -v "CN=" | \
cut -d'"' -f2 | awk '{gsub(/\\n/,"\n");}1;' >> "$TMP_SUBS"

curl -s "https://chaos-data.projectdiscovery.io/index.json" | \
jq -r ".[].URL" | grep "$DOMAIN" | while read -r URL; do
  curl -s "$URL" >> "$TMP_SUBS"
done

subfinder -d "$DOMAIN" -all -silent >> "$TMP_SUBS"

sort -u "$TMP_SUBS" | grep -v "@" > "$TMP_CLEAN"
cat "$TMP_CLEAN" | httpx -silent | sed 's~http[s]*://~~g' > "$FINAL_FILE"

rm -f "$TMP_SUBS" "$TMP_CLEAN"

cat $FINAL_FILE

echo ""
echo "[+] $FINAL_FILE creado correctamente"
