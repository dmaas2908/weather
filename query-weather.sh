#!/bin/bash
# Query the weather in LA!

2>/dev/null

export URL='http://api.openweathermap.org/data/2.5/weather?q='
export APIFILE='api.txt'
export APIKEY="\&appid=`tr -d "\n\r" < $APIFILE`"

#first parameter 'f' for Feirenhight 'c' for Celsius
request_la_weather()
{
	if [ -z "$1" -o -z "` echo $1 | grep ^[fFcC] `" ] ; then
		echo 'Error: request_la_weather requires an argument (f or c)'
		exit 1
	fi

	local tmpfile=`mktemp /tmp/laXXXXXXXX`
	local tempmax=0
	local tempmin=0
	local description=""

	curl "$URL"'Los+Angeles,USA'"$APIKEY" 2>/dev/null | sed 's/,/\n/g' | grep -e temp_min -e temp_max -e wind -e description | sed 's/[\{\}\"]//g' > $tmpfile

	#tempmax and min are turned from floats in K to integers in C. Bash builtin math does not do decimals
	description="`cat $tmpfile | grep description | cut -d : -f 2`"
	local i=`cat $tmpfile | grep temp_max | cut -d : -f 2 | cut -d . -f 1 `
	((tempmax=i-273))
	i=`cat $tmpfile | grep temp_min | cut -d : -f 2 | cut -d . -f 1 `
	((tempmin=i-273))

	if [ -z "$description" ] ; then
		echo "Error: Unable to retrieve data from openweather"
		rm -f $tmpfile
		exit 1
	fi
	print_weather "$1" "$description" $tempmax $tempmin

	rm -f $tmpfile #cleanup
}

#first parameter, metric or not metric, 'f' or 'c'
#second argument, weather description
#third argument, temp max in C
#fourth arg, temp min in C
print_weather()
{
	local ismetric=1
	local description=""
	local tempmax=0
	local tempmin=0

        if [ -z "$1" -o -z "` echo $1 | grep ^[fFcC] `" -o -z "$2" -o -z "$3" -o -z "$4" ] ; then
                echo 'Error: print_weather requires four arguments'
                exit 1
        fi

        #figure out if metric temps or not
        if [ -n "`echo $1 | grep -e ^[fF] `" ] ; then
                ismetric=0
        else
                ismetric=1
        fi

	#other fields
	description="$2"
	tempmax="$3"
	tempmin="$4"	

        if [ $ismetric -eq 1 ] ; then
                echo "Weather type is $description, high of $tempmax C, low of $tempmin C"
        else
                echo -n "Weather type is $description, high of "
                echo "$tempmax * 1.8 + 32" | bc | tr '\n' ' '
                echo -n "F, low of "
                echo "$tempmin * 1.8 + 32" | bc | tr '\n' ' '
                echo "F"
        fi
}

check_for_issues()
{
	#api file exists
	if [ ! -e api.txt ] ; then
		echo "Error: Openweather api key not found! Create an account, generate a key, and add it to api.txt without newlines"
		exit 1
	fi

	#api file is the expected size
	local apilen=`wc -c api.txt | awk '{print $1}'`
	if [ $apilen -ne 32 -a $apilen -ne 34 ] ; then
		echo "Error: Api key should be 32 bytes long"
		exit 1 #34 bytes = newline
	fi

	if [ ! -e `which curl` ] ; then
		echo "Error: Curl not found"
		exit 1
	fi
}	

check_for_issues
request_la_weather 'f'
