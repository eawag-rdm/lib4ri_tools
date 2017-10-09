#!/bin/bash
#Laura Konstantaki
#Lib4RI, Eawag, Switzerland
#Split xml file to single xmls (1 xml corresponds to one publication)


#############################################################################################
mypath=$PWD                                               # get current directory path

a=`find  -name '*.xml'`                                   # get input file name
echo "$a" >> filenames_0.txt
sed -i -e 's|./||g' filenames_0.txt 
sed -i -e 's|.xml||g' filenames_0.txt
read -r filein <filenames_0.txt
mv $filein.xml $filein                                            

mkdir xmls						  # create xml folder
                                     
grep -w "<reference>" $filein > filenames_1.txt           # get the number of publications
pubNO=`cat filenames_1.txt|wc -l`
                                     
xml_split -c reference $filein                            # split into single files

if (( "$pubNO" <= 9 ));					  # need to split it due to different automatic naming of the fils for file number below 10 and above
then
for (( i=1; i<="$pubNO"; i++ ))
do 
   # Get the XML name
   xml_split -c filename -b N$i $filein-0$i.xml  
   mv N$i-01.xml N$i-01.txt   
   sed '1d' N$i-01.txt > tmp1.txt                
   sed -i -e 's|<filename>||g' tmp1.txt          
   sed -i -e 's|</filename>||g' tmp1.txt
   sed -i -e 's|^.*/||g' tmp1.txt                
   value=`awk '{print $0;}' tmp1.txt`            
                            
   # Correct the MODS start and ending
   sed '1d' $filein-0$i.xml > tmp1.xml                     # remove first line
   a="<mods xmlns="http://www.loc.gov/mods/v3" xmlns:mods="http://www.loc.gov/mods/v3"   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://www.w3.org/1999/xlink">" #correct mods start
   sed "2 s|^|$a|" tmp1.xml > tmp2.xml 
   sed -i -e 's|http://www.loc.gov/mods/v3|"http://www.loc.gov/mods/v3"|g' tmp2.xml   #correct mods start (" are not taken into account in the previous substitution)
   sed -i -e 's|http://www.w3.org/2001/XMLSchema-instance|"http://www.w3.org/2001/XMLSchema-instance"|g' tmp2.xml
   sed -i -e 's|http://www.w3.org/1999/xlink|"http://www.w3.org/1999/xlink"|g' tmp2.xml  
   sed -i -e 's|<filename>.*</filename>||g' tmp2.xml      # remove unnecessary tag
   sed -i -e '/^\s*$/d' tmp2.xml                          # remove empty lines
   awk '1; END {print "</mods>"}' tmp2.xml > tmp3.xml     # add correct MODS ending
   
   mv tmp3.xml $value.xml 
   rm tmp*     						
   mv $value.xml $mypath/xmls
done
else
for (( i=1; i<=9; i++ ))
do 
   # Get the XML name
   xml_split -c filename -b N$i $filein-0$i.xml  
   mv N$i-01.xml N$i-01.txt   
   sed '1d' N$i-01.txt > tmp1.txt                
   sed -i -e 's|<filename>||g' tmp1.txt          
   sed -i -e 's|</filename>||g' tmp1.txt
   sed -i -e 's|^.*/||g' tmp1.txt                
   value=`awk '{print $0;}' tmp1.txt`            
                            
   # Correct the MODS start and ending
   sed '1d' $filein-0$i.xml > tmp1.xml                     # remove first line
   a="<mods xmlns="http://www.loc.gov/mods/v3" xmlns:mods="http://www.loc.gov/mods/v3"   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://www.w3.org/1999/xlink">" #correct mods start
   sed "2 s|^|$a|" tmp1.xml > tmp2.xml 
   sed -i -e 's|http://www.loc.gov/mods/v3|"http://www.loc.gov/mods/v3"|g' tmp2.xml   #correct mods start (" are not taken into account in the previous substitution)
   sed -i -e 's|http://www.w3.org/2001/XMLSchema-instance|"http://www.w3.org/2001/XMLSchema-instance"|g' tmp2.xml
   sed -i -e 's|http://www.w3.org/1999/xlink|"http://www.w3.org/1999/xlink"|g' tmp2.xml  
   sed -i -e 's|<filename>.*</filename>||g' tmp2.xml      # remove unnecessary tag
   sed -i -e '/^\s*$/d' tmp2.xml                          # remove empty lines
   awk '1; END {print "</mods>"}' tmp2.xml > tmp3.xml     # add correct MODS ending
   
   mv tmp3.xml $value.xml 
   rm tmp*     						
   mv $value.xml $mypath/xmls
done
for (( i=10; i<="$pubNO"; i++ ))
do
# Get the XML name
   xml_split -c filename -b N$i $filein-$i.xml  
   mv N$i-01.xml N$i-01.txt   
   sed '1d' N$i-01.txt > tmp1.txt                
   sed -i -e 's|<filename>||g' tmp1.txt          
   sed -i -e 's|</filename>||g' tmp1.txt
   sed -i -e 's|^.*/||g' tmp1.txt                
   value=`awk '{print $0;}' tmp1.txt`            
                            
   # Correct the MODS start and ending
   sed '1d' $filein-$i.xml > tmp1.xml                     # remove first line
   a="<mods xmlns="http://www.loc.gov/mods/v3" xmlns:mods="http://www.loc.gov/mods/v3"   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://www.w3.org/1999/xlink">" #correct mods start
   sed "2 s|^|$a|" tmp1.xml > tmp2.xml 
   sed -i -e 's|http://www.loc.gov/mods/v3|"http://www.loc.gov/mods/v3"|g' tmp2.xml   #correct mods start (" are not taken into account in the previous substitution)
   sed -i -e 's|http://www.w3.org/2001/XMLSchema-instance|"http://www.w3.org/2001/XMLSchema-instance"|g' tmp2.xml
   sed -i -e 's|http://www.w3.org/1999/xlink|"http://www.w3.org/1999/xlink"|g' tmp2.xml  
   sed -i -e 's|<filename>.*</filename>||g' tmp2.xml      # remove unnecessary tag
   sed -i -e '/^\s*$/d' tmp2.xml                          # remove empty lines
   awk '1; END {print "</mods>"}' tmp2.xml > tmp3.xml     # add correct MODS ending
   
   mv tmp3.xml $value.xml 
   rm tmp*     						
   mv $value.xml $mypath/xmls
done
fi
   rm filenames*					  # removing unnecessary files
   rm N*						 
   rm $filein-*
#echo "$pubNO publications have been saved in the folder xmls"
################################################################################################

