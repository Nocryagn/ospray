## Copyright 2009-2020 Intel Corporation
## SPDX-License-Identifier: Apache-2.0

macro(ospray_install_namelink NAME)
  get_filename_component(TARGET_NAME ${NAME} NAME) # strip path
  set(LIB_SUFFIX ${CMAKE_SHARED_LIBRARY_SUFFIX})
  # strip version and lib suffix
  if(APPLE)
    set(LIBREGEX "(.+)[.]([0-9]+)([.][0-9]+[.][0-9]+)?${LIB_SUFFIX}")
  else()
    set(LIBREGEX "(.+)${LIB_SUFFIX}[.]([0-9]+)([.][0-9]+[.][0-9]+)?")
  endif()
  string(REGEX REPLACE ${LIBREGEX} "\\1" BASE_LIB_NAME ${TARGET_NAME})

  if (CMAKE_MATCH_COUNT)
    set(SYMLINK ${CMAKE_CURRENT_BINARY_DIR}/${BASE_LIB_NAME}${LIB_SUFFIX})
    execute_process(COMMAND "${CMAKE_COMMAND}" -E
        create_symlink ${TARGET_NAME} ${SYMLINK})
    install(PROGRAMS ${SYMLINK} DESTINATION ${CMAKE_INSTALL_LIBDIR}
        COMPONENT redist)
  endif()
   
  if (CMAKE_MATCH_COUNT GREATER 2)
    # also create a major version suffixed symlink
    if(APPLE)
      set(SYMLINK ${CMAKE_CURRENT_BINARY_DIR}/${BASE_LIB_NAME}.${CMAKE_MATCH_2}${LIB_SUFFIX})
    else()
      set(SYMLINK ${CMAKE_CURRENT_BINARY_DIR}/${BASE_LIB_NAME}${LIB_SUFFIX}.${CMAKE_MATCH_2})
    endif()
    execute_process(COMMAND "${CMAKE_COMMAND}" -E
        create_symlink ${TARGET_NAME} ${SYMLINK})
    install(PROGRAMS ${SYMLINK} DESTINATION ${CMAKE_INSTALL_LIBDIR}
        COMPONENT redist)
  endif()
endmacro()

if (OSPCOMMON_TASKING_TBB)
  if (WIN32)
    set(TBB_DLL_HINTS
      HINTS
      ${OSPCOMMON_TBB_ROOT}/../redist/${TBB_ARCH}_win/tbb/vc14
      ${OSPCOMMON_TBB_ROOT}/../redist/${TBB_ARCH}/tbb/vc14
      ${OSPCOMMON_TBB_ROOT}/bin/${TBB_ARCH}/vc14
      ${OSPCOMMON_TBB_ROOT}/bin
    )
    find_file(TBB_DLL tbb.dll ${TBB_DLL_HINTS})
    find_file(TBB_DLL_DEBUG tbb_debug.dll ${TBB_DLL_HINTS})
    find_file(TBB_DLL_MALLOC tbbmalloc.dll ${TBB_DLL_HINTS})
    find_file(TBB_DLL_MALLOC_DEBUG tbbmalloc_debug.dll ${TBB_DLL_HINTS})
    mark_as_advanced(TBB_DLL)
    mark_as_advanced(TBB_DLL_DEBUG)
    mark_as_advanced(TBB_DLL_MALLOC)
    mark_as_advanced(TBB_DLL_MALLOC_DEBUG)
    install(PROGRAMS ${TBB_DLL} ${TBB_DLL_MALLOC}
            DESTINATION ${CMAKE_INSTALL_BINDIR}
            CONFIGURATIONS Release RelWithDebInfo COMPONENT redist)
    install(PROGRAMS ${TBB_DLL_DEBUG} ${TBB_DLL_MALLOC_DEBUG}
            DESTINATION ${CMAKE_INSTALL_BINDIR}
            CONFIGURATIONS Debug COMPONENT redist)
  else()
    install(PROGRAMS ${TBB_LIBRARY} ${TBB_LIBRARY_MALLOC}
            DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT redist)
    ospray_install_namelink(${TBB_LIBRARY})
    ospray_install_namelink(${TBB_LIBRARY_MALLOC})
  endif()
endif()

macro(ospray_add_dependent_lib TARGET_NAME)
  if (TARGET ${TARGET_NAME})
    get_target_property(CONFIGURATIONS ${TARGET_NAME} IMPORTED_CONFIGURATIONS)
    list(GET CONFIGURATIONS 0 CONFIGURATION)
    get_target_property(LIBRARY ${TARGET_NAME} IMPORTED_LOCATION_${CONFIGURATION})
    list(APPEND DEPENDENT_LIBS ${LIBRARY})
    ospray_install_namelink(${LIBRARY})
  else()
    message(STATUS "Skipping target '${TARGET_NAME}")
  endif()
endmacro()

ospray_add_dependent_lib(ospcommon::ospcommon)
ospray_add_dependent_lib(openvkl::openvkl)
ospray_add_dependent_lib(openvkl::openvkl_module_ispc_driver)
ospray_add_dependent_lib(openvkl::openvkl_module_ispc_driver_4)
ospray_add_dependent_lib(openvkl::openvkl_module_ispc_driver_8)
ospray_add_dependent_lib(openvkl::openvkl_module_ispc_driver_16)
if (OSPRAY_MODULE_DENOISER)
  ospray_add_dependent_lib(OpenImageDenoise)
endif()

if (WIN32)
  get_filename_component(EMBREE_LIB_DIR ${EMBREE_LIBRARY} PATH)
  set(EMBREE_DLL_HINTS
    ${EMBREE_LIB_DIR}
    ${EMBREE_LIB_DIR}/../bin
    ${embree_DIR}/../../../bin
    ${embree_DIR}/../bin
  )
  find_file(EMBREE_DLL embree3.dll HINTS ${EMBREE_DLL_HINTS})
  mark_as_advanced(EMBREE_DLL)
  list(APPEND DEPENDENT_LIBS ${EMBREE_DLL})
  install(PROGRAMS ${DEPENDENT_LIBS}
          DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT redist)
else()
  # TODO use ospray_add_dependent_lib(embree) when v3.10 (with targets) is minimum
  list(APPEND DEPENDENT_LIBS ${EMBREE_LIBRARY})
  install(PROGRAMS ${DEPENDENT_LIBS}
          DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT redist)
  ospray_install_namelink(${EMBREE_LIBRARY})
endif()

# Install MSVC runtime
if (WIN32)
  set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP TRUE)
  include(InstallRequiredSystemLibraries)
  list(FILTER CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS INCLUDE REGEX
      ".*msvcp[0-9]+\.dll|.*vcruntime[0-9]+\.dll|.*vcruntime[0-9]+_[0-9]+\.dll")
  install(FILES ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS}
      DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT redist)
endif()
