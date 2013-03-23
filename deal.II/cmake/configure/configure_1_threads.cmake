#####
##
## Copyright (C) 2012, 2013 by the deal.II authors
##
## This file is part of the deal.II library.
##
## <TODO: Full License information>
## This file is dual licensed under QPL 1.0 and LGPL 2.1 or any later
## version of the LGPL license.
##
## Author: Matthias Maier <matthias.maier@iwr.uni-heidelberg.de>
##
#####


#
# Configuration for thread support in deal.II with the help of the tbb
# library:
#


#
# Set up genereal threading:
# The macro will be included in CONFIGURE_FEATURE_THREADS_EXTERNAL/BUNDLED.
#
MACRO(SETUP_THREADING)
  FIND_PACKAGE(Threads)

  IF(NOT Threads_FOUND)
    # TODO:
    MESSAGE(FATAL_ERROR
      "\nInternal configuration error: No Threading support found\n\n"
      )
  ENDIF()

  MARK_AS_ADVANCED(pthread_LIBRARY)

  #
  # Change -lphtread to -pthread for better compatibility on non linux
  # platforms:
  #
  IF("${CMAKE_THREAD_LIBS_INIT}" MATCHES "-lpthread")
    CHECK_CXX_COMPILER_FLAG("-pthread"
      DEAL_II_HAVE_FLAG_pthread
      )
    IF(DEAL_II_HAVE_FLAG_pthread)
      STRING(REPLACE "-lpthread" "-pthread" CMAKE_THREAD_LIBS_INIT
        "${CMAKE_THREAD_LIBS_INIT}"
        )
    ENDIF()
  ENDIF()

  ADD_FLAGS(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_THREAD_LIBS_INIT}")

  #
  # Set up some posix thread specific configuration toggles:
  #
  IF(NOT CMAKE_SYSTEM_NAME MATCHES "Windows")

    IF(NOT CMAKE_USE_PTHREADS_INIT)
      MESSAGE(FATAL_ERROR
        "\nInternal configuration error: Not on Windows but posix thread support unavailable\n\n"
        )
    ENDIF()

    SET(DEAL_II_USE_MT_POSIX TRUE)

    #
    # Check whether posix thread barriers are available:
    #
    ADD_FLAGS(CMAKE_REQUIRED_FLAGS "${CMAKE_THREAD_LIBS_INIT}")
    CHECK_CXX_SOURCE_COMPILES(
    "
    #include <pthread.h>
    int main()
    {
      pthread_barrier_t pb;
      pthread_barrier_init (&pb, 0, 1);
      pthread_barrier_wait (&pb);
      pthread_barrier_destroy (&pb);
      return 0;
    }
    "
    DEAL_II_HAVE_MT_POSIX_BARRIERS)
    STRIP_FLAG(CMAKE_REQUIRED_FLAGS "${CMAKE_THREAD_LIBS_INIT}")
    IF(NOT DEAL_II_HAVE_MT_POSIX_BARRIERS)
      SET(DEAL_II_USE_MT_POSIX_NO_BARRIERS TRUE)
    ENDIF()

  ELSE()

    #
    # Poor Windows:
    #
    SET(DEAL_II_USE_MT_POSIX FALSE)
    SET(DEAL_II_USE_MT_POSIX_NO_BARRIERS TRUE)
  ENDIF()

ENDMACRO()


#
# Set up the tbb library:
#

MACRO(FEATURE_THREADS_FIND_EXTERNAL var)
  FIND_PACKAGE(TBB)

  IF(TBB_FOUND)
    SET(${var} TRUE)
  ENDIF()
ENDMACRO()


MACRO(FEATURE_THREADS_CONFIGURE_EXTERNAL)
  INCLUDE_DIRECTORIES(${TBB_INCLUDE_DIR})

  SPLIT_DEBUG_RELEASE(_tbb_debug _tbb_release ${TBB_LIBRARIES})

  IF(CMAKE_BUILD_TYPE MATCHES "Debug")
    IF(TBB_WITH_DEBUG_LIB)
      LIST(APPEND DEAL_II_DEFINITIONS_DEBUG
        "TBB_USE_DEBUG=1" "TBB_DO_ASSERT=1"
        )
    ENDIF()

    LIST(APPEND DEAL_II_EXTERNAL_LIBRARIES_DEBUG ${_tbb_debug})
  ENDIF()

  IF(CMAKE_BUILD_TYPE MATCHES "Release")
    LIST(APPEND DEAL_II_EXTERNAL_LIBRARIES_RELEASE ${_tbb_release})
  ENDIF()

  SETUP_THREADING()
ENDMACRO()


MACRO(FEATURE_THREADS_CONFIGURE_BUNDLED)
  #
  # Setup threading (before configuring our build...)
  #
  SETUP_THREADING()

  #
  # We have to disable a bunch of warnings:
  #
  ENABLE_IF_SUPPORTED(CMAKE_CXX_FLAGS "-Wno-parentheses")
  ENABLE_IF_SUPPORTED(CMAKE_CXX_FLAGS "-Wno-long-long")

  #
  # Add some definitions to use the header files in debug mode:
  #
  IF (CMAKE_BUILD_TYPE MATCHES "Debug")
    LIST(APPEND DEAL_II_DEFINITIONS_DEBUG
      "TBB_DO_DEBUG=1" "TBB_DO_ASSERT=1"
      )
  ENDIF()

  #
  # tbb uses dlopen/dlclose, so link against libdl.so as well:
  #
  FIND_LIBRARY(dl_lib NAMES dl)
  MARK_AS_ADVANCED(dl_lib)
  IF(NOT dl_lib MATCHES "-NOTFOUND")
    LIST(APPEND DEAL_II_EXTERNAL_LIBRARIES ${dl_lib})
  ENDIF()

  INCLUDE_DIRECTORIES(${TBB_FOLDER}/include)
ENDMACRO()


CONFIGURE_FEATURE(THREADS)
