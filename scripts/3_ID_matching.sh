#!/bin/bash
#Laura Konstantaki
#Lib4RI, Eawag, Switzerland
#Add Journal, Author and Department IDs


#############################################################################################
mypath=$PWD 								              		
cd $mypath/xmls
cp $filename.xml tmp1.xml

# Journal ID matching
ISSN=`sed -n 's:.*<identifier type="issn">\(.*\)</identifier>.*:\1:p' tmp1.xml`    		    # get the ISSN of the Publication
if [[ "$ISSN" ]];
then                                                             
cd $mypath
grep -w -i "$ISSN" Journals.csv > tmp2.txt                                                		    # match the ISSN in the journal list and get all journal information
sed -i -e 's|"||g' tmp2.txt
JournalID=`awk -F',' '{print $1;}' tmp2.txt `
JournalN=`awk -F',' '{print $2;}' tmp2.txt |sed -e 's|&|&amp;|g' `				    # The journal name and the publisher may have the & symbol
Journalabr=`awk -F',' '{print $3;}' tmp2.txt `
publJ=`awk -F',' '{print $4;}' tmp2.txt |sed -e 's|&|&amp;|g'`
essnJ=`awk -F',' '{print $6;}' tmp2.txt `
mv tmp* $mypath/xmls
cd $mypath/xmls
	if [[ "$JournalID" ]];
	then
	Volume=`sed -n 's:.*<detail type="volume"><number>\(.*\)</number></detail>.*:\1:p' tmp1.xml` # move the Volume etc information in the correct position
	Issue=`sed -n 's:.*<detail type="issue"><number>\(.*\)</number></detail>.*:\1:p' tmp1.xml`
	Startpage=`sed -n 's:.*<start>\(.*\)</start>.*:\1:p' tmp1.xml`
	Endpage=`sed -n 's:.*<end>\(.*\)</end>.*:\1:p' tmp1.xml`
	sed -i -e 's|<detail type="volume"><number>\(.*\)</number></detail>||g' tmp1.xml
	sed -i -e 's|<detail type="issue"><number>\(.*\)</number></detail>||g' tmp1.xml
	sed -i -e 's|<extent unit="page"><start>\(.*\)</start></extent>||g' tmp1.xml	
	sed -i -e 's|<extent unit="page"><start>\(.*\)</start>||g' tmp1.xml
	sed -i -e 's|<end>\(.*\)</end></extent>||g' tmp1.xml
	sed -i -e 's|<part>||g' tmp1.xml
	sed -i -e 's|</part>||g' tmp1.xml
	filetemp=tmp1.xml
	sed -i -e 's|<identifier type="issn">|<identifier type=issn>|g' tmp1.xml
	sed -i -e "s|<identifier type=issn>$ISSN</identifier>|<relatedItem type=host><titleInfo><title>$JournalN</title></titleInfo><titleInfo type=abbreviated><title>$Journalabr</title></titleInfo><originInfo><publisher>$publJ</publisher></originInfo><identifier type=journal id>$JournalID</identifier><identifier type=issn>$ISSN</identifier><identifier type=e-issn>$essnJ</identifier><part><detail type=volume><number>$Volume</number></detail><detail type=issue><number>$Issue</number></detail><extent unit=page><start>$Startpage</start><end>$Endpage</end></extent></part></relatedItem>|g" "$filetemp"									                      # add the journal information
	#sed -i -e 's|</part>|</part></relatedItem>|g' tmp1.xml					      # correct the xml tags, delete unncesseary empty tags
	sed -i -e 's|<identifier type=issn>|<identifier type="issn">|g' tmp1.xml
	sed -i -e 's|<relatedItem type=host>|<relatedItem type="host">|g' tmp1.xml
	sed -i -e 's|<titleInfo type=abbreviated>|<titleInfo type="abbreviated">|g' tmp1.xml
	sed -i -e 's|<identifier type=journal id>|<identifier type="journal id">|g' tmp1.xml
	sed -i -e 's|<identifier type=e-issn>|<identifier type="e-issn">|g' tmp1.xml
	sed -i -e 's|<detail type=volume>|<detail type="volume">|g' tmp1.xml
	sed -i -e 's|<detail type=issue>|<detail type="issue">|g' tmp1.xml
	sed -i -e 's|<extent unit=page>|<extent unit="page">|g' tmp1.xml
	sed -i -e 's|<titleInfo type="abbreviated"><title></title></titleInfo>||g' tmp1.xml
	sed -i -e 's|<originInfo><publisher></publisher></originInfo>||g' tmp1.xml
	sed -i -e 's|<identifier type="e-issn"></identifier>||g' tmp1.xml
	sed -i -e 's|<detail type="volume"><number></number></detail>||g' tmp1.xml
	sed -i -e 's|<detail type="issue"><number></number></detail>||g' tmp1.xml
	sed -i -e 's|<end></end>||g' tmp1.xml
	else 
	echo "The ISSN found no match and the journal has to be manually linked in DORA"
	sed -i -e 's|<identifier type="issn">.*</identifier>||g' tmp1.xml															  
	sed -i -e 's|<part>|<relatedItem type="host"><part>|g' tmp1.xml
        sed -i -e 's|</part>|</part></relatedItem>|g' tmp1.xml
	fi
else 
sed -i -e 's|<part>|<relatedItem type="host"><part>|g' tmp1.xml
sed -i -e 's|</part>|</part></relatedItem>|g' tmp1.xml
echo "The publication has no ISSN and the journal has to be manually linked in DORA"
fi

# Get the WOS ID and rearange the identifier tags
DOI=`sed -n 's:.*<identifier type="doi">\(.*\)</identifier>.*:\1:p' tmp1.xml `
Scopus=`sed -n 's:.*<identifier type="scopus">\(.*\)</identifier>.*:\1:p' tmp1.xml `
cd $mypath
if [[ "$DOI" ]];
then
grep -w -i "$DOI" WOS.txt > tmp3.txt           								# match the DOI in the WOS file and extract the WOS
awk -F'\t' '{print $61;}' tmp3.txt > tmp4.txt								# remove tab spaces
grep -w "WOS" tmp4.txt | sed -e 's|WOS:||g' > tmp5.txt 							# take only WOS IDs with the words "WOS:". Remove those words afterwards
WOS=`awk '{print $1;}' tmp5.txt `
mv tmp* $mypath/xmls
cd $mypath/xmls
sed -i -e 's|<identifier type="doi">'$DOI'</identifier>||g' tmp1.xml
sed -i -e 's|<identifier type="scopus">'$Scopus'</identifier>|<identifier type="doi">'$DOI'</identifier><identifier type="ut">'$WOS'</identifier><identifier type="scopus">'$Scopus'</identifier>|g' tmp1.xml
sed -i -e 's|<identifier type="ut"></identifier>||g' tmp1.xml
else
cd $mypath/xmls
#echo "The publications has no DOI and thus there is no WOS ID linked to this publication"
fi

# Get the Author and Department ID
sed -n 's:.*<authorsaffiliations>\(.*\)</authorsaffiliations>.*:\1:p' tmp1.xml > tmp6.txt
sed -e 's/\&amp/\&amp;/g' tmp6.txt > tmp60.txt								
sed -i -e 's/\\&/\&/g' tmp60.txt
Authoraffil=`awk '{print $0;}' tmp60.txt`                                                               # all authors with affiliations for later use, corrections of the & so that it fits later on
AuthorsNo=`grep -o ";" tmp6.txt |cat|wc -l`
AuthorsNoC=$(( AuthorsNo + 1 ))										# number of authors is equal to the number of demiters + 1
        for (( j=1; j<="$AuthorsNoC"; j++ ))
	do 
	awk -F';' '{printf $'"${j}"'""}' tmp6.txt > tmp7.txt						# use the loop for printing different columns (hence different authors)
	sed -i -e 's/^[ \t]*//g' tmp7.txt								# remove leading spaces
        AuthorLast=`awk -F',' '{print $1;}' tmp7.txt`
	awk -F',' '{print $2;}' tmp7.txt > tmp70.txt
	sed -i -e 's/^[ \t]*//g' tmp70.txt
	AuthorFirst=`awk '{print $0;}' tmp70.txt`
        awk -F',' '{print $2;}' tmp7.txt > tmp71.txt
	sed -i -e 's/^[ \t]*//g' tmp71.txt
        head -c 1 tmp71.txt >tmp72.txt									# get only first initial of first author name
        AuthorIni=`awk '{print $1;}' tmp72.txt`
	awk -F',' '{$1=$2=""; print $0;}' tmp7.txt > tmp8.txt						# print everything after 2 first commas (to get the whole affiliation incl any commas)
	cd $mypath 
	./3a_findaffiliation.sh										# running external script that has all possible variations of the Lib4RI affiliations
	cd $mypath/xmls
	Affil=`awk '{print $0;}' tmpall.txt` 								# get only authors that have a Lib4RI affiliation		
		if [[ "$Affil" ]];									# if it is an Lib4RI author, add the ID information. Otherwise not.
		then
		Authortogrep=$AuthorLast,$AuthorIni
		cd $mypath
		sed -i -e 's|,,,,,,,,,|,,,,|g' Authors.csv
		DepartName0=`grep -w -i "Empa" Authors.csv`						# check if the publications are Empa or Eawag to do correct substitution below
		DepartName01=`grep -w -i "Eawag" Authors.csv`
			if [[ "$DepartName0" ]];
			then
			sed -i -e 's|,,,,|000 Empa"|g' Authors.csv				        # all authors that have no department in DORA are set to the Lib4RI department
			standartDepID=empa-units\:56
			standartDepName='000 Empa'		
			fi
			if [[ "$DepartName01" ]];
			then
			sed -i -e 's|,,,,|Eawag"|g' Authors.csv	
			standartDepID=eawag-units\:34
			standartDepName=Eawag			        
			fi		
		grep -m1 "$Authortogrep.*" Authors.csv > tmp9.txt 					# grep only the first match - to avoid getting more matches, but it may match the wrong author!
		Authormatch=`grep -w -i "$Authortogrep.*" Authors.csv`
			if [[ "$Authormatch" ]];
			then
			FullName=`awk -F'"' '{print $4;}' tmp9.txt`
			AuthorID=`awk -F',' '{print $1;}' tmp9.txt`
			DepartName=`awk -F'"' '{print $(NF-1);}' tmp9.txt`				# printing second last column that contains the department name
			DepartID=									# clear the variable	
				if [[ "$DepartName" ]];							# get the department ID
				then
				grep -m1 "$DepartName" Departments.csv > tmp10.txt 			# to get the first match
				DepartID=`awk -F',' '{print $1;}' tmp10.txt`
				fi	
			mv tmp* $mypath/xmls		
			cd $mypath/xmls
			filetemp2=tmp1.xml
			sed -i -e "s|</authorsaffiliations>|<name type=personal><namePart type=family>$AuthorLast</namePart><namePart type=given>$AuthorFirst</namePart><nameIdentifier type=authorId>$AuthorID</nameIdentifier><nameIdentifier type=organizational unit id>$DepartID</nameIdentifier><fullName>$FullName</fullName><affiliation>$DepartName</affiliation><role><roleTerm authority=marcrelator type=text>author</roleTerm></role></name></authorsaffiliations>|" "$filetemp2"    		    # in case there is a space in a variable " are needed for the sed command and cannot be in the text between the ||		
			else
			mv tmp* $mypath/xmls
			cd $mypath/xmls
			filetemp2=tmp1.xml
			echo "The Lib4RI author $AuthorLast was not found and is only linked to the Lib4RI department"
 			sed -i -e "s|</authorsaffiliations>|<name type=personal><namePart type=family>$AuthorLast</namePart><namePart type=given>$AuthorFirst</namePart><nameIdentifier type=organizational unit id>$standartDepID</nameIdentifier><affiliation>$standartDepName</affiliation><role><roleTerm authority=marcrelator type=text>author</roleTerm></role></name></authorsaffiliations>|" "$filetemp2" 
			fi		
		else
		cd $mypath/xmls
		filetemp2=tmp1.xml
		sed -i -e "s|</authorsaffiliations>|<name type=personal><namePart type=family>$AuthorLast</namePart><namePart type=given>$AuthorFirst</namePart><role><roleTerm authority=marcrelator type=text>author</roleTerm></role></name></authorsaffiliations>|" "$filetemp2"  
		fi
	done
sed -i -e 's/\&amp/\&amp;/g' tmp1.xml  									# correct the &
sed -i -e 's/\\&/\&/g' tmp1.xml
sed -i -e 's|<name type=personal><namePart type=family>|<name type="personal" usage="primary"><namePart type="family">|' tmp1.xml	       # correct the xml tags. 
sed -i -e 's|<name type=personal><namePart type=family>|<name type="personal"><namePart type="family">|g' tmp1.xml
sed -i -e 's|<namePart type=given>|<namePart type="given">|g' tmp1.xml
sed -i -e 's|<nameIdentifier type=authorId>|<nameIdentifier type="authorId">|g' tmp1.xml
sed -i -e 's|<nameIdentifier type=organizational unit id>|<nameIdentifier type="organizational unit id">|g' tmp1.xml
sed -i -e 's|<roleTerm authority=marcrelator type=text>|<roleTerm authority="marcrelator" type="text">|g' tmp1.xml
sed -i -e "s|<authorsaffiliations>$Authoraffil||g" "$filetemp2"
sed -i -e 's|</authorsaffiliations>||g' tmp1.xml

# remove empty lines
sed -i -e '/^\s*$/d' tmp1.xml 

rm -rf $filename.xml
mv tmp1.xml $filename.xml
rm -rf tmp*
################################################################################################

