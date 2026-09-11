#------------------------------------------------------------------------------#
# Returns artifact version.
#
# The name of function must consist of folder name (probe-rs) and postfix
# (_GetArtifactVersion). Otherwise the buildprocess will fail.
#
# ARTIFACT_VERSION [out]: Version of artifact in format X.Y.Z
#------------------------------------------------------------------------------#
function(probe-rs_GetArtifactVersion RET_VERSION)

    execute_process(COMMAND probe-rs --version
                    OUTPUT_VARIABLE ARTIFACT_VERSION
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" VERSION "${ARTIFACT_VERSION}")

    set(${RET_VERSION} "${VERSION}" PARENT_SCOPE)

endfunction()


#------------------------------------------------------------------------------#
# Initialize artifact for build.
#
# The name of function must consist of folder name (probe-rs) and postfix
# (_ArtifactInit). Otherwise the buildprocess will fail.
#
# probe-rs is a debug/flash toolset, not a compiler toolchain – unlike
# gcc-arm-none-eabi this only needs to put the resolved bin/ directory on
# PATH (exposing probe-rs, cargo-flash, cargo-embed together). No
# CMAKE_TOOLCHAIN_FILE is set and no companion .cmake file is required.
#
# NOTE: set(ENV{PATH} ...) below only affects the running CMake configure
# process. It does NOT reach commands added via add_custom_target/
# add_custom_command, since those run later as a separate build-tool
# process (ninja/make) that does not inherit configure-time ENV changes.
# For that reason this function also exports the resolved absolute
# executable path as the CACHE variable PROBE_RS_EXECUTABLE – use that
# (not a bare "probe-rs") inside any COMMAND that runs at build time, e.g.:
#
#   add_custom_target(flash
#       COMMAND ${PROBE_RS_EXECUTABLE} download --chip ... $<TARGET_FILE:${PROJECT_NAME}>
#       COMMAND ${PROBE_RS_EXECUTABLE} reset --chip ...
#       DEPENDS ${PROJECT_NAME}
#       USES_TERMINAL)
#
# ARTIFACT_BIN_PATH_ARG [in]: Path to the binary part of artifact
#------------------------------------------------------------------------------#
function(probe-rs_ArtifactInit ARTIFACT_BIN_PATH_ARG)

    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")

        file(GLOB_RECURSE ALL_CONFIG_FILES "${ARTIFACT_BIN_PATH_ARG}/*probe-rs.exe")

        foreach(FILE_PATH IN LISTS ALL_CONFIG_FILES)
            if(FILE_PATH MATCHES "probe-rs.exe")
                get_filename_component(CONFIG_DIR ${FILE_PATH} DIRECTORY)
                set(RESOLVED_EXECUTABLE "${FILE_PATH}")
                break()
            endif()
        endforeach()

        if(CONFIG_DIR)

            message(STATUS "File probe-rs.exe found in: ${CONFIG_DIR}")

            set(ENV{PATH} "${CONFIG_DIR};$ENV{PATH}")

            set(ENV{PATH} "${ARTIFACT_BIN_PATH_ARG}/;$ENV{PATH}")

        else()

            message(FATAL_ERROR "File probe-rs.exe not found.")

        endif()

    else()

        file(GLOB_RECURSE ALL_CONFIG_FILES "${ARTIFACT_BIN_PATH_ARG}/*probe-rs")

        foreach(FILE_PATH IN LISTS ALL_CONFIG_FILES)
            if(FILE_PATH MATCHES "probe-rs$")
                get_filename_component(CONFIG_DIR ${FILE_PATH} DIRECTORY)
                set(RESOLVED_EXECUTABLE "${FILE_PATH}")
                break()
            endif()
        endforeach()

        if(CONFIG_DIR)

            message(STATUS "File probe-rs found in: ${CONFIG_DIR}")

            set(ENV{PATH} "${CONFIG_DIR}:$ENV{PATH}")

            set(ENV{PATH} "${ARTIFACT_BIN_PATH_ARG}:$ENV{PATH}")

        else()

            message(FATAL_ERROR "File probe-rs not found.")

        endif()

    endif()

    set(PROBE_RS_EXECUTABLE "${RESOLVED_EXECUTABLE}" CACHE FILEPATH "Absolute path to the resolved probe-rs executable" FORCE)

    message(DEBUG "probe-rs was added to PATH from: ${CONFIG_DIR}")
    message(DEBUG "PROBE_RS_EXECUTABLE set to: ${PROBE_RS_EXECUTABLE}")

endfunction()