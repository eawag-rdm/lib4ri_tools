#!/bin/bash
#Laura Konstantaki
#Lib4RI, Eawag, Switzerland
#Correct XML tags


#############################################################################################
mypath=$PWD 						# get current directory path
cd $mypath/xmls
cp $filename.xml tmp1.xml

# Remove unnecessary tags
sed -i -e 's|<reference>|<?xml version="1.0"?>|g' tmp1.xml
sed -i -e 's|</reference>||g' tmp1.xml
sed -i -e 's|<publisher>.*</publisher>||g' tmp1.xml
sed -i -e 's|<coden>.*</coden>||g' tmp1.xml
sed -i -e 's|<source>.*</source>||g' tmp1.xml
sed -i -e 's|<link>.*</link>||g' tmp1.xml
sed -i -e 's|<authors>.*</authors>||g' tmp1.xml
sed -i -e 's|<affiliations>.*</affiliations>||g' tmp1.xml
sed -i -e 's|<pagecount>.*</pagecount>||g' tmp1.xml
sed -i -e 's|<sourcetitle>.*</sourcetitle>||g' tmp1.xml
sed -i -e 's|<fundingtext>.*</fundingtext>||g' tmp1.xml
sed -i -e 's|<isbn>.*</isbn>||g' tmp1.xml

# Page corrections
sed -n 's:.*<articlenumber>\(.*\)</articlenumber>.*:\1:p' tmp1.xml > tmp0.txt
sed -i -e 's/^[ \t]*//g' tmp0.txt
artnumber=`awk '{print $0;}' tmp0.txt`
if [[ "$artnumber" ]];
then
#echo "Has an article number"
sed -i -e 's|<pagestart>.*</pagestart>|<pagestart>'$artnumber'</pagestart>|g' tmp1.xml
sed -i -e 's|</articlenumber>|</articlenumber><pagestart>'$artnumber'</pagestart>|g' tmp1.xml
sed -i -e 's|<pageend>.*</pageend>||g' tmp1.xml
sed -i -e 's|<articlenumber>.*</articlenumber>||g' tmp1.xml
else 
#echo "Has no article number"
:
fi

# Correct the document type
sed -n 's:.*<doctype>\(.*\)</doctype>.*:\1:p' tmp1.xml > tmp1.txt
Type=`awk '{print $0;}' tmp1.txt `
typepress="Article in Press"
if [[ "$Type" = "$typepress" ]];
then
sed -i -e 's|<pagestart>.*</pagestart>|<pagestart>xx</pagestart>|g' tmp1.xml
sed -i -e 's|<pagestart/>|<pagestart>xx</pagestart>|g' tmp1.xml
sed -i -e 's|<pageend>.*</pageend>||g' tmp1.xml
sed -i -e 's|<doctype>.*</doctype>|<doctype>Article</doctype>|g' tmp1.xml
#echo "Is in press"
else
#echo "Is not in press"
:
fi
sed -i -e 's|<doctype>Article</doctype>|<typeOfResource>text</typeOfResource> <genre authorityURI="info:eu-repo/semantics" valueURI="info:eu-repo/semantics/article">Journal Article</genre>|g' tmp1.xml

# Correct the year and the reporting year
sed -i -e 's|<Year>|<originInfo><dateIssued encoding="w3cdtf" keyDate="yes">|g' tmp1.xml
sed -i -e 's|</Year>|</dateIssued><dateOther encoding="w3cdtf" type="reporting year">2017</dateOther></originInfo>|g' tmp1.xml

# Correct the language, funding, peer review, publication status
sed -n 's:.*<languageterm>\(.*\)</languageterm>.*:\1:p' tmp1.xml > tmp2.txt
Language=`awk -F';' '{print $1;}' tmp2.txt `
if [[ "$Language" = English ]];
then
sed -i -e 's|<languageterm>.*</languageterm>|<language><languageTerm authority="iso639-3" type="code">eng</languageTerm></language>|g' tmp1.xml
fi
if [[ "$Language" = France ]];
then
sed -i -e 's|<languageterm>.*</languageterm>|<language><languageTerm authority="iso639-3" type="code">fra</languageTerm></language>|g' tmp1.xml
fi
if [[ "$Language" = Italian ]];
then
sed -i -e 's|<languageterm>.*</languageterm>|<language><languageTerm authority="iso639-3" type="code">ita</languageTerm></language>|g' tmp1.xml
fi
if [[ "$Language" = German ]];
then
sed -i -e 's|<languageterm>.*</languageterm>|<language><languageTerm authority="iso639-3" type="code">deu</languageTerm></language>|g' tmp1.xml
fi
if [[ "$Language" != English && "$Language" != German && "$Language" != Italian && "$Language" != France ]];
then
sed -i -e 's|<languageterm>.*</languageterm>|<language><languageTerm authority="iso639-3" type="code">'$Language'</languageTerm></language>|g' tmp1.xml
echo "The language is $Language , it found no match to the iso638-3 code and has to be manually corrected in DORA"
fi
sed -i -e 's|<fundingdetails>|<note type="peer review">Yes</note><note type="funding">|g' tmp1.xml
sed -i -e 's|</fundingdetails>|</note><note type="publicationStatus">Published</note>|g' tmp1.xml
sed -i -e 's|<fundingdetails/>|<note type="peer review">Yes</note><note type="publicationStatus">Published</note>|g' tmp1.xml

# Correct the identifiers
sed -i -e 's|<eid>|<identifier type="scopus">|g' tmp1.xml
sed -i -e 's|</eid>|</identifier>|g' tmp1.xml
sed -i -e 's|<doi>|<identifier type="doi">|g' tmp1.xml
sed -i -e 's|</doi>|</identifier>|g' tmp1.xml
sed -n 's:.*<issn>\(.*\)</issn>.*:\1:p' tmp1.xml > tmp3.txt
charactNo=`awk '{print length($0);}' tmp3.txt`
ISSN=`awk -F';' '{print $1;}' tmp3.txt `
if [[ "$charactNo" < 8 ]];
then
printf -v ISSNc "%08d\n" $ISSN
#echo "The ISSN was wrong and has been corrected"
else
#echo "Has a correct ISSN"
ISSNc=$ISSN
fi
sed -e 's|\(....\)\(....\)|\1-\2|' <<< "$ISSNc" >tmp4.txt
ISSNn=`awk -F';' '{print $1;}' tmp4.txt `
sed -i -e 's|<issn>.*</issn>|<identifier type="issn">'$ISSNn'</identifier>|g' tmp1.xml

# Correct the pages, volume, issue
sed -i -e 's|<volume>|<detail type="volume"><number>|g' tmp1.xml
sed -i -e 's|</volume>|</number></detail>|g' tmp1.xml
sed -i -e 's|<issue>|<detail type="issue"><number>|g' tmp1.xml
sed -i -e 's|</issue>|</number></detail>|g' tmp1.xml
sed -i -e 's|<pagestart>|<extent unit="page"><start>|g' tmp1.xml
sed -i -e 's|</pagestart>|</start>|g' tmp1.xml
pageend=`sed -n 's:.*<pageend>\(.*\)</pageend>.*:\1:p' tmp1.xml`
if [[ "$pageend" ]];
then 
sed -i -e 's|<pageend>|<end>|g' tmp1.xml
sed -i -e 's|</pageend>|</end></extent>|g' tmp1.xml
else
sed -i -e 's|</start>|</start></extent>|g' tmp1.xml
fi

# Correct the corresponding address
sed -n 's:.*<address>\(.*\)</address>.*:\1:p' tmp1.xml > tmp5.txt
grep -o "email:.*" tmp5.txt >tmp6.txt
sed -i -e 's|email:||g' tmp6.txt
email=`awk '{print $0;}' tmp6.txt`
Email=$(echo $email |sed -e 's/\r//g')
sed -i -e 's|email.*||g' tmp5.txt							# remove email information (the affiliation can be e.g., Last Name, First Name; email:.... missing thus the address)
address=`awk -F';' '{print $1";"$2;}' tmp5.txt `					# get the authors name + address
filetemp=tmp1.xml
sed -i -e "s|<address>.*</address>|<note type=corresponding author address>$address</note><note type=corresponding author email>$Email</note>|g" "$filetemp"
sed -i -e 's|<note type=corresponding author address>|<note type="corresponding author address">|g' tmp1.xml
sed -i -e 's|<note type=corresponding author email>|<note type="corresponding author email">|g' tmp1.xml
sed -i -e 's|<note type="corresponding author email"></note>||g' tmp1.xml
sed -i -e 's|; </note>|</note>|g' tmp1.xml
sed -i -e 's| </note>|</note>|g' tmp1.xml

# Correct the abstract
sed -i -e 's|©.*</abstract>|</abstract>|g' tmp1.xml
sed -i -e 's| </abstract>|</abstract>|g' tmp1.xml

# Split the keywords
sed -n 's:.*<Keywords>\(.*\)</Keywords>.*:\1:p' tmp1.xml > tmp7.txt
KeywordsNo=`grep -o ";" tmp7.txt |cat|wc -l`
KeywordsNoC=$(( KeywordsNo + 1 ))
Keywords=`awk '{print $0;}' tmp7.txt `
filetempp=tmp1.xml
for (( j=1; j<="$KeywordsNoC"; j++ ))
do
Key=`awk -F';' '{printf $'"${j}"'""}' tmp7.txt`
sed -i -e "s|</Keywords>|<topic>$Key</topic></Keywords>|" "$filetempp"
done
sed -i -e "s|<Keywords>$Keywords||g" "$filetempp"
sed -i -e 's|</Keywords>||g' tmp1.xml
sed -i -e 's|<topic> |<topic>|g' tmp1.xml

# Remove all empty tags
sed -i -e 's|<.*/>||g' tmp1.xml  

# Remove empty lines
sed -i -e '/^\s*$/d' tmp1.xml  

rm $filename.xml
mv tmp1.xml $filename.xml
rm tmp*



################################################################################################

