#!/bin/bash
#Laura Konstantaki
#Lib4RI, Eawag, Switzerland
#find the authors that have a Lib4RI affiliation


#############################################################################################
mypath=$PWD 					# get current directory path
cd $mypath/xmls

# get the authors with the Lib4RI affiliation

grep -i "Empa" tmp8.txt > tmpa.txt
grep -i "Eawag" tmp8.txt > tmpb.txt
grep -i "Eidgenössische Materialprüfungs- und Forschungsanstalt" tmp8.txt > tmpc.txt
grep -i "Swiss Federal Laboratories for Materials Science and Technology" tmp8.txt > tmpd.txt
grep -i "Swiss Federal Laboratories for Materials Testing and Research" tmp8.txt > tmpe.txt
grep -i "Swiss Laboratories for Materials Science & Technology" tmp8.txt > tmpf.txt
grep -i "Swiss Fed. Labs. Mat. Test. and Res." tmp8.txt > tmpg.txt
grep -i "Swiss Fed. Labs. for Mat. Sci. and Technol." tmp8.txt > tmph.txt
grep -i "Swiss Federal Labs for Mater. Sci and Tech." tmp8.txt > tmpi.txt
grep -i "Swiss Federal Institute of Aquatic Science and Technology" tmp8.txt > tmpj.txt
grep -i "Swiss Federal Institute of Water Science and Technology" tmp8.txt > tmpk.txt
grep -i "Swiss Federal Inst. of Aquatic Science and Technology" tmp8.txt > tmpl.txt
grep -i "Swiss Federal Institute of Aquatic Research and Science" tmp8.txt > tmpm.txt
grep -i "Swiss Fed. Inst. of Aquatic Sci. and Technol." tmp8.txt > tmpn.txt
grep -i "Swiss Federal Institute for Aquatic Science and Technology" tmp8.txt > tmpo.txt
grep -i "Eidgenössische Anstalt für Wasserversorgung, Abwasserreinigung und Gewässerschutz" tmp8.txt > tmpp.txt
grep -i "Eidgenossische Anst. F. Wasserversorgung, Abwasserreinigung und Gewasserschutz" tmp8.txt > tmpq.txt
grep -i "Kastanienbaum" tmp8.txt > tmpr.txt
grep -i "Swiss Federal Institute of Aquatic Research" tmp8.txt > tmps.txt


cat tmpa.txt tmpb.txt tmpc.txt tmpd.txt tmpe.txt tmpf.txt tmpg.txt tmph.txt tmpi.txt tmpg.txt tmpk.txt tmpl.txt tmpm.txt tmpn.txt tmpo.txt tmpp.txt tmpq.txt tmpr.txt tmps.txt> tmpall.txt
################################################################################################

