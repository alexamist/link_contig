#!/bin/bash

# written by Alechania Misturini [jul/2018]

 # colors
RED='\033[1;31m'
BLU='\033[1;34m'
GRE='\033[1;32m'
MAG='\033[1;35m'
CYA='\033[1;36m'
YEL='\033[1;33m'
GRA='\033[1;37m'
NC='\033[0m'
UND='\e[4m'
NUN='\e[24m'

 # defining flags and options
while getopts "DRcrs:h" option;
do
 case $option in
  D)
   dna=1
   ;;
  R)
   rna=1
   ;;
  c)
   complementar=1
   ;;
  r)
   reverse=1
   ;;
  s)
   sequence=$OPTARG
   ;;
  h)
  echo -e "${RED}Help! comrev.sh${NC}"
  echo -e "Obtain complementary and/or reverse of a DNA/RNA sequence. \n"
  echo -e "${GRA}*Options:  ${BLU}-D${NC} for a DNA sequence"
  echo -e "           ${BLU}-R${NC} for a RNA sequence"
  echo -e "           ${BLU}-c${NC} to get the complementary sequence"
  echo -e "           ${BLU}-r${NC} to get the reverse sequence"
  echo -e "           ${BLU}-s ${GRE}${UND}sequence${NUN}${NC} to define a sequence for conversion \n"
  echo -e "${GRA}*Files needed: ${GRE}sequence${NC}\n"
  echo -e "${GRA}*Example of usage:${NC} ./${GRE}comrev.sh ${BLU}-D -c -r -s ${GRE}dna_sequence${NC}"
  echo -e "                   ./${GRE}comrev.sh ${BLU}-R -r -s ${GRE}rna_sequence${NC} \n"
  echo -e "${GRA}*Output files: ${GRE}com_sequence${NC} for ${BLU}-c${NC} option"
  echo -e "               ${GRE}rev_sequence${NC} for ${BLU}-r${NC} option"
  echo -e "               ${GRE}comrev_sequence${NC} for ${BLU}-c${NC} and ${BLU}-r${NC} options"
  exit
   ;;
 :)
   echo -e "${RED}Type ./comrev.sh -h for help.${NC}"; exit
   ;;
  *)
   echo -e "${RED}Type ./comrev.sh -h for help.${NC}"; exit
   ;;
 esac
done

#------------- defining complement
function complement(){

 # checking if its a DNA or RNA sequence
if [ "$dna" = 1 ] && [ "$rna" = 1 ]  ; then echo "Select just one option! -D or -R. Type ./comrev.sh -h for help."; exit ; fi
if [ "$dna" = 1 ] ; then piri=T ; fi
if [ "$rna" = 1 ] ; then piri=U ; fi

 # obtain complement sequece
while IFS= read -r -n1 base ; do
#  echo  "$base"
  if [ "$base" = "A" ] ; then
#  echo "changing for ${piri}"
  echo "${piri}" >> com${sequence}
  else
    if [ "${base}" = "${piri}" ] ; then
#    echo "changing for A"
    echo "A" >> com${sequence}
    else
      if [ "${base}" = "C" ] ; then
#      echo "changing for G"
      echo "G" >> com${sequence}
      else
        if [ "${base}" = "G" ] ; then
#        echo "changing for C"
        echo "C" >> com${sequence}
        fi
      fi
    fi
  fi
done < "$sequence"

cat com${sequence} | tr -d '\n' > com_${sequence} ; echo '' >> com_${sequence}
rm com${sequence}

echo "                given sequence: $(cat $sequence)"
echo "        complementary sequence: $(cat com_${sequence})"
}
#-------------- end complement


#------------- defining reverse
function reverse(){
 # checking if its a DNA or RNA sequence
if [ "$dna" = 1 ] && [ "$rna" = 1 ]  ; then echo "Select just one option! -D or -R. Type ./comrev.sh -h for help."; exit ; fi

 # obtain reverse sequence
if [ "$complementar" = 1 ] ; then
  cat com_${sequence} | rev > comrev_${sequence}
  echo "complementary-reverse sequence: $(cat comrev_${sequence})"
else
  cat ${sequence} | rev > rev_${sequence}

  echo "  given sequence: $(cat $sequence)"
  echo "reverse sequence: $(cat rev_${sequence})"
fi
}
#-------------- end reverse

 # run functions
if [ "$complementar" = 1 ] ; then complement ; fi
if [ "$reverse" = "1" ] ; then reverse ; fi
