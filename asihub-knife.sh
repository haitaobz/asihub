#remove whitespaces from input parameters
RFSW_TAG_LABEL=$(echo ${RFSW_TAG_LABEL} | grep -o "[a-zA-Z0-9_]*")
BASED_ON_ASIHUB_TAG_LABEL=$(echo ${BASED_ON_ASIHUB_TAG_LABEL} | grep -o "[a-zA-Z0-9_.]*")
NEW_ASIHUB_TAG_PREFIX=$(echo ${NEW_ASIHUB_TAG_PREFIX} | grep -o "[a-zA-Z0-9_]*")
BRANCHES_FOR=$(echo ${BRANCHES_FOR} | grep -o "[a-zA-Z0-9_,.]*")

#check input parameters
is_knife=false
if [ -z "${RFSW_TAG_LABEL}" ]; then
    echo "RFSW_TAG_LABEL empty! All input parameters must be set, aborting" > new_asihub_ver.txt
    exit 1
elif [[ ${RFSW_TAG_LABEL} =~ ^ASIR_HUB_RFSW_20[0-9]{2}_[0-9]{2}_[0-9]{3}$ ]]; then
    echo "RFSW_TAG_LABEL has correct format and no prefix"
    rfsw_prefix=""
elif [[ ${RFSW_TAG_LABEL} =~ ^([A-Za-z0-9]{1,9}_)?ASIR_HUB_RFSW_20[0-9]{2}_[0-9]{2}_[0-9]{3}$ ]]; then
    echo "RFSW_TAG_LABEL has correct format and has a prefix"
    rfsw_prefix=$(echo ${RFSW_TAG_LABEL} | cut -d "_" -f 1)
elif [[ ${RFSW_TAG_LABEL} =~ ^(KNIFE_)?([A-Za-z0-9]{1,9}_)?ASIR_HUB_RFSW_20[0-9]{2}_[0-9]{2}_[0-9]{3}$ ]]; then
    echo "RFSW_TAG_LABEL has correct format and has a prefix and is a knife build"
    rfsw_prefix=$(echo ${RFSW_TAG_LABEL} | cut -d "_" -f 1)
    is_knife=true
else
    echo "RFSW_TAG_LABEL format is incorrect!, aborting" > new_asihub_ver.txt
    exit 1
fi

if [ -z "${BASED_ON_ASIHUB_TAG_LABEL}" ]; then
    echo "BASED_ON_ASIHUB_TAG_LABEL empty! All input parameters must be set, aborting" > new_asihub_ver.txt
    exit 1
elif [[ ${BASED_ON_ASIHUB_TAG_LABEL} =~ ^ASIHUB[0-9]{2}\.[0-9]{2}\.R[0-9]+$ ]]; then
    echo "BASED_ON_ASIHUB_TAG_LABEL has correct format and no prefix"
    prefix=""
elif [[ ${BASED_ON_ASIHUB_TAG_LABEL} =~ ^ASIHUB(_[A-Za-z0-9]{1,9}_)?[0-9]{2}\.[0-9]{2}\.R[0-9]+$ ]]; then
    echo "BASED_ON_ASIHUB_TAG_LABEL has correct format and already has a prefix"
    prefix=$(echo ${BASED_ON_ASIHUB_TAG_LABEL} | cut -d "_" -f 2)
else
    echo "BASED_ON_ASIHUB_TAG_LABEL format is incorrect!, aborting" > new_asihub_ver.txt
    exit 1
fi
if [ -z "${NEW_ASIHUB_TAG_PREFIX}" ]; then
    echo "NEW_ASIHUB_TAG_PREFIX empty! No prefix will be used" > new_asihub_ver.txt
elif [[ ${NEW_ASIHUB_TAG_PREFIX} =~ ^[A-Za-z0-9]{1,9} ]]; then
    prefix=${NEW_ASIHUB_TAG_PREFIX}
    echo "NEW_ASIHUB_TAG_PREFIX has correct format and will be used"
else
    echo "NEW_ASIHUB_TAG_PREFIX format is incorrect!, aborting" > new_asihub_ver.txt
    exit 1
fi

set variables
svne1root="https://svne1.access.nsn.com"
svnopts="--non-interactive --trust-server-cert --no-auth-cache --username ${SVN_USER} --password ${SVN_PASSWORD}"
rfsw_repo_url="${svne1root}/isource/svnroot/asir-hub-rfsw"
asid_url="${svne1root}/isource/svnroot/BTS_D_ASIHUB"
target_dir="C_Element/SE_ASI/SS_ASIHUB/Target"
#set git config
git config --global user.email "scm.asihub@nokia.com"
git config --global user.name "SCM ASIHUB"
#wipe the workspace
rm -rf *
#checkout asir tag and extract variables and binaries
svn co ${svnopts} ${rfsw_repo_url}/tags/${RFSW_TAG_LABEL} rfsw_tag
das_repo_tag=$(cat rfsw_tag/ReleaseNote.xml | grep -o "<repositoryBranch>.*"  | cut -d ">" -f 2 | cut -d "<" -f 1)
rfsw_tag=$(cat rfsw_tag/ReleaseNote.xml | grep -o "<name>.*"  | cut -d ">" -f 2 | cut -d "<" -f 1 | grep -o "[a-zA-Z0-9_]*")
ps_tag=$(cat rfsw_tag/ReleaseNote.xml | grep -o "<baseline.*PS_REL.*"  | cut -d ">" -f 2 | cut -d "<" -f 1 | grep -o "[a-zA-Z0-9_]*")
rfsw_file_path="$(pwd)/rfsw_tag/target/RFSW.txz"
rfsw_baseline_path="$(pwd)/rfsw_tag/target/RFSW.baseline"
rfsw_releasenote_path="$(pwd)/rfsw_tag/ReleaseNote.xml"
#checkout bts_d_asihub tag and update bundle
main_ws_dir="$(pwd)"
svn co ${asid_url}/tags/${BASED_ON_ASIHUB_TAG_LABEL} asihub_tag ${svnopts}
cd asihub_tag/${target_dir}
svn del fzhub-bundle_*.tgz
cd ${main_ws_dir}
#update sw version and for_targetBD.txt file
bd_str=$(cat asihub_tag/${target_dir}/for_targetBD.txt | grep -o "softwareReleaseVersion=.*")
oldSwVerFullName=$(echo ${bd_str} | cut -d "\"" -f 2)
bd_num=$(echo ${bd_str} | grep -oP "[0-9]{2}\.[0-9]{2}\.R[0-9]{2}")
bd_month=$(echo ${bd_num} | cut -d "." -f 2)
bd_year=$(echo ${bd_num} | cut -d "." -f 1)
bd_ver=$(echo ${bd_num} | cut -d "R" -f 2)
month=$(date +%m)
year=$(date +%y)
ver="01"
if [ -z "${prefix}" ]; then
    if [ -z "${NEW_ASIHUB_TAG_PREFIX}" ]; then
        if [ ! -z "${rfsw_prefix}" ]; then
            prefix=${rfsw_prefix}
        fi
    else
        prefix=${NEW_ASIHUB_TAG_PREFIX}
    fi
fi
if [ ! -z "${prefix}" ]; then
    prefix="_${prefix}_"
fi

if [ -z "${NEW_ASIHUB_TAG_PREFIX}" ]; then
    if [ "${year}" -eq "${bd_year}" ]; then
        if [ "${month}" -eq "${bd_month}" ]; then
            ver=$((10#${bd_ver}+1))
            if [ 10 -gt "${ver}" ]; then
                ver="0${ver}"
            fi
        fi
    fi
fi
new_asihub_ver="ASIHUB${prefix}${year}.${month}.R${ver}"
echo "softwareReleaseVersion=\"${new_asihub_ver}\"" > asihub_tag/${target_dir}/for_targetBD.txt
echo "${new_asihub_ver}" > new_asihub_ver.txt

#checkout DAS repo and prepare env
rm -rf das
git clone https://${SVN_USER}:${SVN_PASSWORD}@gerrite1.ext.net.nokia.com:443/SCRFSW/DAS/das das
cd das
git fetch origin ${das_repo_tag}:${das_repo_tag}
git checkout ${das_repo_tag}
bundle_workspace=$(pwd)
#set virtualenv
if [[ ! -d "${bundle_workspace}/env" ]]; then
    virtualenv ${bundle_workspace}/env
fi
source ${bundle_workspace}/env/bin/activate
pip install --upgrade pip
pip install flatbuffers
#run ecl env
python ECL.py --svn ${svne1root} --username ${SVN_USER} --password ${SVN_PASSWORD} -d 6
mkdir build
cd build
#extracting keys
mkdir keys
set +x
echo "${ASIHUB_PRIVATE}" > keys/ssk.pem
echo "${ASIHUB_SPKSIG}" > keys/spk.sig
echo "${ASIHUB_PUBLIC}" > keys/ppk.pem
set -x
#copy binaries and create bundle
cp ${rfsw_file_path} .
#look for rfsw baseline file or create empty
if [ -f "$rfsw_baseline_path" ]; then
    cp ${rfsw_baseline_path} .
        cat RFSW.baseline
else
    touch RFSW.baseline
fi
touch CCS.baseline
timestamp=$(date +%y%m%d%H%M%S)
../C_Platform/LFS/os/platforms/fzhub/mkbundle-fzhub -p -N fzhub-bundle_${timestamp}.tgz -K $(pwd)/keys -V ${new_asihub_ver} ../C_Platform/CCS/Tar/LINUX_FZHUB/CCS.txz CCS.baseline RFSW.txz RFSW.baseline <<< "${ASIHUB_PASSPHR}"
new_bundle_file="$(pwd)/fzhub-bundle_${timestamp}.tgz"
#keys cleanup
set +x
shred -zvu -n 5 keys/*
rm -rf keys
set -x
cd ../..
#checkout bts_d_asihub and update bundle part 2
cd asihub_tag/${target_dir}
cp ${new_bundle_file} .
svn add fzhub-bundle_*.tgz
#update releasenote.xml file
releaseDate=$(date +%Y-%m-%d)
releaseTime=$(date +%H:%M:%S%:z)
sed -i 's|'${oldSwVerFullName}'|'${new_asihub_ver}'|' releasenote.xml
sed -i 's|<releaseDate>.*</releaseDate>|<releaseDate>'${releaseDate}'</releaseDate>|' releasenote.xml
sed -i 's|<releaseTime>.*</releaseTime>|<releaseTime>'${releaseTime}'</releaseTime>|' releasenote.xml
sed -i 's|<basedOn>.*</basedOn>|<basedOn>'${oldSwVerFullName}'</basedOn>|' releasenote.xml
sed -i 's|<baseline name="PS" auto_create="false">.*</baseline>|<baseline name="PS" auto_create="false">'${ps_tag}'</baseline>|' releasenote.xml
sed -i 's|<baseline name="ASIR_HUB_RFSW" auto_create="false">.*</baseline>|<baseline name="ASIR_HUB_RFSW" auto_create="false">'${rfsw_tag}'</baseline>|' releasenote.xml

branch=""
if [ -z "${BRANCHES_FOR}" ]; then
    echo "BRANCHES_FOR empty! Branch for branches will be taken from: ${BASED_ON_ASIHUB_TAG_LABEL}"
else
    echo "Substituting branch for branches with: ${BRANCHES_FOR}"
    sed -i '/<branch>.*<\/branch>/d' releasenote.xml
    #sed -i 's|</branchFor>|\'$'\n</branchFor>|' releasenote.xml
    branch=$(echo ${BRANCHES_FOR} | cut -d "," -f 1)
    branches=$(echo ${BRANCHES_FOR} | grep -o ",.*" | cut -c 2-)
    while [ ! -z "${branch}" ]
    do
        branch=$(echo ${branch} | grep -o "[a-zA-Z0-9_.]*")
        sed -i 's|<branchFor>|<branchFor>\'$'\n\  <branch>'${branch}'</branch>|' releasenote.xml
        branch=$(echo ${branches} | cut -d "," -f 1)
        branches=$(echo ${branches} | grep -o ",.*" | cut -c 2-)
    done
fi

#corrected faults copy to releasenotes
cat ${rfsw_releasenote_path}
cat releasenote.xml
rfswcStart=$(grep -nr "<correctedFaults>" ${rfsw_releasenote_path} | cut -d ":" -f 1)
rfswcEnd=$(grep -nr "</correctedFaults>" ${rfsw_releasenote_path} | cut -d ":" -f 1)

if [ -z $( grep "correctedFaults" releasenote.xml | head -1 ) ]; then
    sed -i 's|<revertedCorrectedFaults>|<correctedFaults/>\n<revertedCorrectedFaults>|' releasenote.xml
fi
sed -i 's|<correctedFaults>|<correctedFaults/>\n<correctedFaults>|' releasenote.xml
substStart=$(grep -nr "<correctedFaults/>" releasenote.xml | cut -d ":" -f 1)
sed -i 's|<correctedFaults/>||' releasenote.xml
corStart=$(grep -nr "<correctedFaults>" releasenote.xml | cut -d ":" -f 1)
corEnd=$(grep -nr "</correctedFaults>" releasenote.xml | cut -d ":" -f 1)
if [ -z "${corEnd}" -o -z "${corStart}" ]; then
    echo "One of the correctedFaults tags in Asihub releasenotes file is missing!";
else
    echo "Removing old fault correction tag from Asihub releasenote file"
    sed -i ''$corStart','$corEnd'd' releasenote.xml
fi

if [ -z "${substStart}" ]; then
    echo "No place to paste correctedFaults info in asihub releasenotes file";
else
    if [ -z "${rfswcEnd}" -o -z "${rfswcStart}" ]; then
        echo "correctedFaults tags is missing in rfsw ReleaseNotes file! Not copying.";
    else
        echo "Correction faults found in rfsw ReleaseNotes, copying..."
        cp releasenote.xml releasenote.tmp
        > releasenote.xml
        tmp_len=$(($(wc -l releasenote.tmp | cut -d " " -f 1)+1))
        i_rfsw=${rfswcStart}
        rfswlen=$((1+${rfswcEnd}-${rfswcStart}))
        for ind in $(seq 1 $tmp_len); do
            if [ ${ind} -eq ${substStart} ]; then
                for rfind in $(seq 1 $rfswlen); do
                	sed ''$((${rfswcStart}+${rfind}-1))'!d' ${rfsw_releasenote_path}
                    sed ''$((${rfswcStart}+${rfind}-1))'!d' ${rfsw_releasenote_path} >> releasenote.xml
                done
            else
            	sed ''${ind}'!d' releasenote.tmp
                sed ''${ind}'!d' releasenote.tmp >> releasenote.xml
            fi    
        done
        rm releasenote.tmp
    fi
fi

cat releasenote.xml

svn_current_rev=$(svn info ${svnopts} ${asid_url} | grep "Revision" | cut -d " " -f 2)
svn_tag_rev=$((${svn_current_rev}+2))
sed -i 's|<repositoryRevision>.*</repositoryRevision>|<repositoryRevision>'${svn_tag_rev}'</repositoryRevision>|' releasenote.xml
cd ${main_ws_dir}
#commit changes
svn copy ${svnopts} asihub_tag/ ${asid_url}/branches/${new_asihub_ver} -m "Files for release ${new_asihub_ver}"
#create tag
if ! svn info ${svnopts} ${asid_url}/trunk ${asid_url}/tags/${new_asihub_ver}; then
    svn_tag_rev="$(svn copy ${svnopts} ${asid_url}/branches/${new_asihub_ver} ${asid_url}/tags/${new_asihub_ver} \
    -m "Creating new tag for wft release ${new_asihub_ver}" \
    | grep "Committed revision*" | cut -d " " -f 3 | tr -d '.' )"
else
    echo "Tag already exists!" >> new_asihub_ver.txt
    exit 1
fi
#wft upload
wft_validation_info=$(curl -k https://wft.int.net.nokia.com/ext/api/xml -F access_key=5INUgW6JdmmsSqaAsc7KATJglOHOPtoPCufN9gnn -F file=@asihub_tag/${target_dir}/releasenote.xml)
if [ "${wft_validation_info}" = "XML valid!" ]; then
    echo "releasenote.xml sent to WFT"
else
    echo "releasenote.xml didn't pass verification!"  >> new_asihub_ver.txt
    exit 1
fi
cd ..
