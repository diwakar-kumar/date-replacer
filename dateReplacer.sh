#! /bin/bash
set -x; ##uncomment it for debugging on terminal
function usage()
{
	echo "*** ERROR: Invalid arguments."
	echo "Usage: $0 <Inputfile> [Outputfile] <YYYY>"
	echo 
	exit -1
}

# if input file not provided
if [ $# -lt 2 ]; then
	usage
fi

inFileDir=`dirname $1`
currentYear=""
newYear=""

# brief: returns the date of the year passed as argument while keeping the day , month and year same
# args: $inDay: 	date read from file
# 	$outDay: 	day of the same month and same year for the year passed as argument
# 	$outDate:	output date to be calculated
function datecal()
{
	inDay=$1
	outDay=$2 
	outDate=$3
	# month of the output date
	currentMonth=`date -d "$outDate" +%m`
	# year of the output date
	outYear=${outDate:6:4}

	# if newYear is greater than existing year
	if [ "$newYear" -gt "$currentYear"  ]; then
		# calculate previous year, used to check transition of year
		prevYear=$(($newYear-1))
		sign="-1day"
		# loop unless the day of new date becomes the day of the existing date
		while [ $outDay != $inDay ]
		do
			outDate=`date -d "$outDate $sign" +%m/%d/%Y`
			outDay=`date -d "$outDate" +%a`
			outMonth=`date -d "$outDate $sign" +%m`
			# extract year from calculated date
			outYear=${outDate:6:4}
			# if after changing date it becomes the date of input year then increment the date
			if [ "$prevYear" -eq "$outYear" -o  "$currentMonth" -gt "$outMonth" ]; then
				sign="+1day"
				outDate=`date -d "$outDate $sign" +%m/%d/%Y`
				outDay=`date -d "$outDate" +%a`
				outMonth=`date -d "$outDate $sign" +%m`
			fi
			# if after changing date, the new date becomes the date of previous month then increment the date
		done
	else
		# if newYear is less than existing year
		if [ $newYear -lt $currentYear  ]; then
			sign="+1day"
			# calculate next year, used to check transition of year
			nextYear=$(($newYear+1))
		# loop unless the day of new date becomes the day of the existing date
		while [ $outDay != $inDay ]
		do
			outDate=`date -d "$outDate $sign" +%m/%d/%Y`
			outDay=`date -d "$outDate" +%a`
			outMonth=`date -d "$outDate $sign" +%m`
			# extract year from calculated date
			outYear=${outDate:6:4}
			# if after changing date it becomes the date of input year then decrement the date
			if [ "$nextYear" -eq "$outYear" -o "$currentMonth" -lt "$outMonth" ]; then
				sign="-1day"
				outDate=`date -d "$outDate $sign" +%m/%d/%Y`
				outDay=`date -d "$outDate" +%a`
				outMonth=`date -d "$outDate $sign" +%m`
			fi
			# if after changing date, the new date becomes the date of next month then increment the date
		done
		fi
	fi

	# Calculating new date according to input date 
	echo `date -d "$outDate" +%d`.`date -d "$outDate" +%m`.`date -d "$outDate" +%Y`
}

# If No. of arguments is not 3 show usage and exit
if [ $# -eq 3 ]; then
	outfile=$inFileDir/$2
	newYear=$3
else
	if [ $# -eq 2 ]; then
		newYear=$2
		outfile=$inFileDir/${1%.*}_$2.txt
	else
		usage
	fi
fi

# if input file does not exists then print error message and exit
if [ ! -f $1 ]; then
	echo "*** Error: File <$1> does not exists."
	exit -1
fi

# if input file is not readable then print error message and exit
if [ ! -r $1 ]; then
	echo "*** Error: File <$1> is not readable."
	exit -1
fi

# If year of input date and year of output date are same then show message and exit

currentYear=`grep -m 1 "^P.*" $1|sed 's/^P[ ]\+[0-9]\{1,2\}.[0-9]\{1,2\}.//'`
currentYear=${currentYear:0:4}

if [ "$currentYear" == "$newYear" ]; then
	echo
	echo "*** Warning: Year of current date and new date are same...!!!"
	echo
	exit 0
fi

# if output file already exists then prompt user for choice(either replace existing file or input a new output filename)
if [ -f "$outfile" ]; then
	echo "Output file <$outfile>already exists."
	echo "Do you want to replace the file(y\n):"
	read choice
	if [ "$choice" == "y" -o  "$choice" == "Y" ]; then
		rm -f $outfile
	else
		echo "Enter a new filename: "
		read outfile
		outfile=$inFileDir/$outfile
	fi
fi

# Reading file line by line

cat $1|while read line;
do
	# unix date format : MM/DD/YYYY
	# input date format is: DD.MM.YYYY

	# checking each line if it contains the input date
	if echo $line|egrep -q "^P.*"; then
	
		# replacing input format DD.MM.YYYY with MM.DD.YYYY
		tmpline=`echo $line|sed 's/\([0-9]\{1,2\}\)\.\([0-9]\{1,2\}\)\.\([0-9]\{4\}\)/\2\/\1\/\3/'`
		
		#input date in unix format : MM/DD/YYYY
		indate=`echo $tmpline|awk '{print $2; }'` 

		# Extracting input day
		inDay=`date -d $indate +%a` 
		if [ $? == 1 ]; then
			echo "Invalid date.." >> $outfile
			continue	
		fi		

		# Extracting input year
		currentYear=`echo $indate|sed 's/[0-9]\{1,2\}\/[0-9]\{1,2\}\///'`

		# Calculating output date based on input date in unix format
		outDate=`echo $indate|sed "s/[0-9]\{4\}/$newYear/"` 

		# Extracting output day
		outDay=`date -d "$outDate" +%a`

		# If day of input date and day of output date are same then append the line 
		# after modifying the line
		if [ "$inDay" == "$outDay" ]; then
			echo $line|sed "s/\([0-9]\{1,2\}\)\.\([0-9]\{1,2\}\)\.\([0-9]\{4\}\)/$outDate/" >> $outfile
		else

		# If day of input date and day of output date are not same then
		# call the function datecal() with $inDay, $outDay and $outDate as arguments
			tmpdate=`datecal $inDay $outDay $outDate`
			echo $line|sed "s/\([0-9]\{1,2\}\)\.\([0-9]\{1,2\}\)\.\([0-9]\{4\}\)/$tmpdate/" >> $outfile
		fi
	else
		# if line does not contain the date then append it to file as it is
		echo $line >> $outfile		
	fi
done
