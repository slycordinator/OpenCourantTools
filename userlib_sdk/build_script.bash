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


function my_help()
{
  echo " " 
  echo " userlib_sdk build script "
  echo " -------------------------"
  echo " " 
  echo " Use with arguments : "
  echo " -arch=[linux64|linuxa64|win64]"
  echo " -compiler=[armflang|gfortran|oneapi|intel]"
  echo "            Defaults :"
  echo "              linux64  : gfortran"
  echo "              win64    : oneapi"
  echo "              linuxa64 : gfortran"
  echo " -prec=[dp|sp] "
  echo "              set precision - dp (default) |sp "
  echo " " 
  echo " -verbose : Build verbose mode."
  echo " -clean : delete build"
  echo " " 
  echo " " 
}

# -----------------------------
# Parse command line arguments
# -----------------------------
arch='none'
prec=dp
suffix=''
got_compiler=0
got_arch=0
clean=0
verbose=()

if (( $# == 0 ))
then

  my_help
  exit 1

else

   for var in "$@"
   do
      IFS='=' read -r arg val <<< "${var}"
      case "${arg}" in
        -arch)
          arch="${val}"
          got_arch=1
          ;;
        -compiler)
          compiler="${val}"
          got_compiler=1
          ;;
        -prec)
          prec="${val}"
          if [[ ${prec} == 'sp' ]]
          then
            suffix=_sp
          fi
          ;;
        -clean)
          clean=1
          ;;
        -verbose)
          verbose=( 'VERBOSE=1' )
          ;;
      esac

   done

  if (( got_arch == 0 ))
  then
     echo " Error : "
     echo " ------  "
     echo " Specify -arch option"
     echo " " 
     echo " " 
     my_help
     exit 1
  fi


  if (( got_compiler == 0 ))
  then
    case "${arch}" in
      win64) compiler=oneapi ;;
      linux64 | linuxa64) compiler=gfortran ;;
    esac
  fi

   echo " " 
   echo " Build Radioss(TM) Userlib SDK"
   echo " ------------------------------"
   echo " Build Arguments :"
   echo " arch=            $arch"
   echo " compiler=         $compiler"
   echo " " 
fi

# Library extention 

if [[ "$arch" == "win64" && "$compiler" != "gfortran" ]]
then
  lib=.lib
else
  lib=.a
fi
echo "$LIB_EXT"

# build & object directory
build_directory=cbuild_${arch}_${compiler}${suffix}
sdk_directory=${arch}${suffix}_${compiler}

# clean option
if (( clean == 1 ))
then
   if [[ -d ${build_directory} ]]
   then
     echo "Clean ${build_directory} directory"
     rm -rf "./${build_directory}"
   else
     echo "Clean ${build_directory} directory requested but not found"
   fi
   echo " " 
   exit 0
fi

# create build directory if it does not exist
mkdir -p "${build_directory}"

cmake_args=(
  -Darch="${arch}" -Dcompiler="${compiler}" -Dprecision="${prec}" ../source
)

(
  cd "${build_directory}"

  if [[ $arch == "win64" ]]
  then
    cmake -G "Unix Makefiles" "${cmake_args[@]}"
  else
    cmake "${cmake_args[@]}"
  fi

  make "${verbose[@]}"

  cp "libraduser_${arch}${suffix}_${compiler}${lib}" ./*.mod "../userlib_sdk/${sdk_directory}"

)



echo " " 
echo " Done"
echo " ----" 
echo " " 
