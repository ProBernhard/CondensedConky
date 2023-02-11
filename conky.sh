#!/bin/bash
# Wrote this little script to unify the Conky monitoring on my two different systems (Debian and Fedora), so I won't work with several different scripts. :)

upf() { # Flatpak shenanigans
 flatpak update > /tmp/flatupcheck.txt
 Fstarter=$(wc -l /tmp/flatupcheck.txt | cut -d " " -f 1)
 Foutputter=$(( $Fstarter - 5))
 if [[ "$Foutputter" -le 0 ]]; then
  echo 0
 else
  echo $Foutputter
 fi
}

upa() { # Easy shit for APTitude
 outputterA=$(aptitude search '~U' | wc -l)
 echo $outputterA
}

upd() { # DNF shenanigans
 dnf list updates > /tmp/dnfupcheck.txt 
 Dstarter=$(wc -l /tmp/dnfupcheck.txt | cut -d ' ' -f 1)
 Doutputter=$(( $Dstarter - 2))
 if [[ "$Doutputter" -le 0 ]]; then
  echo 0
 else
  echo $Doutputter
 fi
}

Radio() { #Radiation Monitor
 curl -X GET "https://sfws.lfrz.at/json.php?command=getstationdata&stationcode=AT2002&a=&b=" -H  "accept: application/json" -o /tmp/Radiation.json
 cat /tmp/Radiation.json | grep 'v' | cut -d ':' -f 4 | awk -v FS="," 'BEGIN{OFS=""}{printf "%snSv/h%s",$1, OFS}' | cut -d " " -f 2
 # go to the Strahlenfrühwarnsystem site, fetch the data for the closest station (look it up on their website!) and mangle it out
}

Train() { #Abfahrtsmonitor U3 Ottakring 
 curl -X GET "https://www.wienerlinien.at/ogd_realtime/monitor?stopId=4931&activateTrafficInfo=stoerungkurz" -H  "accept: application/json" -o /tmp/Ottakring.json
 cat /tmp/Ottakring.json | jq -r '.[] | .monitors' | grep 'countdown' | cut -d ':' -f 2 | awk -v FS="," 'BEGIN{OFS=""}{printf "%smin%s",$1, OFS}' | cut -d " " -f 2,3,4
 # 4931 is the stopId of Ottakring U3 (direction SImmering) Cat into the json, mangle it with jq as raw string (all data as an array), select for countdown, grep just the countdowns, cut away the "countdown:" portion, create the output and reduce it with head to just show the upper most 2 (3, as the print command itself needs to be accounted for too)
}

varFetchCoin() { #Fetching the desired Coins from the CoinGecko API with variables (hence the VAR)
 curl -X 'GET' 'https://api.coingecko.com/api/v3/coins/markets?vs_currency=EUR&ids='$1'%2C'$2'%2C'$3'%2C'$4'%2C'$5'%2C'$6'&order=market_cap_desc&per_page=100&page=1&sparkline=false' -H 'accept: application/json' -o /tmp/currentData.json 
 cat /tmp/currentData.json | jq -r '.[] | [.symbol,.current_price] | @csv' | awk -v FS="," 'BEGIN{print}{printf "%s:%s€ ",$1,$2,ORS}'
}

Bluetoothchecker() {
 connections=($(hcitool con | grep -oE "(\w+:){5}\w+"))
 first=true
 device=($(hcitool dev | grep -o -E '(\w+:){5}\w+'))

 hciconfig > /tmp/BT.txt
 Enabler=($(hciconfig | head -n 3 | tail -n 1 | cut -d " " -f 1))
 if [ $Enabler = UP ]; then
  echo "Enabled"
 else 
  echo "Disabled"
 fi

 for i in "${connections[@]}"
 do 
  name=($(hcitool name ${i}))
  echo $name $connections
 done
}

Temp() {
 exec w3m http://www.zamg.ac.at/ogd/tawes1h.csv | grep 11035 | cut -d ";" -f 6 | awk -v FS="," 'BEGIN{OFS=""}{printf "%s,%s°C\n",$1,$2,OS}'
}
# w3m to zamg, grep for Hohe Warte (11035), cut deliminator is semicolon, field number 6 (temperature)

Humid() {
exec w3m http://www.zamg.ac.at/ogd/tawes1h.csv | grep 11035 | cut -d ";" -f 8 | awk -v FS="," 'BEGIN{OFS=""}{printf "%s%%\n",$1}'
} 

Rain() {
exec w3m http://www.zamg.ac.at/ogd/tawes1h.csv | grep 11035 | cut -d ";" -f 13 | awk -v FS="," 'BEGIN{OFS=""}{printf "%sl/m²\n",$1,ORS}'
}

PMX() {
exec w3m https://go.gv.at/l9lumesakt | grep KEND | cut -d ";" -f 15 | awk -v FS="," 'BEGIN{OFS=""}{printf "%s,%sug/m³\n",$1,$2,ORS}'
}

PMY() { 
exec w3m https://go.gv.at/l9lumesakt | grep KEND | cut -d ";" -f 18 | awk -v FS="," 'BEGIN{OFS=""}{printf "%s,%sug/m³\n",$1,$2,ORS}'
}

Ozon() {
exec w3m https://go.gv.at/l9lumesakt | grep ZA | cut -d ";" -f 21 | awk -v FS="," 'BEGIN{OFS=""}{printf "%s,%sug/m³\n",$1,$2,ORS}'
}

Wind() {
exec w3m https://go.gv.at/l9lumesakt | grep KEND | cut -d ";" -f 5 | awk -v FS="," 'BEGIN{OFS=""}{printf "%s,%sm/s\n", $1,$2,ORS}'
# w3m to Stadt Wien Umweltstationen, grep for Kendlerstraße, cut deliminator is semicolon field number 15 (and 18)
}

# If the parameter is empty, or invalid a corresponding return is given, otherwise the corresponding function is called. :)
if [ -z $1 ]; then
 echo NULL 
elif [ $1 = "upf" ]; then
 upf
elif [ $1 = "upa" ]; then
 upa
elif [ $1 = "upd" ]; then
 upd
elif [ $1 = "Radio" ]; then
 Radio
elif [ $1 = "Train" ]; then
 Train
elif [ $1 = "Coin" ]; then
 varFetchCoin $2 $3 $4 $5 $6 $7
elif [ $1 = "Blue" ]; then
 Bluetoothchecker
elif [ $1 = "Temp" ]; then
 Temp
elif [ $1 = "Humid" ]; then
 Humid
elif [ $1 = "Rain" ]; then
 Rain
elif [ $1 = "PMX" ]; then
 PMX
elif [ $1 = "PMY" ]; then
 PMY
elif [ $1 = "Ozon" ]; then
 Ozon
elif [ $1 = "Wind" ]; then
 Wind
else
 echo NOPE
fi