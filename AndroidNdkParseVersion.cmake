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

function(android_ndk_parse_version _android_ndk _variantVar _releaseVerVar _releaseVar _releaseFullVar)
    set(ANDROID_NDK ${_android_ndk})
    set(VARIANT NOTFOUND)
    set(ANDROID_NDK_RELEASE_VER NOTFOUND)
    set(ANDROID_NDK_RELEASE NOTFOUND)
    if(EXISTS "${ANDROID_NDK}/RELEASE.TXT")
        file(STRINGS "${ANDROID_NDK}/RELEASE.TXT" ANDROID_NDK_RELEASE_FULL LIMIT_COUNT 1 REGEX "r[0-9]+[a-z]?")
        if(ANDROID_NDK_RELEASE_FULL)
            # Looks like it might be an official NDK - set ANDROID_NDK_RELEASE, ANDROID_NDK_RELEASE_NUM = major * 1000 + revision (a, b, c...),
            # as well as ANDROID_NDK_RELEASE_VER, which is a dotted decimal major.0.revision to match r12+

            # Apparently official
            set(VARIANT Android)

            string(REGEX MATCH "r([0-9]+)([a-z]?)" ANDROID_NDK_RELEASE "${ANDROID_NDK_RELEASE_FULL}" )
            string(REGEX REPLACE "r([0-9]+)([a-z]?)" "\\1*1000" ANDROID_NDK_RELEASE_NUM "${ANDROID_NDK_RELEASE}" )
            string(FIND " abcdefghijklmnopqastuvwxyz" "${CMAKE_MATCH_2}" __ndkReleaseLetterNum )
            #math(EXPR ANDROID_NDK_RELEASE_NUM "${ANDROID_NDK_RELEASE_NUM}+${__ndkReleaseLetterNum}" )
            set(ANDROID_NDK_RELEASE_VER "${ANDROID_NDK_RELEASE_NUM}.0.${__ndkReleaseLetterNum}")
        else()
            # OK, not apparently an official Google release but it's got a RELEASE.txt file.
            file(STRINGS "${ANDROID_NDK}/RELEASE.TXT" ANDROID_NDK_GENERIC_RELEASE_FULL LIMIT_COUNT 1 REGEX "[^ ]+")
            if(ANDROID_NDK_GENERIC_RELEASE_FULL)
                string(REGEX MATCH "^[^ ]+" ANDROID_NDK_GENERIC_RELEASE "${ANDROID_NDK_GENERIC_RELEASE_FULL}")
                set(ANDROID_NDK_RELEASE_THIRD_PARTY True)
                set(VARIANT ThirdParty)
                set(ANDROID_NDK_RELEASE ${ANDROID_NDK_GENERIC_RELEASE})
                set(ANDROID_NDK_RELEASE_FULL ${ANDROID_NDK_GENERIC_RELEASE_FULL})
            endif()
        endif()
    elseif(EXISTS "${ANDROID_NDK}/source.properties")
        set(_fn "${ANDROID_NDK}/source.properties")
        file(STRINGS "${_fn}" ANDROID_NDK_PKG_DESC_LINE LIMIT_COUNT 1 REGEX "Pkg.Desc =.*")
        file(STRINGS "${_fn}" ANDROID_NDK_PKG_REVISION_LINE LIMIT_COUNT 1 REGEX "Pkg.Revision =.*")
        if(ANDROID_NDK_PKG_DESC_LINE)
            string(REGEX REPLACE "^[^=]* = (.+)$" "\\1" ANDROID_NDK_RELEASE_FULL "${ANDROID_NDK_PKG_DESC_LINE}")
            if("${ANDROID_NDK_PKG_DESC_LINE}" MATCHES "= Android NDK$")
                # Looks official
                set(VARIANT Android)
            endif()
        endif()
        if(ANDROID_NDK_PKG_REVISION_LINE)
            string(REGEX REPLACE "^[^=]* = ([0-9]+(\\.[0-9]+)+)$" "\\1" ANDROID_NDK_RELEASE_VER "${ANDROID_NDK_PKG_REVISION_LINE}")
            set(ANDROID_NDK_RELEASE "${ANDROID_NDK_RELEASE_VER}")
            set(ANDROID_NDK_RELEASE_FULL "${ANDROID_NDK_RELEASE_FULL} ${ANDROID_NDK_PKG_REVISION_LINE}")
        endif()
    endif()

    if(ANDROID_NDK_RELEASE_THIRD_PARTY)
        if(ANDROID_NDK_GENERIC_RELEASE MATCHES "crystax-ndk")
            set(VARIANT CrystaX)
        # Add more variants here as they are found and recognized.
        endif()
    endif()
    # return values
    set(${_variantVar} "${VARIANT}" PARENT_SCOPE)
    set(${_releaseVerVar} "${ANDROID_NDK_RELEASE_VER}" PARENT_SCOPE)
    set(${_releaseVar} "${ANDROID_NDK_RELEASE}" PARENT_SCOPE)
    set(${_releaseFullVar} "${ANDROID_NDK_RELEASE_FULL}" PARENT_SCOPE)
endfunction()
