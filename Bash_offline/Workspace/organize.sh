#!/usr/bin/bash


if [ "$#" -lt 4 ]; then
    echo "Usage: ./organize.sh submissions targets tests answers"
    exit 1
fi



target=$2
submission=$1
test=$3
answer=$4

vervose=0
noexecute=0
nolc=0
nofc=0
nocc=0

all_args="$*"


for i in $all_args; do
	if [[ $i == "-v" ]]; then
		verbose=$((verbose+1))
	fi
	if [[ $i == "-noexecute" ]]; then
		noexecute=$((noexecute+1))
	fi
	if [[ $i == "-nolc" ]]; then
		nolc=$((nolc+1))
	fi
	if [[ $i == "-nofc" ]]; then
		nofc=$((nofc+1))
	fi
	if [[ $i == "-nocc" ]]; then
		nocc=$((nocc+1))
	fi
done


if [[ -d $target ]]; then
	rm -r $target
fi


if [[ -d $submission/unzipped ]]; then
	rm -r $submission/unzipped
fi

header="student_id,student_name,language"
# echo "student_id,student_name,language,matched,not_matched,line_count,comment_count,function_count" > result.csv

if [[ $noexecute -eq 0 ]]; then
	header+=",matched,not_matched"
fi

if [[ $nolc -eq 0 ]]; then
	header+=",line_count"
fi

if [[ $nocc -eq 0 ]]; then
	header+=",comment_count"
fi

if [[ $nofc -eq 0 ]]; then
	header+=",function_count"
fi

echo $header > result.csv

mkdir $target

mkdir $target/{C,C++,Java,Python}

mkdir $submission/unzipped

for file in "$submission"/*; do
    unzip "${file}" -d $submission/unzipped > /dev/null 2>&1
done

find $submission/unzipped -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.py" -o -name "*.java" \) | 
while read -r file; do
	tmp=${file#*/}
	tmp=${tmp#*/}
	name=${tmp%%_*}
	tmp=${tmp#*_}
	tmp=${tmp#*_}
	tmp=${tmp#*_}
	folder=${tmp::7}
	ext=${tmp#*.}


    if [[ $verbose -eq 1 ]]; then
    		echo "Organizing Files of $folder"
    	    if [[ $noexecute -eq 0 ]]; then
    			echo "Executing Files of $folder"
    		fi
    fi




    if [[ $ext == "java" ]]; then

    	mkdir $target/Java/$folder
    	cp "$file" $target/Java/$folder/Main.$ext
    	function_count=$(grep -E "(^[a-z]*\s)*[a-z]*\s+[a-zA-Z][a-zA-Z0-9]*\(([a-zA-Z]+(\[])*\s[a-zA-Z][a-zA-Z0-9]*)*\)\s*\{" target/Java/$folder/Main.$ext | wc -l)
        main_cnt=$(wc -l $target/Java/$folder/Main.$ext)
        comment=$(cat $target/Java/$folder/Main.$ext | grep "//" | wc -l)
        csv_print="$folder,$name,Java"

    	if [[ $noexecute -eq 0 ]]; then
      	
    		javac $target/Java/$folder/Main.$ext > /dev/null 2>&1
        	mismatched=0
        	cnt=0
    		for i in $(ls $test); do
    			num=${i%*.}
    			java -cp $target/Java/$folder Main < $test/$i > $target/Java/$folder/out${num:4:1}.txt 2> /dev/null
    			if  diff $target/Java/$folder/out${num:4:1}.txt $answer/ans${num:4:1}.txt > /dev/null ; then
    				mismatched=$((mismatched+1))
    			fi
    			cnt=$((cnt+1))
        	done
        	matched=$((cnt-mismatched))
        	csv_print+=",$mismatched,$matched"
        
        fi
		if [[ $nolc -eq 0 ]]; then
			csv_print+=",${main_cnt% *}"
		fi

		if [[ $nocc -eq 0 ]]; then
			csv_print+=",$comment"
		fi

		if [[ $nofc -eq 0 ]]; then
			csv_print+=",$function_count"
		fi
		   echo $csv_print >> result.csv

    elif [[ $ext == "c" ]]; then
    	mkdir $target/C/$folder
    	cp "$file" $target/C/$folder/main.$ext

        main_cnt=$(wc -l $target/C/$folder/main.$ext)
        comment=$(cat $target/C/$folder/main.$ext | grep "//" | wc -l)
        function_count=$(grep -E "^[a-z]*\s+[a-zA-Z][a-zA-Z0-9]*\(([a-z]+\s[a-zA-Z][a-zA-Z0-9]*)*\)\s*\{" target/C/$folder/main.$ext | wc -l)
        csv_print="$folder,$name,C"
    	if [[ $noexecute -eq 0 ]]; then

	    	mismatched=0
	    	gcc $target/C/$folder/main.$ext -o $target/C/$folder/main.out
	    	cnt=0
	    	for i in $(ls $test); do
	    		num=${i%*.}
	    		./$target/C/$folder/main.out < $test/$i > $target/C/$folder/out${num:4:1}.txt
	    		if  diff $target/C/$folder/out${num:4:1}.txt $answer/ans${num:4:1}.txt > /dev/null ; then
	    			mismatched=$((mismatched+1))
	    		fi
	    		cnt=$((cnt+1))
	        done
	        matched=$((cnt-mismatched))
	        csv_print+=",$mismatched,$matched"

        fi

		if [[ $nolc -eq 0 ]]; then
			csv_print+=",${main_cnt% *}"
		fi

		if [[ $nocc -eq 0 ]]; then
			csv_print+=",${comment}"
		fi

		if [[ $nofc -eq 0 ]]; then
			csv_print+=",$function_count"
		fi
    		echo $csv_print >> result.csv

    elif [[ $ext == "py" ]]; then
    	mkdir $target/Python/$folder
    	cp "$file" $target/Python/$folder/main.$ext

        main_cnt=$(wc -l $target/Python/$folder/main.$ext)
        comment=$(cat $target/Python/$folder/main.$ext | grep "#" | wc -l)  
        function_count=$(cat $target/Python/$folder/main.$ext | grep "def" | wc -l)      
        cnt=0

        csv_print="$folder,$name,Python"
    	if [[ $noexecute -eq 0 ]]; then
    	
    		mismatched=0
    		for i in $(ls $test); do
    			num=${i%*.}
    			python3 $target/Python/$folder/main.$ext < $test/$i > $target/Python/$folder/out${num:4:1}.txt
    			if  diff $target/Python/$folder/out${num:4:1}.txt $answer/ans${num:4:1}.txt > /dev/null ; then
    				mismatched=$((mismatched+1))
    			fi
    			cnt=$((cnt+1))
        	done
        	matched=$((cnt-mismatched))
        	csv_print+=",$mismatched,$matched"

        fi

		if [[ $nolc -eq 0 ]]; then
			csv_print+=",${main_cnt% *}"
		fi

		if [[ $nocc -eq 0 ]]; then
			csv_print+=",$comment"
		fi

		if [[ $nofc -eq 0 ]]; then
			csv_print+=",$function_count"
		fi
    echo $csv_print >> result.csv

    else
    	mkdir $target/C++/$folder
    	cp "$file" $target/C++/$folder/main.$ext
        
        main_cnt=$(wc -l $target/C++/$folder/main.$ext)
        comment=$(cat $target/C++/$folder/main.$ext | grep "//" | wc -l)
        function_count=$(grep -E "^[a-z]*\s+[a-zA-Z][a-zA-Z0-9]*\(([a-z]+\s[a-zA-Z][a-zA-Z0-9]*)*\)\s*\{" target/C++/$folder/main.$ext | wc -l)

        csv_print="$folder,$name,C++"
    	if [[ $noexecute -eq 0 ]]; then

    		mismatched=0
    		g++ $target/C++/$folder/main.$ext -o $target/C++/$folder/main.out
        	cnt=0
    		for i in $(ls $test); do
    			num=${i%*.}
    			./$target/C++/$folder/main.out < $test/$i > $target/C++/$folder/out${num:4:1}.txt
    			if  diff $target/C++/$folder/out${num:4:1}.txt $answer/ans${num:4:1}.txt > /dev/null ; then
    				mismatched=$((mismatched+1))
    			fi
    			cnt=$((cnt+1))
        	done
        	matched=$((cnt-mismatched))
        	csv_print+=",$mismatched,$matched"

        fi

		if [[ $nolc -eq 0 ]]; then
			csv_print+=",${main_cnt% *}"
		fi

		if [[ $nocc -eq 0 ]]; then
			csv_print+=",$comment"
		fi

		if [[ $nofc -eq 0 ]]; then
			csv_print+=",$function_count"
		fi 
	    echo $csv_print >> result.csv
   
    fi
done


rm -r $submission/unzipped


# for i in $files; do
# 	echo ${i: -2}
# done