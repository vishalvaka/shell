find_package(PkgConfig REQUIRED)
pkg_check_modules(QALCULATE REQUIRED libqalculate)
pkg_check_modules(AUBIO REQUIRED aubio)

qt_add_qml_module(caelestia
    URI Caelestia
    VERSION ${VERSION}
    SOURCES
        cutils.hpp cutils.cpp
        cachingimagemanager.hpp cachingimagemanager.cpp
        filesystemmodel.hpp filesystemmodel.cpp
        qalculator.hpp qalculator.cpp
        beattracker.hpp beattracker.cpp
)

qt_query_qml_module(caelestia
    PLUGIN_TARGET module_plugin_target
    TARGET_PATH module_target_path
    QMLDIR module_qmldir
    TYPEINFO module_typeinfo
)

set(module_dir "${INSTALL_QMLDIR}/${module_target_path}")
install(TARGETS caelestia LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
install(TARGETS "${module_plugin_target}" LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
install(FILES "${module_qmldir}" DESTINATION "${module_dir}")
install(FILES "${module_typeinfo}" DESTINATION "${module_dir}")

target_include_directories(caelestia SYSTEM PRIVATE ${QALCULATE_INCLUDE_DIRS} ${AUBIO_INCLUDE_DIRS})
target_link_libraries(caelestia PRIVATE
    Qt::Core Qt::Qml Qt::Gui Qt::Concurrent Qt::Multimedia
    ${QALCULATE_LIBRARIES} ${AUBIO_LIBRARIES}
)

add_subdirectory(Config)
