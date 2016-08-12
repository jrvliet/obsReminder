#!/usr/bin/env bash

testing=0

#loc="/home/pi/obs/"
loc="/home/users/jrvander/teaching/obs/"
signup=$loc"campusObs_S16.csv"
contacts=$loc"astroContacts.csv"
objects=$loc"objects.csv"
domain="@nmsu.edu"
weather=$loc"weather-2.0/weather"

# Get today's date
monthNum="$(date +%m)"
month="$(date +%b)"
day="$(date +%e)"
name="$(date +%a)"

# For testing...
if [ "$testing" -eq "1" ]; then
    month="Mar"
    day="25"
    name="Wed"
    year="2016"
fi

if [ $day -lt "10" ]; then
    pat="$name, $month$day"
else
    pat="$name, $month $day"
fi
    
line="$(grep -E "$pat" $signup)"
if [ "$line" == "" ]; then
    echo $pat
    echo 'No obs today'
    #exit 1;
fi

end="end"
fields="$(echo $line | awk -F'"' '{print $3}' | tr ',' ' ')"
dum="$(echo $line | awk -F'"' '{print $3}')"
i=0
for name in $fields; do
    if [[ $name != *Open* ]] && [[ $name != *Closed* ]] && [[ $name != *night* ]] &&  [[ $name != " " ]]; then
        # Find the name in the contacts list
        username="$(fgrep $name $contacts | awk -F',' '{print $1}')"
        email="$username$domain"
        recip[$i]=$email
        i=$((i+1))
    fi

    # Make sure there aren't more than 4 people signed up
    if [ ${#recip[@]} -eq 4 ]; then
        break
    fi
done

# Get the dates of each half to determine what half we are in
firstStart="$(fgrep 'First' $objects | awk -F',' '{print $2}')"
firstEnd="$(fgrep 'First' $objects | awk -F',' '{print $3}')"
secondStart="$(fgrep 'Second' $objects | awk -F',' '{print $2}')"
secondEnd="$(fgrep 'Second' $objects | awk -F',' '{print $3}')"

firstStartYear="$(echo $firstStart | awk -F'/' '{print $1}')"
firstStartMonth="$(echo $firstStart | awk -F'/' '{print $2}')"
firstStartDay="$(echo $firstStart | awk -F'/' '{print $3}')"
secondStartYear="$(echo $secondStart | awk -F'/' '{print $1}')"
secondStartMonth="$(echo $secondStart | awk -F'/' '{print $2}')"
secondStartDay="$(echo $secondStart | awk -F'/' '{print $3}')"

firstEndYear="$(echo $firstEnd | awk -F'/' '{print $1}')"
firstEndMonth="$(echo $firstEnd | awk -F'/' '{print $2}')"
firstEndDay="$(echo $firstEnd | awk -F'/' '{print $3}')"
secondEndYear="$(echo $secondEnd | awk -F'/' '{print $1}')"
secondEndMonth="$(echo $secondEnd | awk -F'/' '{print $2}')"
secondEndDay="$(echo $secondEnd | awk -F'/' '{print $3}')"

# Determine the correct half 
if [ "$testing" -eq "1" ]; then
    currentDate="$(date -d $year-$monthNum-$day +%s)"
else
    currentDate="$(date +%s)"
fi
firstStart="$(date -d $firstStartYear-$firstStartMonth-$firstStartDay +%s)"
firstEnd="$(date -d $firstEndYear-$firstEndMonth-$firstEndDay +%s)"

secondStart="$(date -d $secondStartYear-$secondStartMonth-$secondStartDay +%s)"
secondEnd="$(date -d $secondEndYear-$secondEndMonth-$secondEndDay +%s)"

if [ $currentDate -lt $secondStart ]; then
    half="first"
else
    half="second"
fi

# Get the objects
if [[ "$half" == "first" ]]; then
    south="$(fgrep 'South' $objects | head -1 | awk -F',' '{print $1}')"
    north="$(fgrep 'North' $objects | head -1 | awk -F',' '{print $1}')"
    dob="$(fgrep 'Dob' $objects | head -1 | awk -F',' '{print $1}')"
    const="$(fgrep 'Constellation' $objects | head -1 | awk -F',' '{print $1}')"
else
    south="$(fgrep 'South' $objects | tail -1 | awk -F',' '{print $1}')"
    north="$(fgrep 'North' $objects | tail -1 | awk -F',' '{print $1}')"
    dob="$(fgrep 'Dob' $objects | tail -1 | awk -F',' '{print $1}')"
    const="$(fgrep 'Constellation' $objects | tail -1 | awk -F',' '{print $1}')"
fi

# Check noon phase
phase="$(python /home/users/jrvander/teaching/obs/moonphase.py)"
percent="$(echo $phase | cut -d '(' -f2 | cut -d ')' -f1)"
phase="$(echo $phase | cut -d '(' -f1)"
cutoff=0.625
check="$(echo $percent'<'$cutoff | bc -l)"
if [ "$check" -eq "1" ]; then
    dob=Moon
fi

# Get the weather predictions
fips=3539380
forecast="$(cd $loc/weather-2.0 && ./weather -f fips3539380 | grep -i 'tonight' | tr '[:upper:]' '[:lower:]' | cut -d'.' -f5)"

# Build the message
line[0]="Hello!\n\n"
line[1]="This is a reminder that you are signed up for campus observatory tonight. "
line[2]="\nThe current forecast is: \n\t "$forecast
line[3]="\n\nThe Obs TA will make the call by 8:00 and email you if we are closed. "
line[4]="\nIf you do not hear from the Obs TA, assume we are open. "
line[5]="\nPlease be at the dome by 8:30 with information about the objects:\n\n"
line[6]=$south" (South)\n"
line[7]=$north" (North)\n"
line[8]=$dob" (Dob)\n"
line[9]=$const" (Constellation)\n\n"
#line[10]="Recipients: \n"

body=''
for l in "${line[@]}";do        
    body+=$l
done
#for l in "${recip[@]}";do        
#    body+=$l"\n"
#done


echo -e $body
declare -a testrecip=('karraki@nmsu.edu' 'jrvander@nmsu.edu' 'feuilldk@nmsu.edu')
# Send the message
if [ "$testing" -eq "1" ]; then
    echo -e $body | mail -s "Campus Observatory" jrvliet@gmail.com
else
    echo -e $body | mail -s "Campus Observatory" -b jrvander@nmsu.edu ${recip[@]}
#    echo -e $body | mail -s "Campus Observatory"  jrvander@nmsu.edu 
fi





