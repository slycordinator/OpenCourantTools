#!/usr/bin/env bash

# Copyright (C) 2026 SISW Siemens Industry Software Inc.
# Copyright> 
# Copyright>  Permission is hereby granted, free of charge, to any person obtaining 
# Copyright>  a copy of this software and associated documentation files (the "Software"), 
# Copyright>  to deal in the Software without restriction, including without limitation 
# Copyright>  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
# Copyright>  sell copies of the Software, and to permit persons to whom the Software is 
# Copyright>  furnished to do so, subject to the following conditions:
# Copyright> 
# Copyright>  The above copyright notice and this permission notice shall be included in all 
# Copyright>  copies or substantial portions of the Software.
# Copyright> 
# Copyright>  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# Copyright>  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# Copyright>  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# Copyright>  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIAsBILITY, 
# Copyright>  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
# Copyright>  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.




echo " "
echo " "
echo "*********************************************"
echo "** Generating Radioss Dynamic user library **"
echo "**            linux64 gfortran             **"
echo "**                                         **"
echo "*********************************************"
echo " "

if (( $# == 0 ));then
  echo " "
  echo "Script Usage:"
  echo " "
  echo "build_userlib.bash starter=\"Starter source files\" engine=\"Engine Source files\" [Optional Arguments]"
  echo " "
  echo "[Optional Arguments]"
  echo " "
  echo "library=\"Additional static Library\""
  echo "outfile=\"Optional library name\""
  echo " "
  echo "-free   : Source files are in Fortran 90 Free Format"
  echo "-addflag \"Additional Compiling Arguments\" - Advanced Users Only"
  echo "-link_flags \"Additional Linking Arguments\" - Advanced Users Only"
  echo " "
  echo "----"
  echo " "
  echo " "
  exit 1
fi

libpath=${RAD_USERLIB_SDK_PATH}/${RAD_USERLIB_ARCH}

starter_files=()
engine_files=()
static_libraries=()
static_library_names=()
addflags=()
link_flags=()
free_flag=()

unquote_path() {
  local path="$1"
  path="${path#\"}"
  path="${path%\"}"
  path="${path#\'}"
  echo "${path%\'}"
}

for var in "$@"
do
    IFS='=' read -r arg value <<< "${var}"
    case "${arg}" in
      starter)
        read -ra starter_files <<< "${value}"
        for idx in "${!starter_files[@]}"; do
          curr_path="$(unquote_path "${starter_files[idx]}")"
          starter_files[idx]="${curr_path}"
        done
        ;;
      engine)
        read -ra engine_files <<< "${value}"
        for idx in "${!engine_files[@]}"; do
          curr_path="$(unquote_path "${engine_files[idx]}")"
          engine_files[idx]="${curr_path}"
        done
        ;;
      library)
        read -ra static_libraries <<< "${value}"
        for idx in "${!static_libraries[@]}"; do
          curr_path="$(unquote_path "${static_libraries[idx]}")"
          static_library_names+=( "${curr_path##*/}" )
          static_libraries[idx]="${curr_path}"
        done
        ;;
      outfile)
        outfile="${value}"
        ;;
      addflag)
        read -ra addflags <<< "${value}"
        ;;
      link_flags)
        read -ra link_flags <<< "${value}"
        ;;
      *)
        arg="$(echo "${var}"|awk '{print $1}')"
        if [[ "${arg}" == "-free" ]]
        then
          free_flag=( -ffree-form )
        fi
    esac

done

if [[ -n "${outfile}" ]]
then
  outlib=../${outfile}
  outnam=${outfile}
else
  outlib=../libraduser_linux64.so
  outnam=libraduser_linux64.so
fi

# ----------------------------------------------------------
# Check environment variables 
# if they are wrong, the static interface library could not be found
# ----------------------------------------------------------
if [[ ! -f ${libpath}/libraduser_linux64_gfortran.a ]]
then
  echo "*** Error : "
  echo " "
  echo "${libpath}/libraduser_linux64_gfortran.a"
  echo " "
  echo "not found"
  echo " "
  echo " "
  echo "Check environment variables:"
  echo " "
  echo "RAD_USERLIB_SDK_PATH"
  echo "RAD_USERLIB_ARCH"
  echo " "
  echo " "
  exit 0
fi

rundir=_obj_linux64_$$

mkdir "${rundir}"

if (( "${#starter_files[@]}" > 0 ))
then
  cp "${starter_files[@]}" "${rundir}"
fi

if (( "${#engine_files[@]}" > 0 ))
then
  cp "${engine_files[@]}" "${rundir}"
fi


#Verify if an additional statical library was set

if (( "${#static_libraries[@]}" > 0 ))
then
     cp "${static_libraries[@]}" "${rundir}"
     echo " "
     echo "adding ${static_library_names[*]} in library"
     echo "---------------------------------"
     echo " "
fi

fortran_head_args=(
  "${free_flag[@]}"
  -fintrinsic-modules-path "${libpath}"
  "${addflags[@]}" -fPIC
)

fortran_tail_args=(
  -fopenmp -DMYREAL8 -DR8 -ffixed-line-length-132
)

(
  cd "${rundir}"

  ar -x "${libpath}/libraduser_linux64_gfortran.a"

  #extract statical library
  for lib in "${static_library_names[@]}"
  do
    if [[ -f ${lib} ]]
    then
      echo "extracting ${lib}"
      ar -x "${lib}"
    fi
  done

  if (( "${#starter_files[@]}" > 0 ))
  then
    echo " "
    echo " "
    echo " Compiling: ${starter_files[*]}"
    echo "-----------"
    echo " "
    gfortran "${fortran_head_args[@]}" -O2 "${fortran_tail_args[@]}" -c "${starter_files[@]}"
  fi

  if (( "${#engine_files[@]}" > 0 ))
  then
    echo " "
    echo " "
    echo "Compiling: ${engine_files[*]}"
    echo "----------"
    echo " "
    gfortran "${fortran_head_args[@]}" -O3 "${fortran_tail_args[@]}" -c "${engine_files[@]}"
  fi



  echo " "
  echo " "
  echo "Creating library: ${outnam}"
  echo "-----------------"
  echo " "


  gfortran "${addflags[@]}" -fPIC -shared -O2 -o "${outlib}" ./*.o "${link_flags[@]}"
)

rm -rf  "${rundir}"

echo " "
echo " "
echo "Done"
echo "----"
echo " "
echo " "
