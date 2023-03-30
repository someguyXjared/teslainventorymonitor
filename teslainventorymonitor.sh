#!/bin/bash
# teslainventory monitor.sh - Monitors a Tesla inventory records for changes
# This will monitor new SIMPLE inventory requests
# This will NOT monitor Rear Wheel Drive, Long Range, or Performance
# Sends an email notification if the file change
# github: https://github.com/someguyXjared/
# Created: 3/10/2023

echo "Please update your ZIP and Lat/Lng variables prior to 1st run"
echo "Enter your email: (default gmail)"
read user_var
echo "Enter your password:"
echo "Create an App Password with GMAIL: https://support.google.com/accounts/answer/185833?hl=en"
read -s pass_var


# If you want static just update items below
# user_var="changeme@gmail.com"
# pass_var="not recommended"
model_var="y" # choose 1: s, 3, x, or y - must be lowercase

###### CABIN_CONFIG - MS and M3 no options - MX - 5,6,7 MY - 5,7 
seats_var="FIVE" # choose 1: FIVE, SIX, or SEVEN must be UPPERCASE
# ############IMPORTANT################
# If you choose cabin config, use URL2 and Email2 for Email notifications

zip_var="85001"
#### Use this site for LAT/LNG https://www.freemaptools.com/convert-us-zip-code-to-lat-lng.htm
lat_var="33.4483" # must include 4 decimals
lng_var="-112.0740" # must include 4 decimals

#Does not contain CABIN_CONFIG
URL1="https://www.tesla.com/inventory/api/v1/inventory-results?query=%7B%22query%22%3A%7B%22model%22%3A%22m$model_var%22%2C%22condition%22%3A%22new%22%2C%22arrangeby%22%3A%22Price%22%2C%22order%22%3A%22asc%22%2C%22market%22%3A%22US%22%2C%22language%22%3A%22en%22%2C%22super_region%22%3A%22north+america%22%2C%22lng%22%3A$lng_var%2C%22lat%22%3A$lat_var%2C%22zip%22%3A%22$zip_var%22%2C%22range%22%3A200%7D%2C%22offset%22%3A0%2C%22count%22%3A50%2C%22outsideOffset%22%3A0%2C%22outsideSearch%22%3Afalse%7D"

# Contains CABIN_CONFIG
URL2="https://www.tesla.com/inventory/api/v1/inventory-results?query=%7B%22query%22%3A%7B%22model%22%3A%22m$model_var%22%2C%22condition%22%3A%22new%22%2C%22options%22%3A%7B%22CABIN_CONFIG%22%3A%5B%22$seats_var%22%5D%7D%2C%22arrangeby%22%3A%22Price%22%2C%22order%22%3A%22asc%22%2C%22market%22%3A%22US%22%2C%22language%22%3A%22en%22%2C%22super_region%22%3A%22north+america%22%2C%22lng%22%3A$lng_var%2C%22lat%22%3A$lat_var%2C%22zip%22%3A%22$zip_var%22%2C%22range%22%3A200%7D%2C%22offset%22%3A0%2C%22count%22%3A50%2C%22outsideOffset%22%3A0%2C%22outsideSearch%22%3Afalse%7D"

#Does not contain CABIN_CONFIG
Email1="https://tesla.com/inventory/new/m$model_var?arrangeby=plh&zip=$zip_var&range=200"

# Contains CABIN_CONFIG
Email2="https://tesla.com/inventory/new/m$model_var?CABIN_CONFIG=$seats_var&arrangeby=plh&zip=$zip_var&range=200"

##### IF there are too many in inventory,
##### you will get "Argument list too long"
##### narrow your search or try again later
##### or lower your radius 200, 100, 50, 25 miles
##### find and replace all 200 options, there are 4

for (( ; ; )); do
    mv model$model_var.new.txt model$model_var.old.txt 2> /dev/null
    curl $URL1 -L --compressed -s > model$model_var.new.txt
    DIFF_OUTPUT="$(diff model$model_var.new.txt model$model_var.old.txt)"
    if [ "0" = "${#DIFF_OUTPUT}" ]; then
        dt=$(date)
        echo "No Change $dt" >> model$model_var.log
        sleep 600 # wait X seconds
    fi
    if [ "0" != "${#DIFF_OUTPUT}" ]; then
        dt=$(date)
        sendEmail -f $user_var -s smtp.gmail.com:587 \
            -xu $user_var -xp $pass_var -t $user_var \
            -o tls=yes -u "Tesla Inventory Changed" \
            -m "Inventory Change. Go to: $Email1 \n \n Visit it at and the difference is \n $DIFF_OUTPUT" \
            -a model$model_var.old.txt model$model_var.old.txt
        echo "Email sent $dt to $user_var" >> model$model_var.log
        sleep 600 
    fi
done

