#!/bin/bash

# link_contig.sh written by Alechania Misturini [jul/2018]

 # pause
function pause(){
   read -p "$*"
}

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
while getopts "DRprv:c:f:b:h" option;
do
 case $option in
  D)
   dna=1
   ;;
  R)
   rna=1
   ;;
  p)
   pausing=1
   ;;
  r)
   rmtmpf=1
   ;;
  v)
   verbose=$OPTARG
   ;;
  c)
   allcontigs=$OPTARG
   ;;
  f)
   nfrag=$OPTARG
   ;;
  b)
   nbases=$OPTARG
   ;;
  h)
  echo -e "${RED}Help! link_contig.sh${NC}"
  echo "Let's find base sequence matches in your contigs..."
  echo "Define the size of a sequence fragment, that will be get from beginning and ending of each contig,"
  echo "as well a number of bases inside this fragment, that will be searched in all other contigs."
  echo -e "Searches will be done in a direct way, as well using the fragment complementary reverse sequence.\n"
  echo -e "${GRA}*Options:  ${BLU}-D${NC} for a DNA sequence"
  echo -e "           ${BLU}-R${NC} for a RNA sequence"
  echo -e "           ${BLU}-p${NC} to make pauses after printing each search result"
  echo -e "           ${BLU}-r${NC} to remove intermediary files (${GRE}contigs/${NC} directory)"
  echo -e "           ${BLU}-c${NC} ${GRE}${UND}contigs.fasta${NUN}${NC} to define contigs multifasta file"
  echo -e "           ${BLU}-f${NC} ${GRA}${UND}n${NUN}${NC} to define fragment size, in number of bases (${GRA}${UND}n${NUN}${NC})"
  echo -e "           ${BLU}-b${NC} ${GRA}${UND}n${NUN}${NC} to define the number of bases (${GRA}${UND}n${NUN}${NC}) in the fragment that will be search"
  echo -e "           ${BLU}-v${NC} to define verbose mode (default = ${GRA}${UND}2${NUN}${NC}):"
  echo -e "              ${GRA}${UND}0${NUN}${NC} for silent mode, see report.txt after running"
  echo -e "              ${GRA}${UND}1${NUN}${NC} to see a concise result report during the search"
  echo -e "              ${GRA}${UND}2${NUN}${NC} to see a complete result report during the search\n"
  echo -e "${GRA}*Files needed: ${GRE}contigs.fasta${NC}\n"
  echo -e "${GRA}*Example of usage:${NC} ./${GRE}link_contig.sh ${BLU}-D -p -c ${GRE}contigs.fasta ${BLU}-f ${GRA}${UND}180${NUN} ${BLU}-b ${GRA}${UND}40${NUN} ${BLU}-v ${GRA}${UND}1${NUN} ${NC}\n"
  echo -e "${GRA}*Output files: ${GRE}report.txt${NC} with obtained results"
  echo -e "               ${GRE}contigs_4mummer.fasta${NC} multifasta file for mummer usage, with same contig numbers of report.txt"
  echo -e "  ~without -r option:"
  echo -e "               ${GRE}contigs/original_contigs/contig_*${NC} with one contig per file, splitted from multifasta file"
  echo -e "               ${GRE}contigs/direct_contigs/d_contig_*${NC} files of each contig, just the sequence, without spaces"
  echo -e "               ${GRE}contigs/direct_contigs/comrev_d_contig_*${NC} files of each contig, just the complementary reverse sequence, without spaces"
  echo -e "               ${GRE}contigs/frags/head_*${NC} files with fragment of contigs beginning, without spaces"
  echo -e "               ${GRE}contigs/frags/comrev_head_*${NC} files with fragment of contigs beginning, in a complementary reverse sequence, without spaces"
  echo -e "               ${GRE}contigs/frags/tail_*${NC} files with fragment of contigs ending, without spaces"
  echo -e "               ${GRE}contigs/frags/comrev_tail_*${NC} files with fragment of contigs ending, in a complementary reverse sequence, without spaces"
  exit
   ;;
 :)
   echo -e "${RED}Type ./link_contig.sh -h for help.{NC}"; exit
   ;;
  *)
   echo -e "${RED}Type ./link_contig.sh -h for help.{NC}"; exit
   ;;
 esac
done

#------------- defining comrev
function comrev(){

 # checking if its a DNA or RNA sequence
if [ "$dna" = 1 ] && [ "$rna" = 1 ]  ; then echo "Select just one option! -D or -R. Type ./link_contig.sh -h for help."; exit ; fi
if [ "$dna" = 1 ] ; then piri=T ; fi
if [ "$rna" = 1 ] ; then piri=U ; fi

 # obtain complement sequece
while IFS= read -r -n1 base ; do
  if [ "$base" = "A" ] ; then
  echo "${piri}" >> com${sequence}
  else
    if [ "${base}" = "${piri}" ] ; then
    echo "A" >> com${sequence}
    else
      if [ "${base}" = "C" ] ; then
      echo "G" >> com${sequence}
      else
        if [ "${base}" = "G" ] ; then
        echo "C" >> com${sequence}
        fi
      fi
    fi
  fi
done < "$sequence"

cat com${sequence} | tr -d '\n' > com_${sequence} ; echo '' >> com_${sequence}
rm com${sequence}

 # obtain reverse sequence
cat com_${sequence} | rev > comrev_${sequence}
rm com_${sequence}
}
#-------------- end comrev

#------------- defining searchcontig
function searchcontig(){
 # it's running inside contigs/ directory!

valor=$(( ${nfrag} - ${nbases} + 1 ))
for ((idx=1; idx<=${valor}; idx++)); do
  end=$(( ${nbases} + ${idx} - 1 ))
  find=$(cat ${frag} | cut -c "$idx"-"$end")
  grep --color -r --exclude="${filesearch}${fidx}" "$find" ${filesearch}*
  search=$(grep -r --exclude="${filesearch}${fidx}" "$find" ${filesearch}* | wc -l)
  matched=$(grep -r --exclude="${filesearch}${fidx}" "$find" ${filesearch}* | sed 's/:/ /g' | awk '{print $1}')
  match=$(grep -r --exclude="${filesearch}${fidx}" "$find" ${filesearch}*)
  if [ "${search}" != "0" ] ; then
    echo -e "${GRA}>>> ${GRE}${frag} (b${idx}--b${end}) ${CYA}matched with ${GRE}${matched}${NC}"
    echo -e "${frag} b${idx}-b${end} ${matched}" >> ../report.txt
    echo "b${idx}-b${end} ${frag} ${matched} $find" >>  ../find.txt
    break
  fi
done
}
#-------------- end searchcontig

 # split contigs
if [[ -d ./contigs ]]; then
  rm -r ./contigs
  mkdir ./contigs
else
  mkdir ./contigs
fi

csplit -f contig_ -s ${allcontigs} /\>/ {*}
mv contig_* ./contigs/

 # generate direct sequence of configs (without spaces)
cd contigs/
for i in $(ls contig_*) ; do
 sed '1d' ${i} | tr -d '\n' > d_${i} ; echo '' >> d_${i}
done

mkdir original_contigs
mv contig_* original_contigs/

 # generate head with ${nfrag} first bases
for i in $(ls d_contig_*) ; do
  idx=$(echo $i) ; idx=${idx#$'d_contig_'}
  cat ${i} | cut -c 1-${nfrag} > head_${idx}
done

 # generate comrev_head
for sequence in $(ls head_*) ; do
  comrev
done

 # generate tail with ${nfrag} last bases
for i in $(ls d_contig_*) ; do
  idx=$(echo $i) ; idx=${idx#$'d_contig_'}
  aa=$(cat ${i} | wc -m)
  aa_tail=$(( ${aa} - ${nfrag} ))
  cat ${i} | cut -c "${aa_tail}"-"${aa}" > tail_${idx}
done

 # generate comrev_tail
for sequence in $(ls tail_*) ; do
  comrev
done

 # remove old report to not append new results
if [ -a "../report.txt" ]; then rm ../report.txt ; fi
if [ -a "../find.txt" ]; then rm ../find.txt ; fi

#--------------------------------------------------------------------------
 ## Searching  in d_contig
 # search head
echo -e "${MAG}Seaching header fragment sequence in all contigs...${NC}"
for frag in $(ls head_*) ; do
 filesearch="d_contig_"
 fidx=$(echo $frag) ; fidx=${fidx#$'head_'}
 echo -e "${GRA}*Searching ${frag} sequence${NC}"
 searchcontig
  if [ "${pausing}" = "1" ]; then
   pause $(echo -e "${BLU}Check a possible result, then press [Enter] key to continue...${NC}")
  fi
done

 # search comrev_head
echo -e "${MAG}Seaching comrev_header fragment sequence in all contigs...${NC}"
for frag in $(ls comrev_head_*) ; do
 filesearch="d_contig_"
 fidx=$(echo $frag) ; fidx=${fidx#$'comrev_head_'}
 echo -e "${GRA}*Searching ${frag} sequence${NC}"
 searchcontig
  if [ "${pausing}" = "1" ]; then
   pause $(echo -e "${BLU}Check a possible result, then press [Enter] key to continue...${NC}")
  fi
done

 # search tail
echo -e "${MAG}Seaching tail fragment sequence in all contigs...${NC}"
for frag in $(ls tail_*) ; do
 filesearch="d_contig_"
 fidx=$(echo $frag) ; fidx=${fidx#$'tail_'}
 echo -e "${GRA}*Searching ${frag} sequence${NC}"
 searchcontig
  if [ "${pausing}" = "1" ]; then
   pause $(echo -e "${BLU}Check a possible result, then press [Enter] key to continue...${NC}")
  fi
done

 # search comrev_tail
echo -e "${MAG}Seaching comrev_tail fragment sequence in all contigs...${NC}"
for frag in $(ls comrev_tail_*) ; do
 filesearch="d_contig_"
 fidx=$(echo $frag) ; fidx=${fidx#$'comrev_tail_'}
 echo -e "${GRA}*Searching ${frag} sequence${NC}"
 searchcontig
  if [ "${pausing}" = "1" ]; then
   pause $(echo -e "${BLU}Check a possible result, then press [Enter] key to continue...${NC}")
  fi
done

 # generate comrev_d_contig
for sequence in $(ls d_contig_*) ; do
  comrev
done

 ## Searching in comrev_d_contig
 # search head
echo -e "${MAG}Seaching header fragment sequence in all comrev_contigs...${NC}"
for frag in $(ls head_*) ; do
 filesearch="comrev_d_contig_"
 fidx=$(echo $frag) ; fidx=${fidx#$'head_'}
 echo -e "${GRA}*Searching ${frag} sequence${NC}"
 searchcontig
  if [ "${pausing}" = "1" ]; then
   pause $(echo -e "${BLU}Check a possible result, then press [Enter] key to continue...${NC}")
  fi
done

 # search comrev_head
echo -e "${MAG}Seaching comrev_head fragment sequence in all comrev_contigs...${NC}"
for frag in $(ls comrev_head_*) ; do
 filesearch="comrev_d_contig_"
 fidx=$(echo $frag) ; fidx=${fidx#$'comrev_head_'}
 echo -e "${GRA}*Searching ${frag} sequence${NC}"
 searchcontig
  if [ "${pausing}" = "1" ]; then
   pause $(echo -e "${BLU}Check a possible result, then press [Enter] key to continue...${NC}")
  fi
done

 # search tail
echo -e "${MAG}Seaching tail fragment sequence in all comrev_contigs...${NC}"
for frag in $(ls tail_*) ; do
 filesearch="comrev_d_contig_"
 fidx=$(echo $frag) ; fidx=${fidx#$'tail_'}
 echo -e "${GRA}*Searching ${frag} sequence${NC}"
 searchcontig
  if [ "${pausing}" = "1" ]; then
   pause $(echo -e "${BLU}Check a possible result, then press [Enter] key to continue...${NC}")
  fi
done

 # search comrev_tail
echo -e "${MAG}Seaching comrev_tail fragment sequence in all comrev_contigs...${NC}"
for frag in $(ls comrev_tail_*) ; do
 filesearch="comrev_d_contig_"
 fidx=$(echo $frag) ; fidx=${fidx#$'comrev_tail_'}
 echo -e "${GRA}*Searching ${frag} sequence${NC}"
 searchcontig
  if [ "${pausing}" = "1" ]; then
   pause $(echo -e "${BLU}Check a possible result, then press [Enter] key to continue...${NC}")
  fi
done

cd ..

 # preparing report
echo "Report for search between ${allcontigs} contigs" > head_rep
echo "--------------------------------------------------------" >> head_rep
echo "Fragment size = ${nfrag} bases" >> head_rep
echo "Fragment bases searched each time = ${nbases} bases" >> head_rep
echo "--------------------------------------------------------" >> head_rep
echo "" >> head_rep

sed '1s/^/Fragment Fragment_bases Matched_Contig\n/' report.txt > report
column -t report > creport
cat head_rep creport > report2.txt

sed -i '8s/^/--------------------------------------------------------\n/' report2.txt

echo "" >> report2.txt
echo "" >> report2.txt
echo "-------------------------------------------------------------------------" >> report2.txt
echo "Fragment Fragment_bases Matched_Contig Sequence_matched" >> report2.txt
echo "-------------------------------------------------------------------------" >> report2.txt

cat report2.txt find.txt > report.txt

rm report head_rep creport report2.txt find.txt
echo ""
cat report.txt

 # remove temporary files if -r option is used
if [ "${rmtmpf}" = "1" ]; then
 rm -r contigs/
else
 cd contigs/
 mkdir frags
 mv *tail* frags/
 mv *head* frags/
 mkdir direct_contigs
 mv *d_contig* direct_contigs/
 cd ..
fi

 # rename contigs names for mummer
if [ -a "new_${allcontigs}" ]; then rm new_${allcontigs} ; fi

for i in $(ls contigs/original_contigs/*) ; do
  idx=$(echo $i) ; idx=${idx#$'contigs/original_contigs/'}
  sed "s|>.* A|>${idx} A|" $i >> new_${allcontigs}
done
