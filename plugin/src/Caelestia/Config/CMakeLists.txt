qt_add_qml_module(caelestia-config
    URI Caelestia.Config
    VERSION ${VERSION}
    SOURCES
        jsonaccessor.hpp jsonaccessor.cpp
        config.hpp config.cpp
        bar.hpp
)

qt_query_qml_module(caelestia-config
    PLUGIN_TARGET module_plugin_target
    TARGET_PATH module_target_path
    QMLDIR module_qmldir
    TYPEINFO module_typeinfo
)

set(module_dir "${INSTALL_QMLDIR}/${module_target_path}")
install(TARGETS caelestia-config LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
install(TARGETS "${module_plugin_target}" LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
install(FILES "${module_qmldir}" DESTINATION "${module_dir}")
install(FILES "${module_typeinfo}" DESTINATION "${module_dir}")

target_link_libraries(caelestia-config PRIVATE Qt::Core Qt::Qml)
