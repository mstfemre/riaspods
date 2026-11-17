cmake_minimum_required(VERSION 3.16)

project(linux VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Widgets Bluetooth DBus LinguistTools)
find_package(OpenSSL REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(PULSEAUDIO REQUIRED libpulse)

qt_standard_project_setup()

# Translation files
set(TS_FILES
    translations/librepods_tr.ts
)

qt_add_executable(librepods
    main.cpp
    logger.h
    media/mediacontroller.cpp
    media/mediacontroller.h
    media/pulseaudiocontroller.cpp
    media/pulseaudiocontroller.h
    airpods_packets.h
    trayiconmanager.cpp
    trayiconmanager.h
    enums.h
    battery.hpp
    BluetoothMonitor.cpp
    BluetoothMonitor.h
    autostartmanager.hpp
    BasicControlCommand.hpp
    deviceinfo.hpp
    ble/bleutils.cpp
    ble/bleutils.h
    ble/blemanager.cpp
    ble/blemanager.h
    thirdparty/QR-Code-generator/qrcodegen.cpp
    thirdparty/QR-Code-generator/qrcodegen.hpp
    QRCodeImageProvider.hpp
    eardetection.hpp
    media/playerstatuswatcher.cpp
    media/playerstatuswatcher.h
    systemsleepmonitor.hpp
)

set_source_files_properties(Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(librepods
    URI linux
    VERSION 1.0
    QML_FILES
        Main.qml
        Theme.qml
        GlassPanel.qml
        GlassText.qml
        GlassSwitch.qml
        GlassButton.qml
        ConnectPopup.qml
        Pods3D.qml
        AirPodsModel.qml
        BatteryRing.qml
        PodsShowcase.qml
        SegmentedControl.qml
        Icon.qml
        KeysQRDialog.qml
        TrafficLights.qml
    RESOURCES
        maps/studio.png
        maps/textureData.png
        maps/textureData122.jpg
        maps/textureData124.png
        maps/textureData17.png
        maps/textureData47.png
        maps/textureData58.png
        maps/textureData60.png
        meshes/object_0_mesh.mesh
        meshes/object_10_mesh.mesh
        meshes/object_11_mesh.mesh
        meshes/object_12_mesh.mesh
        meshes/object_13_mesh.mesh
        meshes/object_14_mesh.mesh
        meshes/object_15_mesh.mesh
        meshes/object_16_mesh.mesh
        meshes/object_17_mesh.mesh
        meshes/object_18_mesh.mesh
        meshes/object_19_mesh.mesh
        meshes/object_1_mesh.mesh
        meshes/object_20_mesh.mesh
        meshes/object_21_mesh.mesh
        meshes/object_22_mesh.mesh
        meshes/object_23_mesh.mesh
        meshes/object_24_mesh.mesh
        meshes/object_25_mesh.mesh
        meshes/object_26_mesh.mesh
        meshes/object_27_mesh.mesh
        meshes/object_28_mesh.mesh
        meshes/object_29_mesh.mesh
        meshes/object_2_mesh.mesh
        meshes/object_30_mesh.mesh
        meshes/object_31_mesh.mesh
        meshes/object_32_mesh.mesh
        meshes/object_33_mesh.mesh
        meshes/object_34_mesh.mesh
        meshes/object_35_mesh.mesh
        meshes/object_36_mesh.mesh
        meshes/object_37_mesh.mesh
        meshes/object_38_mesh.mesh
        meshes/object_39_mesh.mesh
        meshes/object_3_mesh.mesh
        meshes/object_40_mesh.mesh
        meshes/object_41_mesh.mesh
        meshes/object_42_mesh.mesh
        meshes/object_43_mesh.mesh
        meshes/object_44_mesh.mesh
        meshes/object_45_mesh.mesh
        meshes/object_46_mesh.mesh
        meshes/object_47_mesh.mesh
        meshes/object_48_mesh.mesh
        meshes/object_49_mesh.mesh
        meshes/object_4_mesh.mesh
        meshes/object_50_mesh.mesh
        meshes/object_51_mesh.mesh
        meshes/object_52_mesh.mesh
        meshes/object_53_mesh.mesh
        meshes/object_54_mesh.mesh
        meshes/object_5_mesh.mesh
        meshes/object_6_mesh.mesh
        meshes/object_7_mesh.mesh
        meshes/object_8_mesh.mesh
        meshes/object_9_mesh.mesh
)

# Add the resource file
qt_add_resources(librepods "resources"
    PREFIX "/icons"
    FILES
        assets/airpods.png
        assets/pod.png
        assets/pod_case.png
        assets/pod3.png
        assets/pod3_case.png
        assets/pod4_case.png
        assets/podpro.png
        assets/podpro_case.png
        assets/podmax.png
        assets/fonts/SF-Symbols-6.ttf
)

target_link_libraries(librepods
    PRIVATE Qt6::Quick Qt6::Widgets Qt6::Bluetooth Qt6::DBus OpenSSL::SSL OpenSSL::Crypto ${PULSEAUDIO_LIBRARIES}
)

qt_add_executable(librepods-ctl
    librepods-ctl.cpp
)
target_link_libraries(librepods-ctl
    PRIVATE Qt6::Core Qt6::Network
)
install(TARGETS librepods-ctl
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# The targets keep their original names; only the installed programs are renamed.
set_target_properties(librepods PROPERTIES OUTPUT_NAME riaspods)
set_target_properties(librepods-ctl PROPERTIES OUTPUT_NAME riaspods-ctl)

target_include_directories(librepods PRIVATE ${PULSEAUDIO_INCLUDE_DIRS})

include(GNUInstallDirs)
install(TARGETS librepods
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
install(FILES assets/riaspods.desktop
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/applications")
install(FILES assets/riaspods.svg
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps")

# Translation support
qt_add_translations(librepods
    TS_FILES ${TS_FILES}
    QM_FILES_OUTPUT_VARIABLE QM_FILES
)

# Install translation files
install(FILES ${QM_FILES}
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/riaspods/translations")
