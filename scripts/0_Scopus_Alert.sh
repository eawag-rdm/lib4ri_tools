#!/bin/bash
#Laura Konstantaki
#Lib4RI, Eawag, Switzerland
#Prepare the Scopus Alert Publications for DORA


#############################################################################################
mypath=$PWD                                             # get current directory path

exec > output.txt					# create the log file with all information

# Split to single xmls
./1_split_publications.sh
						
ls $mypath/xmls >filenames_2.txt			# get xml filenames
cd $mypath		
mv filenames_2.txt $mypath/xmls
cd $mypath/xmls
pubNO2=`cat filenames_2.txt|wc -l`


for (( l=1; l<="$pubNO2"; l++ ))
do
cd $mypath/xmls
filename=`awk -F'.' 'NR=='$l'{print $1;}' filenames_2.txt`
echo "........................................................................................."
echo "Publication $filename"
export filename

echo -e "$l...\c" > /dev/tty

sed -i -e 's/\&amp/\\&/g' $filename.xml			# change the & symbol so that it can be handled by sed later on
sed -i -e 's/amp;/amp/g' $filename.xml 

# Correct xml tags
cd $mypath
./2_XML_corrections.sh

# Add IDs
cd $mypath
./3_ID_matching.sh

# Rename files, correct xml format
cd $mypath
./4_renamefiles.sh
done
cd $mypath/xmls
rm filenames_2.txt

# Create the zip file
echo -e "Creating the zip file...." > /dev/tty
ls $mypath/xmls >filenames_3.txt
OA=`grep -w "OA.*" filenames_3.txt`
cd $mypath
mkdir files_to_upload
if [[ "$OA" ]];
then
mkdir zipfilesOA
cd $mypath/xmls
mv OA* $mypath/zipfilesOA
cd $mypath/pdf
cp OA* $mypath/zipfilesOA
cd $mypath/zipfilesOA
zip -r scopusOA.zip ../zipfilesOA/ >/dev/null
rm *.xml
rm *.pdf
mv scopusOA.zip $mypath/files_to_upload
cd $mypath
rmdir zipfilesOA/
else
echo "........................................"
echo "There are no OA publications"
fi
cd $mypath
mkdir zipfiles
cd $mypath/xmls
mv *.xml $mypath/zipfiles
rm filenames_3.txt
cd $mypath/pdf
cp *.pdf $mypath/zipfiles
cd $mypath/zipfiles
zip -r scopus.zip ../zipfiles/ >/dev/null
rm *.xml
rm *.pdf
mv scopus.zip $mypath/files_to_upload
cd $mypath
rmdir zipfiles/
rmdir xmls/
echo -e "Process successfully completed! The zip files can be found in the folder files_to_upload. Please read the output.txt file for furhter remarks." > /dev/tty
exit
################################################################################################

