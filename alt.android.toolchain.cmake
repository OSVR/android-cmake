# Copyright (c) 2010-2011, Ethan Rublee
# Copyright (c) 2011-2014, Andrey Kamaev
# Copyright (c) 2015-2016, Sensics, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1.  Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#
# 2.  Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
# 3.  Neither the name of the copyright holder nor the names of its
#     contributors may be used to endorse or promote products derived from this
#     software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

# Set system name.
if( CMAKE_VERSION VERSION_GREATER "3.0.99" )
 set( CMAKE_SYSTEM_NAME Android )
else()
 set( CMAKE_SYSTEM_NAME Linux )
endif()
set(CMAKE_CROSSCOMPILING YES)
if(NOT CMAKE_ANDROID_ARCH)
    set(CMAKE_ANDROID_ARCH armv7-a)
    message(STATUS "Setting CMAKE_ANDROID_ARCH to a default value of ${CMAKE_ANDROID_ARCH}.")
endif()
if(NOT CMAKE_ANDROID_STL_TYPE)
    set(CMAKE_ANDROID_STL_TYPE "gnustl_static")
    message(STATUS "Setting CMAKE_ANDROID_STL_TYPE to a default value of ${CMAKE_ANDROID_STL_TYPE}.")
endif()

set(ANDROID_DEFAULT_API_LEVEL 16)


get_property( _CMAKE_IN_TRY_COMPILE GLOBAL PROPERTY IN_TRY_COMPILE )

if( CMAKE_TOOLCHAIN_FILE )
 # touch toolchain variable to suppress "unused variable" warning
endif()

# Setup Android NDK location, if possible.
if(NOT ANDROID_NDK OR NOT EXISTS "${ANDROID_NDK}")
    get_filename_component(ANDROID_NDK "$ENV{ANDROID_NDK}" ABSOLUTE)
    set(ANDROID_NDK ${ANDROID_NDK} CACHE PATH "The root directory of an Android NDK" FORCE)
endif()
# detect current host platform
if( NOT DEFINED ANDROID_NDK_HOST_X64 AND (CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "amd64|x86_64|AMD64" OR CMAKE_HOST_APPLE) )
    set( ANDROID_NDK_HOST_X64 1 CACHE BOOL "Try to use 64-bit compiler toolchain" )
    mark_as_advanced( ANDROID_NDK_HOST_X64 )
endif()
if( CMAKE_HOST_APPLE )
    set( ANDROID_NDK_HOST_SYSTEM_NAME "darwin-x86_64" )
    set( ANDROID_NDK_HOST_SYSTEM_NAME2 "darwin-x86" )
elseif( CMAKE_HOST_WIN32 )
    set( ANDROID_NDK_HOST_SYSTEM_NAME "windows-x86_64" )
    set( ANDROID_NDK_HOST_SYSTEM_NAME2 "windows" )
    set( TOOL_OS_SUFFIX ".exe" )
    set(ANDROID_NDK_BUILD_SUFFIX .cmd)
elseif( CMAKE_HOST_UNIX )
    set( ANDROID_NDK_HOST_SYSTEM_NAME "linux-x86_64" )
    set( ANDROID_NDK_HOST_SYSTEM_NAME2 "linux-x86" )
else()
    message( FATAL_ERROR "Cross-compilation on your platform is not supported by this cmake toolchain" )
endif()

if( NOT ANDROID_NDK_HOST_X64 )
    set( ANDROID_NDK_HOST_SYSTEM_NAME ${ANDROID_NDK_HOST_SYSTEM_NAME2} )
endif()

set( ANDROID_NDK_TOOLCHAINS_PATH "${ANDROID_NDK}/toolchains" )
set( ANDROID_NDK_TOOLCHAINS_SUBPATH  "/prebuilt/${ANDROID_NDK_HOST_SYSTEM_NAME}" )
set( ANDROID_NDK_TOOLCHAINS_SUBPATH2 "/prebuilt/${ANDROID_NDK_HOST_SYSTEM_NAME2}" )

find_program(ANDROID_NDK_BUILD
    NAMES
    ndk-build${ANDROID_NDK_BUILD_SUFFIX}
    HINTS
    ${ANDROID_NDK}
    DOC "Root directory of android NDK")

if(NOT ANDROID_NDK_BUILD)
    message(FATAL_ERROR "Need the Android NDK path set, by finding the ndk-build command! Set ANDROID_NDK in environment or CMake! Current value of ANDROID_NDK=${ANDROID_NDK}")
endif()

# Get release info.
include("${CMAKE_CURRENT_LIST_DIR}/AndroidNdkParseVersion.cmake")
if(NOT ANDROID_NDK_VARIANT)
    android_ndk_parse_version("${ANDROID_NDK}" ANDROID_NDK_VARIANT ANDROID_NDK_RELEASE_VER ANDROID_NDK_RELEASE ANDROID_NDK_RELEASE_FULL)
    if(ANDROID_NDK_VARIANT STREQUAL "CrystaX")
        set(ANDROID_CRYSTAX_NDK ON)
        option(ANDROID_CRYSTAX_NDK_SHARED_LIBCRYSTAX "Build against the shared, rather than static, libcrystax?" off)
    endif()

    if(ANDROID_NDK_VARIANT STREQUAL "Android")
        message(STATUS "Building using an apparently stock/official Google Android NDK")
    elseif(ANDROID_NDK_VARIANT STREQUAL "CrystaX")
        message(STATUS "Building using a CrystaX NDK")
    elseif(ANDROID_NDK_VARIANT STREQUAL "ThirdParty")
        message(STATUS "Building using an unrecognized third-party NDK")
    else()
        message(STATUS "Building using an NDK that was neither classified as official nor third-party - should not happen!")
    endif()

    if(ANDROID_NDK_RELEASE_VER)
        message(STATUS "ANDROID_NDK_RELEASE_VER ${ANDROID_NDK_RELEASE_VER}")
    endif()
endif()

# Data tables for each architecture
# Keys:
# - CMAKE_SYS_PROC - Value for CMAKE_SYSTEM_PROCESSOR
# - ANDROID_ABI
# - GCC_PREFIX - Thing that goes before -gcc and the binutils, also used in toolchain dir names.
# - LLVM_TARGET - The target "triple" passed to LLVM/Clang toolchains for this arch
# - TOOLCHAIN_ARCH - Just "arm", etc - the thing under the platform and api level directory.
# - C_FLAGS - flags to add to c/c++ compilation
# - ID_VAR - A variable to set to TRUE to indicate this architecture.
set(_ANDROID_ARCH_CMAKE_SYS_PROC_armv7_a "armv7-a")
set(_ANDROID_ARCH_ANDROID_ABI_armv7_a "armeabi-v7a")
set(_ANDROID_ARCH_GCC_PREFIX_armv7_a "arm-linux-androideabi")
set(_ANDROID_ARCH_LLVM_TARGET_armv7_a "armv7-none-linux-androideabi")
set(_ANDROID_ARCH_TOOLCHAIN_ARCH_armv7_a "arm")
set(_ANDROID_ARCH_C_FLAGS_armv7_a "-march=armv7-a -mfloat-abi=softfp -Wl,--fix-cortex-a8")
set(_ANDROID_ARCH_ID_VAR_armv7_a "ARMEABI_V7A")

# Retreive per-architecture data.
function(_android_get_arch_info _arch _info _var)
    # Make a legal variable name.
    string(MAKE_C_IDENTIFIER "${_arch}" archCleaned)
    set(varName _ANDROID_ARCH_${_info}_${archCleaned})
    set(_result ${${varName}})
    if(NOT _result)
        message(FATAL_ERROR "Arch ${_arch} not currently supported (no value found for ${varName})")
    endif()
    set(${_var} ${_result} PARENT_SCOPE)
endfunction()

# Set CMAKE_SYSTEM_PROCESSOR
_android_get_arch_info(${CMAKE_ANDROID_ARCH} CMAKE_SYS_PROC CMAKE_SYSTEM_PROCESSOR)

# Set ID VAR - like ARMEABI_V7A
_android_get_arch_info(${CMAKE_ANDROID_ARCH} ID_VAR _android_id_var)
set(${_android_id_var} TRUE)

# set ANDROID_GCC_PREFIX
_android_get_arch_info(${CMAKE_ANDROID_ARCH} GCC_PREFIX ANDROID_GCC_PREFIX)

# set _CMAKE_TOOLCHAIN_PREFIX - used by CMakeDetermineCompiler and friends.
set(_CMAKE_TOOLCHAIN_PREFIX "${ANDROID_GCC_PREFIX}-")

# set ANDROID_NDK_ABI_NAME
_android_get_arch_info(${CMAKE_ANDROID_ARCH} ANDROID_ABI ANDROID_NDK_ABI_NAME)

if(NOT ANDROID_TOOLCHAIN_NAME)
    set(TOOLCHAIN_PRIORITY_LIST ${ANDROID_GCC_PREFIX}-4.9 llvm llvm-3.7 )
    foreach(__TOOLCHAIN ${TOOLCHAIN_PRIORITY_LIST})
        if(EXISTS "${ANDROID_NDK_TOOLCHAINS_PATH}/${__TOOLCHAIN}${ANDROID_NDK_TOOLCHAINS_SUBPATH}")
            set(ANDROID_TOOLCHAIN_NAME "${__TOOLCHAIN}")
            break()
        endif()
    endforeach()
endif()

if(NOT ANDROID_TOOLCHAIN_NAME)
    message(FATAL_ERROR "Couldn't auto-set ANDROID_TOOLCHAIN_NAME - try setting it yourself!")
endif()

set(ANDROID_NDK_TOOLCHAIN_PATH "${ANDROID_NDK_TOOLCHAINS_PATH}/${ANDROID_TOOLCHAIN_NAME}${ANDROID_NDK_TOOLCHAINS_SUBPATH}")

if("${ANDROID_TOOLCHAIN_NAME}" MATCHES "clang" OR "${ANDROID_TOOLCHAIN_NAME}" MATCHES "llvm")
    set(ANDROID_COMPILER_IS_CLANG TRUE)
else()
    set(ANDROID_COMPILER_IS_CLANG FALSE)
endif()

###
# Set the ANDROID_GCC_TOOLCHAIN_NAME
if(ANDROID_COMPILER_IS_CLANG)
    # todo how to pick the right version?
    set(ANDROID_GCC_TOOLCHAIN_NAME ${ANDROID_GCC_PREFIX}-4.9)
else()
    set(ANDROID_GCC_TOOLCHAIN_NAME ${ANDROID_TOOLCHAIN_NAME})
endif()

# Extract the (GCC) compiler version
if(NOT ANDROID_GCC_VERSION)
    string(REGEX REPLACE ".*-([.0-9]+)$" "\\1" ANDROID_GCC_VERSION "${ANDROID_GCC_TOOLCHAIN_NAME}")
    message(STATUS "ANDROID_GCC_VERSION ${ANDROID_GCC_VERSION}")
endif()

set(ANDROID_GCC_TOOLCHAIN_PREBUILT_ROOT "${ANDROID_NDK_TOOLCHAINS_PATH}/${ANDROID_GCC_TOOLCHAIN_NAME}${ANDROID_NDK_TOOLCHAINS_SUBPATH}")
set(_CMAKE_TOOLCHAIN_LOCATION "${ANDROID_GCC_TOOLCHAIN_PREBUILT_ROOT}")
# Given something like "strip", gives you the full "C:\Users\Ryan\Desktop\deps\crystax-ndk-10.3.1\toolchains\arm-linux-androideabi-4.9\prebuilt\windows-x86_64\bin\arm-linux-androideabi-ld.exe"
function(_android_get_gcc_toolchain_binary _tool _var)
    get_filename_component(location
        "${ANDROID_GCC_TOOLCHAIN_PREBUILT_ROOT}/bin/${ANDROID_GCC_PREFIX}-${_tool}${TOOL_OS_SUFFIX}"
        ABSOLUTE)
    if(location)
        message(STATUS "${_tool}: ${location}")
        set(${_var} "${location}" PARENT_SCOPE)
    endif()
endfunction()
###
# Set up the auxiliary tools (ld, ar, and so on)

if(NOT CMAKE_AR)
    # Prefer gcc-ar if we have it for LTO support.
    _android_get_gcc_toolchain_binary(gcc-ar ANDROID_GCC_AR)
    if(EXISTS "${ANDROID_GCC_AR}")
        set(CMAKE_AR "${ANDROID_GCC_AR}" CACHE FILEPATH "" FORCE)
    else()
        _android_get_gcc_toolchain_binary(ar CMAKE_AR)
        set(CMAKE_AR "${CMAKE_AR}" CACHE FILEPATH "" FORCE)
    endif()
endif()

#todo consider using CMakeFindBinUtils here? (It won't do the gcc-ar trick above, but it can do the rest.)
# _android_get_gcc_toolchain_binary(ld CMAKE_LINKER)
# _android_get_gcc_toolchain_binary(nm CMAKE_NM)
# _android_get_gcc_toolchain_binary(objcopy CMAKE_OBJCOPY)
# _android_get_gcc_toolchain_binary(objdump CMAKE_OBJDUMP)
# _android_get_gcc_toolchain_binary(ranlib CMAKE_RANLIB)
include(CMakeFindBinUtils)


_android_get_arch_info(${CMAKE_ANDROID_ARCH} C_FLAGS ANDROID_ARCH_C_FLAGS)

set(CMAKE_CFAMILY_COMPILER_ARG1 "${ANDROID_ARCH_C_FLAGS}")
set(CMAKE_C_COMPILER_ARG1)
set(CMAKE_CXX_COMPILER_ARG1)
set(ANDROID_COMMON_LINKER_FLAGS_INIT "-Wl,--build-id")
set(ANDROID_CXX_LINKER_FLAGS_INIT)
set(CMAKE_CXX_STANDARD_LIBRARIES_INIT)

if(ANDROID_COMPILER_IS_CLANG)
    _android_get_arch_info(${CMAKE_ANDROID_ARCH} LLVM_TARGET ANDROID_LLVM_TARGET)
    set(CMAKE_C_COMPILER "${ANDROID_NDK_TOOLCHAIN_PATH}/bin/clang${TOOL_OS_SUFFIX}")
    #set(CMAKE_C_COMPILER_ARG1 "-target ${ANDROID_LLVM_TARGET} -gcc-toolchain ${ANDROID_GCC_TOOLCHAIN_PREBUILT_ROOT}")
    set(CMAKE_CFAMILY_COMPILER_ARG1 "-gcc-toolchain ${ANDROID_GCC_TOOLCHAIN_PREBUILT_ROOT}")
    set(CMAKE_CFAMILY_COMPILER_TARGET "${ANDROID_LLVM_TARGET}")

    set(CMAKE_CXX_COMPILER "${ANDROID_NDK_TOOLCHAIN_PATH}/bin/clang++${TOOL_OS_SUFFIX}")
    #set(CMAKE_CXX_COMPILER_ARG1 "-target ${ANDROID_LLVM_TARGET} -gcc-toolchain ${ANDROID_GCC_TOOLCHAIN_PREBUILT_ROOT}")
    #set(CMAKE_CXX_COMPILER_ARG1 "-gcc-toolchain ${ANDROID_GCC_TOOLCHAIN_PREBUILT_ROOT}")
    #set(CMAKE_CXX_COMPILER_TARGET "${ANDROID_LLVM_TARGET}")
else()
    _android_get_gcc_toolchain_binary(gcc CMAKE_C_COMPILER)
    _android_get_gcc_toolchain_binary(g++ CMAKE_CXX_COMPILER)
endif()

_android_get_arch_info(${CMAKE_ANDROID_ARCH} TOOLCHAIN_ARCH ANDROID_ARCH_NAME)
set(_prop "$<TARGET_PROPERTY:ANDROID_API_MIN>")
set(ANDROID_API_LEVEL_TARGET_GENERATOR_EXPRESSION $<$<BOOL:${_prop}>:${_prop}:${ANDROID_DEFAULT_API_LEVEL}>)
set(CMAKE_SYSROOT ${ANDROID_NDK}/platforms/android-${ANDROID_DEFAULT_API_LEVEL}/arch-${ANDROID_ARCH_NAME})

if(NOT ${ANDROID_DEFAULT_API_LEVEL} LESS 16)
    # API level 16 and up: default to -fPIE.
    set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
endif()

if(ANDROID_ARCH_NAME STREQUAL "arm" AND NOT ANDROID_FORCE_ARM_BUILD)
    # We turn on thumb mode now.
    set(ANDROID_THUMB ON)
    set(CMAKE_CFAMILY_COMPILER_ARG1 "${CMAKE_CFAMILY_COMPILER_ARG1} -mthumb")
    list(APPEND ANDROID_LD_FLAGS "")
else()
    set(ANDROID_THUMB OFF)
endif()

# Now, handle STL.
function(_android_get_stl_info _stl _rttiVar _exceptVar _incVar _libVar _libSupVar)
    set(__libstl)
    if( "${_stl}" STREQUAL "none" )
        # do nothing
    elseif( "${_stl}" STREQUAL "system" )
        set( "${_rttiVar}"             OFF PARENT_SCOPE)
        set( "${_exceptVar}"       OFF  PARENT_SCOPE)
        set( "${_incVar}" "${ANDROID_NDK}/sources/cxx-stl/system/include"  PARENT_SCOPE)
    elseif( "${_stl}" STREQUAL "system_re" )
        set( "${_rttiVar}"             ON  PARENT_SCOPE)
        set( "${_exceptVar}"       ON  PARENT_SCOPE)
        set( "${_incVar}" "${ANDROID_NDK}/sources/cxx-stl/system/include"  PARENT_SCOPE)
    elseif( "${_stl}" MATCHES "gabi" )
        # not available before r7, but that's ok, that's really old.
        set( "${_rttiVar}"             ON  PARENT_SCOPE)
        set( "${_exceptVar}"       OFF  PARENT_SCOPE)
        set( "${_incVar}" "${ANDROID_NDK}/sources/cxx-stl/gabi++/include"  PARENT_SCOPE)
        set(__libstl                 "${ANDROID_NDK}/sources/cxx-stl/gabi++/libs/${ANDROID_NDK_ABI_NAME}/libgabi++_static.a"  PARENT_SCOPE)
    elseif( "${_stl}" MATCHES "stlport" )
        # different before r8d
        set( "${_exceptVar}"       ON  PARENT_SCOPE)
        # different before r7
        set( "${_rttiVar}"            ON  PARENT_SCOPE)
        set( "${_incVar}" "${ANDROID_NDK}/sources/cxx-stl/stlport/stlport"  PARENT_SCOPE)
        set(__libstl                 "${ANDROID_NDK}/sources/cxx-stl/stlport/libs/${ANDROID_NDK_ABI_NAME}/libstlport_static.a"  PARENT_SCOPE)
    elseif( "${_stl}" MATCHES "gnustl" )
        set( "${_exceptVar}"       ON  PARENT_SCOPE)
        set( "${_rttiVar}"             ON  PARENT_SCOPE)
        # Note: r8d binary for the 4.7 compiler is buggy - but r8d is old.
        set( __libdirstl                "${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/${ANDROID_GCC_VERSION}" )
        if(NOT EXISTS "${__libdirstl}")
            set( __libdirstl                "${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++" )
        endif()
        set( "${_incVar}" "${__libdirstl}/include" "${__libdirstl}/libs/${ANDROID_NDK_ABI_NAME}/include" "${__libdirstl}/include/backward" PARENT_SCOPE)
        set(__libstl                "${__libdirstl}/libs/${ANDROID_NDK_ABI_NAME}/libgnustl_static.a")
        if( NOT EXISTS "${__libstl}" )
            set(__libstl                "${__libdirstl}/libs/${ANDROID_NDK_ABI_NAME}/libstdc++.a")
        endif()
    else()
        message( FATAL_ERROR "Unknown runtime: ${_stl}" )
    endif()
    if(__libstl)
        if("${_stl}" MATCHES "shared")
            if("${__libstl}" MATCHES "static.a")
                string( REPLACE "_static.a" "_shared.so" __libstl "${__libstl}" )
                # TODO: check if .so file exists before the renaming
            else()
                message(FATAL_ERROR "Don't know how to get shared STL of type ${_stl}")
            endif()
        endif()
        message(STATUS "STL Library: ${__libstl}")
        set(${_libVar} "${__libstl}" PARENT_SCOPE)
    endif()

    # find libsupc++.a - rtti & exceptions
    set(__libsupcxx)
    if( "${_stl}" STREQUAL "system_re" OR "${_stl}" MATCHES "gnustl" )
        set( __libsupcxx "${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/${ANDROID_GCC_VERSION}/libs/${ANDROID_NDK_ABI_NAME}/libsupc++.a" ) # r8b or newer
        if( NOT EXISTS "${__libsupcxx}" )
            set( __libsupcxx "${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/libs/${ANDROID_NDK_ABI_NAME}/libsupc++.a" ) # r7-r8
        endif()
    endif()
    if(__libsupcxx)
        set(${_libSupVar} "${__libsupcxx}" PARENT_SCOPE)
    endif()

endfunction()

_android_get_stl_info(${CMAKE_ANDROID_STL_TYPE} ANDROID_RTTI ANDROID_EXCEPTIONS ANDROID_STL_INCLUDE_DIRS ANDROID_STL_LIBRARY ANDROID_STL_SUPPORT_LIBRARY)
if(ANDROID_EXCEPTIONS)
    set(CMAKE_CXX_COMPILER_ARG1 "${CMAKE_CXX_COMPILER_ARG1} -fexceptions")
else()
    set(CMAKE_CXX_COMPILER_ARG1 "${CMAKE_CXX_COMPILER_ARG1} -fno-exceptions")
endif()
if(ANDROID_RTTI)
    set(CMAKE_CXX_COMPILER_ARG1 "${CMAKE_CXX_COMPILER_ARG1} -frtti")
else()
    set(CMAKE_CXX_COMPILER_ARG1 "${CMAKE_CXX_COMPILER_ARG1} -fno-rtti")
endif()
if(ANDROID_STL_INCLUDE_DIRS)
    foreach(_inc_dir ${ANDROID_STL_INCLUDE_DIRS})
        set(CMAKE_CXX_COMPILER_ARG1 "${CMAKE_CXX_COMPILER_ARG1} -isystem ${_inc_dir}")
    endforeach()
endif()
if(ANDROID_STL_LIBRARY)
    set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_STL_LIBRARY}")
    #set(ANDROID_CXX_LINKER_FLAGS_INIT "${ANDROID_CXX_LINKER_FLAGS_INIT} ${ANDROID_STL_LIBRARY}")
endif()
if(ANDROID_STL_SUPPORT_LIBRARY)
    set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_CXX_STANDARD_LIBRARIES_INIT} ${ANDROID_STL_SUPPORT_LIBRARY}")
    #set(ANDROID_CXX_LINKER_FLAGS_INIT "${ANDROID_CXX_LINKER_FLAGS_INIT} ${ANDROID_STL_SUPPORT_LIBRARY}")
endif()

if(ARMEABI_V7A)
    set(ANDROID_COMMON_LINKER_FLAGS_INIT "${ANDROID_COMMON_LINKER_FLAGS_INIT} -Wl,--fix-cortex-a8")
endif()

# Set the C and CXX variables from the shared CFAMILY variables
set(CMAKE_C_COMPILER_ARG1 "${CMAKE_CFAMILY_COMPILER_ARG1} ${CMAKE_C_COMPILER_ARG1}")
set(CMAKE_CXX_COMPILER_ARG1 "${CMAKE_CFAMILY_COMPILER_ARG1} ${CMAKE_CXX_COMPILER_ARG1}")
if(CMAKE_CFAMILY_COMPILER_TARGET)
    set(CMAKE_C_COMPILER_TARGET "${CMAKE_CFAMILY_COMPILER_TARGET}")
    set(CMAKE_CXX_COMPILER_TARGET "${CMAKE_CFAMILY_COMPILER_TARGET}")
endif()

set(CMAKE_EXE_LINKER_FLAGS_INIT "${ANDROID_COMMON_LINKER_FLAGS_INIT}")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${ANDROID_COMMON_LINKER_FLAGS_INIT}")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "${ANDROID_COMMON_LINKER_FLAGS_INIT}")
set(CMAKE_STATIC_LINKER_FLAGS_INIT "")

# set these global flags for cmake client scripts to change behavior
set( ANDROID True )
set( BUILD_ANDROID True )
