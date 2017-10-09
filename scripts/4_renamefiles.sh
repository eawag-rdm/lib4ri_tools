#!/bin/bash
#Laura Konstantaki
#Lib4RI, Eawag, Switzerland
#Correct the xml encoding and structure. Check for Open Access Journals and rename the files accordingly. Create a zip file with the corresponding pdfs.


#############################################################################################
mypath=$PWD                                               # get current directory path
cd $mypath/xmls
cp $filename.xml tmp1.xml

# Check if the Publication is OA or not
ISSN=`sed -n 's:.*<identifier type="issn">\(.*\)</identifier>.*:\1:p' tmp1.xml`      
uconv -x any-nfkc tmp1.xml > tmp1a.xml 			 # correct the encoding and the format of the xml
xmllint --format tmp1a.xml > tmp2.xml
if [[ "$ISSN" ]];
then
cd $mypath
ISSNinOA=`grep -w -i "$ISSN" OpenAccess_Info.csv`
cd $mypath/xmls
	if [[ "$ISSNinOA" ]];
	then
	rm $filename.xml
	mv tmp2.xml OA_$filename.xml
	cd $mypath/pdf
	mv $filename.pdf OA_$filename.pdf
	cd $mypath/xmls
	else
	rm $filename.xml
	mv tmp2.xml $filename.xml
	fi
else
echo "This publication has no ISSN and therefore no check on OA was possible"
mv tmp2.xml $filename.xml
fi
rm tmp*
################################################################################################

