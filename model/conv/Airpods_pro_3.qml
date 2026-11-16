import QtQuick
import QtQuick3D

Node {
    id: root
    objectName: "Root"

    // --- added: controls used by the app
    property real lidOpen: 1          // 0 closed .. 1 fully open
    property bool showCase: true
    property bool showBuds: true
    property real plasticGlow: 0.30   // self-illumination of the white plastic (studio look)
    property real coat: 0.45

    // Resources
    property url textureData: "maps/textureData.png"
    property url textureData58: "maps/textureData58.png"
    property url textureData17: "maps/textureData17.png"
    property url textureData124: "maps/textureData124.png"
    property url textureData47: "maps/textureData47.png"
    property url textureData122: "maps/textureData122.jpg"
    property url textureData60: "maps/textureData60.png"
    Texture {
        id: _2_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: root.textureData58
    }
    Texture {
        id: _3_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: root.textureData60
    }
    Texture {
        id: _1_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: root.textureData47
    }
    Texture {
        id: _4_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: root.textureData122
    }
    Texture {
        id: _5_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: root.textureData124
    }
    Texture {
        id: _6_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: root.textureData
    }
    Texture {
        id: _0_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: root.textureData17
    }
    PrincipledMaterial {
        id: hsvhXbFCGvnKLqR_material
        objectName: "HsvhXbFCGvnKLqR"
        baseColor: "#fff9f9f9"
        roughness: 1
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        clearcoatAmount: root.coat
        emissiveFactor: Qt.vector3d(root.plasticGlow, root.plasticGlow, root.plasticGlow)
        clearcoatRoughnessAmount: 0.4000000059604645
    }
    PrincipledMaterial {
        id: bexwFhrXMdSkVou_material
        objectName: "BExwFhrXMdSkVou"
        baseColor: "#ffa9a9a9"
        roughness: 0.6000000238418579
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: wlGBfgcDjjktGKi_material
        objectName: "wlGBfgcDjjktGKi"
        baseColor: "#ffcbcbcb"
        metalness: 1
        roughness: 0.10000000149011612
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: bcemltzLOrRpykF_material
        objectName: "BCEMLtzLOrRpykF"
        roughness: 1
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        clearcoatAmount: root.coat
        emissiveFactor: Qt.vector3d(root.plasticGlow, root.plasticGlow, root.plasticGlow)
        clearcoatRoughnessAmount: 0.20000000298023224
    }
    PrincipledMaterial {
        id: qUpSUfeNQBdmagr_material
        objectName: "qUpSUfeNQBdmagr"
        baseColor: "#ff191919"
        metalness: 0.30000001192092896
        roughness: 0.10000000149011612
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: vdKonUzpqPTDVLw_material
        objectName: "vdKonUzpqPTDVLw"
        baseColorMap: _4_texture
        metalnessMap: _5_texture
        roughnessMap: _5_texture
        roughness: 1
        normalMap: _6_texture
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: uxJORKAoxKXCbDN_material
        objectName: "uxJORKAoxKXCbDN"
        baseColor: "#ffededed"
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: lbkTACDHYUSZcjk_material
        objectName: "LbkTACDHYUSZcjk"
        baseColor: "#ff595959"
        metalness: 1
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: ieVHhwRkexGaklQ_material
        objectName: "IeVHhwRkexGaklQ"
        baseColorMap: _2_texture
        roughness: 0.05000000074505806
        emissiveMap: _3_texture
        emissiveFactor: Qt.vector3d(1, 1, 1)
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Mask
        depthDrawMode: PrincipledMaterial.OpaquePrePassDepthDraw
        alphaCutoff: 0.10000000149011612
    }
    PrincipledMaterial {
        id: zooxFfrwBWnUQdD_material
        objectName: "zooxFfrwBWnUQdD"
        metalness: 1
        roughness: 0.30000001192092896
        normalMap: _1_texture
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: fesGvQOXeqPgsWH_material
        objectName: "FesGvQOXeqPgsWH"
        baseColor: "#ff000000"
        roughness: 1
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: wwrjthXqFCMqrXz_material
        objectName: "WwrjthXqFCMqrXz"
        roughness: 1
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        clearcoatAmount: root.coat
        emissiveFactor: Qt.vector3d(root.plasticGlow, root.plasticGlow, root.plasticGlow)
        clearcoatRoughnessAmount: 0.05000000074505806
    }
    PrincipledMaterial {
        id: vwrclvsoDtTiCpL_0_material
        objectName: "VWRclvsoDtTiCpL_0"
        baseColor: "#ffc3c3c3"
        metalness: 1
        roughness: 0.5299999713897705
        normalMap: _0_texture
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: vwrclvsoDtTiCpL_material
        objectName: "VWRclvsoDtTiCpL"
        baseColor: "#ffc3c3c3"
        metalness: 1
        roughness: 0.5299999713897705
        normalMap: _0_texture
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: phtTSPZPCvSsFwP_material
        objectName: "PhtTSPZPCvSsFwP"
        baseColor: "#ff746b53"
        metalness: 1
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: oVFezdFDxINspYe_material
        objectName: "oVFezdFDxINspYe"
        baseColor: "#ffcbcbcb"
        metalness: 1
        roughness: 0.10000000149011612
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: fmVudrmHBnZziCY_material
        objectName: "fmVudrmHBnZziCY"
        baseColor: "#ffbdbec1"
        roughness: 0.33000001311302185
        normalMap: _0_texture
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }

    // Nodes:
    Node {
        id: sketchfab_model
        objectName: "Sketchfab_model"
        rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
        Node {
            id: root2
            objectName: "root"
            Node {
                id: gltf_SceneRootNode
                objectName: "GLTF_SceneRootNode"
                rotation: Qt.quaternion(0.707107, 0.707107, 0, 0)
                Node {
                    id: airPods_Pro_3_99
                    objectName: "AirPods Pro 3_99"
                    rotation: Qt.quaternion(0.707107, 0.707107, 0, 0)
                    scale: Qt.vector3d(0.01, 0.01, 0.01)
                    Node {
                        id: ivbAUpgLKGKfWua_96
                        objectName: "IvbAUpgLKGKfWua_96"
                        Node {
                            id: hXJOJrkFTZXXxnW_38
                            visible: root.showCase
                            objectName: "hXJOJrkFTZXXxnW_38"
                            Node {
                                id: fwcKmOLafQNsvRr_35
                                objectName: "fwcKmOLafQNsvRr_35"
                                Node {
                                    id: yqusVHFeCrwHHDx_001_34
                                    objectName: "YqusVHFeCrwHHDx.001_34"
                                    Node {
                                        id: pmlundqhblPuKUK_33
                                        objectName: "PMLUNDQHBlPuKUK_33"
                                        Node {
                                            id: kpaqGvvhsGowTJD_8
                                            objectName: "kpaqGvvhsGowTJD_8"
                                            // closed = identity; the lid swings about its hinge at (y, z) = (-0.9921, -0.1152)
                                            readonly property real th: -115 * root.lidOpen * Math.PI / 180
                                            position: Qt.vector3d(0,
                                                -0.9921 - (-0.9921 * Math.cos(th) - (-0.1152) * Math.sin(th)),
                                                -0.1152 - (-0.9921 * Math.sin(th) + (-0.1152) * Math.cos(th)))
                                            rotation: Quaternion.fromEulerAngles(-115 * root.lidOpen, 0, 0)
                                            Node {
                                                id: heAxRNLiyCNBsIL_3
                                                objectName: "HeAxRNLiyCNBsIL_3"
                                                Node {
                                                    id: maKUDVaCUlqquyG_1
                                                    objectName: "maKUDVaCUlqquyG_1"
                                                    Model {
                                                        id: object_12
                                                        objectName: "Object_12"
                                                        source: "meshes/object_0_mesh.mesh"
                                                        materials: [
                                                            vwrclvsoDtTiCpL_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: nnrNTFKuytzaDJI_2
                                                    objectName: "nnrNTFKuytzaDJI_2"
                                                    Model {
                                                        id: object_14
                                                        objectName: "Object_14"
                                                        source: "meshes/object_1_mesh.mesh"
                                                        materials: [
                                                            vwrclvsoDtTiCpL_0_material
                                                        ]
                                                    }
                                                }
                                            }
                                            Node {
                                                id: izuRLoZEisYUfVR_6
                                                objectName: "IZuRLoZEisYUfVR_6"
                                                Node {
                                                    id: etXDpdpusFylxpy_4
                                                    objectName: "etXDpdpusFylxpy_4"
                                                    Model {
                                                        id: object_17
                                                        objectName: "Object_17"
                                                        source: "meshes/object_2_mesh.mesh"
                                                        materials: [
                                                            wwrjthXqFCMqrXz_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: lLRBiUEDBcysTnb_5
                                                    objectName: "lLRBiUEDBcysTnb_5"
                                                    Model {
                                                        id: object_19
                                                        objectName: "Object_19"
                                                        source: "meshes/object_3_mesh.mesh"
                                                        materials: [
                                                            wwrjthXqFCMqrXz_material
                                                        ]
                                                    }
                                                }
                                            }
                                            Node {
                                                id: ktcvXtIbSdrwngW_7
                                                objectName: "KTcvXtIbSdrwngW_7"
                                                Model {
                                                    id: object_21
                                                    objectName: "Object_21"
                                                    source: "meshes/object_4_mesh.mesh"
                                                    materials: [
                                                        fesGvQOXeqPgsWH_material
                                                    ]
                                                }
                                            }
                                        }
                                        Node {
                                            id: znPUFrNzvqVdFKc_32
                                            objectName: "ZnPUFrNzvqVdFKc_32"
                                            Node {
                                                id: biFbVVqlvhQWkrf_9
                                                objectName: "BiFbVVqlvhQWkrf_9"
                                                Model {
                                                    id: object_24
                                                    objectName: "Object_24"
                                                    source: "meshes/object_5_mesh.mesh"
                                                    materials: [
                                                        vwrclvsoDtTiCpL_material
                                                    ]
                                                }
                                            }
                                            Node {
                                                id: hpqImUTfHtbDtMD_12
                                                objectName: "HPqImUTfHtbDtMD_12"
                                                Node {
                                                    id: bxmmWjfuidEfUvy_10
                                                    objectName: "BXmmWjfuidEfUvy_10"
                                                    Model {
                                                        id: object_27
                                                        objectName: "Object_27"
                                                        source: "meshes/object_6_mesh.mesh"
                                                        materials: [
                                                            fesGvQOXeqPgsWH_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: ittmfrDamQaLCBz_11
                                                    objectName: "ITTMfrDamQaLCBz_11"
                                                    Model {
                                                        id: object_29
                                                        objectName: "Object_29"
                                                        source: "meshes/object_7_mesh.mesh"
                                                        materials: [
                                                            zooxFfrwBWnUQdD_material
                                                        ]
                                                    }
                                                }
                                            }
                                            Node {
                                                id: kpaYtRLMgjTGhWO_14
                                                objectName: "KpaYtRLMgjTGhWO_14"
                                                Node {
                                                    id: ogzcyNMrIrwSKJl_13
                                                    objectName: "OGZCyNMrIrwSKJl_13"
                                                    Model {
                                                        id: object_32
                                                        objectName: "Object_32"
                                                        source: "meshes/object_8_mesh.mesh"
                                                        materials: [
                                                            vwrclvsoDtTiCpL_material
                                                        ]
                                                    }
                                                }
                                            }
                                            Node {
                                                id: lyBSNPETVWStXct_16
                                                objectName: "lyBSNPETVWStXct_16"
                                                Node {
                                                    id: dkuOUpinUveIrMm_15
                                                    objectName: "DkuOUpinUveIrMm_15"
                                                    Model {
                                                        id: object_35
                                                        objectName: "Object_35"
                                                        source: "meshes/object_9_mesh.mesh"
                                                        materials: [
                                                            ieVHhwRkexGaklQ_material
                                                        ]
                                                    }
                                                }
                                            }
                                            Node {
                                                id: oyWPrHSmCoTWUXm_24
                                                objectName: "OyWPrHSmCoTWUXm_24"
                                                Node {
                                                    id: aouzdzAEsDMqVwV_17
                                                    objectName: "AOUzdzAEsDMqVwV_17"
                                                    Model {
                                                        id: object_38
                                                        objectName: "Object_38"
                                                        source: "meshes/object_10_mesh.mesh"
                                                        materials: [
                                                            lbkTACDHYUSZcjk_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: grhyljqQmKbOtVR_18
                                                    objectName: "GRHYljqQmKbOtVR_18"
                                                    Model {
                                                        id: object_40
                                                        objectName: "Object_40"
                                                        source: "meshes/object_11_mesh.mesh"
                                                        materials: [
                                                            fmVudrmHBnZziCY_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: ixMVnEsCfWUaFZR_19
                                                    objectName: "ixMVnEsCfWUaFZR_19"
                                                    Model {
                                                        id: object_42
                                                        objectName: "Object_42"
                                                        source: "meshes/object_12_mesh.mesh"
                                                        materials: [
                                                            oVFezdFDxINspYe_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: iZaIiXlckAnTlzj_20
                                                    objectName: "iZaIiXlckAnTlzj_20"
                                                    Model {
                                                        id: object_44
                                                        objectName: "Object_44"
                                                        source: "meshes/object_13_mesh.mesh"
                                                        materials: [
                                                            fmVudrmHBnZziCY_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: ntuZVLBCiTEIgiK_21
                                                    objectName: "NTuZVLBCiTEIgiK_21"
                                                    Model {
                                                        id: object_46
                                                        objectName: "Object_46"
                                                        source: "meshes/object_14_mesh.mesh"
                                                        materials: [
                                                            fmVudrmHBnZziCY_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: whNvFgLmppxWNct_22
                                                    objectName: "whNvFgLmppxWNct_22"
                                                    Model {
                                                        id: object_48
                                                        objectName: "Object_48"
                                                        source: "meshes/object_15_mesh.mesh"
                                                        materials: [
                                                            lbkTACDHYUSZcjk_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: zgjbCmHVrVNMUuT_23
                                                    objectName: "ZGjbCmHVrVNMUuT_23"
                                                    Model {
                                                        id: object_50
                                                        objectName: "Object_50"
                                                        source: "meshes/object_16_mesh.mesh"
                                                        materials: [
                                                            fmVudrmHBnZziCY_material
                                                        ]
                                                    }
                                                }
                                            }
                                            Node {
                                                id: pbyprcDTNELITty_25
                                                objectName: "PbyprcDTNELITty_25"
                                                Model {
                                                    id: object_52
                                                    objectName: "Object_52"
                                                    source: "meshes/object_17_mesh.mesh"
                                                    materials: [
                                                        wwrjthXqFCMqrXz_material
                                                    ]
                                                }
                                            }
                                            Node {
                                                id: rtzCPAeovFbQscb_29
                                                objectName: "RTzCPAeovFbQscb_29"
                                                Node {
                                                    id: advrDHJnusZvnds_26
                                                    objectName: "advrDHJnusZvnds_26"
                                                    Model {
                                                        id: object_55
                                                        objectName: "Object_55"
                                                        source: "meshes/object_18_mesh.mesh"
                                                        materials: [
                                                            phtTSPZPCvSsFwP_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: hhSKUyiiGoaqiUU_27
                                                    objectName: "HhSKUyiiGoaqiUU_27"
                                                    Model {
                                                        id: object_57
                                                        objectName: "Object_57"
                                                        source: "meshes/object_19_mesh.mesh"
                                                        materials: [
                                                            wwrjthXqFCMqrXz_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: xzacaenQyJvJYyR_28
                                                    objectName: "XZacaenQyJvJYyR_28"
                                                    Model {
                                                        id: object_59
                                                        objectName: "Object_59"
                                                        source: "meshes/object_20_mesh.mesh"
                                                        materials: [
                                                            wwrjthXqFCMqrXz_material
                                                        ]
                                                    }
                                                }
                                            }
                                            Node {
                                                id: scFGOYKHEIEoIWy_30
                                                objectName: "scFGOYKHEIEoIWy_30"
                                                Model {
                                                    id: object_61
                                                    objectName: "Object_61"
                                                    source: "meshes/object_21_mesh.mesh"
                                                    materials: [
                                                        fesGvQOXeqPgsWH_material
                                                    ]
                                                }
                                            }
                                            Node {
                                                id: vzsjcdVppUhaAIr_31
                                                objectName: "VZSJcdVppUhaAIr_31"
                                                Model {
                                                    id: object_63
                                                    objectName: "Object_63"
                                                    source: "meshes/object_22_mesh.mesh"
                                                    materials: [
                                                        fesGvQOXeqPgsWH_material
                                                    ]
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Node {
                            id: yamPaavUOjSVJHE_95
                            visible: root.showBuds
                            objectName: "YamPaavUOjSVJHE_95"
                            Node {
                                id: fwcKmOLafQNsvRr_001_92
                                objectName: "fwcKmOLafQNsvRr.001_92"
                                Node {
                                    id: yqusVHFeCrwHHDx_91
                                    objectName: "YqusVHFeCrwHHDx_91"
                                    Node {
                                        id: twQKaIBlhILKpNP_90
                                        objectName: "TwQKaIBlhILKpNP_90"
                                        Node {
                                            id: blvfImZvTRtJYtd_64
                                            objectName: "BLvfImZvTRtJYtd_64"
                                            position: Qt.vector3d(-1.419, 1.491, -3.403)
                                            rotation: Qt.quaternion(0.59457, 0.144119, -0.274686, -0.741798)
                                            scale: Qt.vector3d(1, 1, 1)
                                            Node {
                                                id: lhUDrvUxcmzZwuV_58
                                                objectName: "lhUDrvUxcmzZwuV_58"
                                                Node {
                                                    id: bmrXOQkCkALaVuj_40
                                                    objectName: "BMrXOQkCkALaVuj_40"
                                                    Model {
                                                        id: object_71
                                                        objectName: "Object_71"
                                                        source: "meshes/object_23_mesh.mesh"
                                                        materials: [
                                                            fesGvQOXeqPgsWH_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: jcdChHihDrYFYvv_51
                                                    objectName: "jcdChHihDrYFYvv_51"
                                                    Node {
                                                        id: iDljlzJKlrWeRaB_43
                                                        objectName: "iDljlzJKlrWeRaB_43"
                                                        Node {
                                                            id: hSNSXotOtRYdUbQ_41
                                                            objectName: "hSNSXotOtRYdUbQ_41"
                                                            Model {
                                                                id: object_75
                                                                objectName: "Object_75"
                                                                source: "meshes/object_24_mesh.mesh"
                                                                materials: [
                                                                    vdKonUzpqPTDVLw_material
                                                                ]
                                                            }
                                                        }
                                                        Node {
                                                            id: wyAyDYvQLzVItzC_42
                                                            objectName: "WyAyDYvQLzVItzC_42"
                                                            Model {
                                                                id: object_77
                                                                objectName: "Object_77"
                                                                source: "meshes/object_25_mesh.mesh"
                                                                materials: [
                                                                    vdKonUzpqPTDVLw_material
                                                                ]
                                                            }
                                                        }
                                                    }
                                                    Node {
                                                        id: kJXgUEWUsOFffkS_47
                                                        objectName: "kJXgUEWUsOFffkS_47"
                                                        Node {
                                                            id: gawrhnVRfmavzbe_44
                                                            objectName: "GAWrhnVRfmavzbe_44"
                                                            Model {
                                                                id: object_80
                                                                objectName: "Object_80"
                                                                source: "meshes/object_26_mesh.mesh"
                                                                materials: [
                                                                    wwrjthXqFCMqrXz_material
                                                                ]
                                                            }
                                                        }
                                                        Node {
                                                            id: nteiWGlHoUfVWfw_45
                                                            objectName: "NTeiWGlHoUfVWfw_45"
                                                            Model {
                                                                id: object_82
                                                                objectName: "Object_82"
                                                                source: "meshes/object_27_mesh.mesh"
                                                                materials: [
                                                                    qUpSUfeNQBdmagr_material
                                                                ]
                                                            }
                                                        }
                                                        Node {
                                                            id: vsbBSKOQzOboZEj_46
                                                            objectName: "VsbBSKOQzOboZEj_46"
                                                            Model {
                                                                id: object_84
                                                                objectName: "Object_84"
                                                                source: "meshes/object_28_mesh.mesh"
                                                                materials: [
                                                                    qUpSUfeNQBdmagr_material
                                                                ]
                                                            }
                                                        }
                                                    }
                                                    Node {
                                                        id: yvdqfEHxpcjMEWa_50
                                                        objectName: "YVdqfEHxpcjMEWa_50"
                                                        Node {
                                                            id: oifgTQMBgdXVrUy_48
                                                            objectName: "OIFgTQMBgdXVrUy_48"
                                                            Model {
                                                                id: object_87
                                                                objectName: "Object_87"
                                                                source: "meshes/object_29_mesh.mesh"
                                                                materials: [
                                                                    bcemltzLOrRpykF_material
                                                                ]
                                                            }
                                                        }
                                                        Node {
                                                            id: tkQHhRlfHIMNwbL_49
                                                            objectName: "tkQHhRlfHIMNwbL_49"
                                                            Model {
                                                                id: object_89
                                                                objectName: "Object_89"
                                                                source: "meshes/object_30_mesh.mesh"
                                                                materials: [
                                                                    wwrjthXqFCMqrXz_material
                                                                ]
                                                            }
                                                        }
                                                    }
                                                }
                                                Node {
                                                    id: vybGjatnMLPRxaU_56
                                                    objectName: "VYbGjatnMLPRxaU_56"
                                                    Node {
                                                        id: dExUZHAdVilEsVU_52
                                                        objectName: "dExUZHAdVilEsVU_52"
                                                        Model {
                                                            id: object_92
                                                            objectName: "Object_92"
                                                            source: "meshes/object_31_mesh.mesh"
                                                            materials: [
                                                                wlGBfgcDjjktGKi_material
                                                            ]
                                                        }
                                                    }
                                                    Node {
                                                        id: sroCKQyVILtVoGd_53
                                                        objectName: "SRoCKQyVILtVoGd_53"
                                                        Model {
                                                            id: object_94
                                                            objectName: "Object_94"
                                                            source: "meshes/object_32_mesh.mesh"
                                                            materials: [
                                                                wwrjthXqFCMqrXz_material
                                                            ]
                                                        }
                                                    }
                                                    Node {
                                                        id: uvdCsPAXvAjFtDg_54
                                                        objectName: "uvdCsPAXvAjFtDg_54"
                                                        Model {
                                                            id: object_96
                                                            objectName: "Object_96"
                                                            source: "meshes/object_33_mesh.mesh"
                                                            materials: [
                                                                vdKonUzpqPTDVLw_material
                                                            ]
                                                        }
                                                    }
                                                    Node {
                                                        id: veazXbsmuJYoYDQ_55
                                                        objectName: "VeazXbsmuJYoYDQ_55"
                                                        Model {
                                                            id: object_98
                                                            objectName: "Object_98"
                                                            source: "meshes/object_34_mesh.mesh"
                                                            materials: [
                                                                wlGBfgcDjjktGKi_material
                                                            ]
                                                        }
                                                    }
                                                }
                                                Node {
                                                    id: xssACHIdYOVpjNn_57
                                                    objectName: "xssACHIdYOVpjNn_57"
                                                    Model {
                                                        id: object_100
                                                        objectName: "Object_100"
                                                        source: "meshes/object_35_mesh.mesh"
                                                        materials: [
                                                            bexwFhrXMdSkVou_material
                                                        ]
                                                    }
                                                }
                                            }
                                            Node {
                                                id: pftzqyiCaCmTEIn_61
                                                objectName: "PFTzqyiCaCmTEIn_61"
                                                Node {
                                                    id: kYFXptIDgcYvMPa_59
                                                    objectName: "kYFXptIDgcYvMPa_59"
                                                    Model {
                                                        id: object_103
                                                        objectName: "Object_103"
                                                        source: "meshes/object_36_mesh.mesh"
                                                        materials: [
                                                            vdKonUzpqPTDVLw_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: yhhzbphJLbfKoVG_60
                                                    objectName: "yhhzbphJLbfKoVG_60"
                                                    Model {
                                                        id: object_105
                                                        objectName: "Object_105"
                                                        source: "meshes/object_37_mesh.mesh"
                                                        materials: [
                                                            uxJORKAoxKXCbDN_material
                                                        ]
                                                    }
                                                }
                                            }
                                            Node {
                                                id: zhpkwtorDqOeTQW_63
                                                objectName: "ZHPKwtorDqOeTQW_63"
                                                Node {
                                                    id: aUmxZKsIeXiNHGS_62
                                                    objectName: "aUmxZKsIeXiNHGS_62"
                                                    Model {
                                                        id: object_108
                                                        objectName: "Object_108"
                                                        source: "meshes/object_38_mesh.mesh"
                                                        materials: [
                                                            hsvhXbFCGvnKLqR_material
                                                        ]
                                                    }
                                                }
                                            }
                                        }
                                        Node {
                                            id: bqtvQbjelRVbbzz_89
                                            objectName: "bqtvQbjelRVbbzz_89"
                                            position: Qt.vector3d(1.41857, 1.49092, -3.40294)
                                            rotation: Qt.quaternion(0.59457, 0.144115, 0.274683, 0.7418)
                                            Node {
                                                id: prSwTkdahGVxGNh_67
                                                objectName: "PrSwTkdahGVxGNh_67"
                                                Node {
                                                    id: aKRHUObZhpZHPbc_65
                                                    objectName: "aKRHUObZhpZHPbc_65"
                                                    Model {
                                                        id: object_112
                                                        objectName: "Object_112"
                                                        source: "meshes/object_39_mesh.mesh"
                                                        materials: [
                                                            uxJORKAoxKXCbDN_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: zhTaWbCVfejLoda_66
                                                    objectName: "ZhTaWbCVfejLoda_66"
                                                    Model {
                                                        id: object_114
                                                        objectName: "Object_114"
                                                        source: "meshes/object_40_mesh.mesh"
                                                        materials: [
                                                            vdKonUzpqPTDVLw_material
                                                        ]
                                                    }
                                                }
                                            }
                                            Node {
                                                id: ujZNArCTNeppuYl_86
                                                objectName: "UjZNArCTNeppuYl_86"
                                                Node {
                                                    id: qaOxXDvtuCyyhqA_68
                                                    objectName: "QaOxXDvtuCyyhqA_68"
                                                    Model {
                                                        id: object_117
                                                        objectName: "Object_117"
                                                        source: "meshes/object_41_mesh.mesh"
                                                        materials: [
                                                            fesGvQOXeqPgsWH_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: vkvdvaFFMTZLcEv_69
                                                    objectName: "VKVDVaFFMTZLcEv_69"
                                                    Model {
                                                        id: object_119
                                                        objectName: "Object_119"
                                                        source: "meshes/object_42_mesh.mesh"
                                                        materials: [
                                                            bexwFhrXMdSkVou_material
                                                        ]
                                                    }
                                                }
                                                Node {
                                                    id: wgDlUyxqKTcBqGI_74
                                                    objectName: "wgDlUyxqKTcBqGI_74"
                                                    Node {
                                                        id: icrLFoWFxYIeGuq_70
                                                        objectName: "icrLFoWFxYIeGuq_70"
                                                        Model {
                                                            id: object_122
                                                            objectName: "Object_122"
                                                            source: "meshes/object_43_mesh.mesh"
                                                            materials: [
                                                                wlGBfgcDjjktGKi_material
                                                            ]
                                                        }
                                                    }
                                                    Node {
                                                        id: lyJpcPZPYAYPJhz_71
                                                        objectName: "LyJpcPZPYAYPJhz_71"
                                                        Model {
                                                            id: object_124
                                                            objectName: "Object_124"
                                                            source: "meshes/object_44_mesh.mesh"
                                                            materials: [
                                                                vdKonUzpqPTDVLw_material
                                                            ]
                                                        }
                                                    }
                                                    Node {
                                                        id: pNRajRgxSQEFFzh_72
                                                        objectName: "pNRajRgxSQEFFzh_72"
                                                        Model {
                                                            id: object_126
                                                            objectName: "Object_126"
                                                            source: "meshes/object_45_mesh.mesh"
                                                            materials: [
                                                                wlGBfgcDjjktGKi_material
                                                            ]
                                                        }
                                                    }
                                                    Node {
                                                        id: sxGxstCriyyKxFa_73
                                                        objectName: "sxGxstCriyyKxFa_73"
                                                        Model {
                                                            id: object_128
                                                            objectName: "Object_128"
                                                            source: "meshes/object_46_mesh.mesh"
                                                            materials: [
                                                                wwrjthXqFCMqrXz_material
                                                            ]
                                                        }
                                                    }
                                                }
                                                Node {
                                                    id: xAPiWYJzRGoIKhG_85
                                                    objectName: "xAPiWYJzRGoIKhG_85"
                                                    Node {
                                                        id: excywBLEnyAZEtv_77
                                                        objectName: "EXcywBLEnyAZEtv_77"
                                                        Node {
                                                            id: ucceYGxMJqkbikV_75
                                                            objectName: "UCceYGxMJqkbikV_75"
                                                            Model {
                                                                id: object_132
                                                                objectName: "Object_132"
                                                                source: "meshes/object_47_mesh.mesh"
                                                                materials: [
                                                                    wwrjthXqFCMqrXz_material
                                                                ]
                                                            }
                                                        }
                                                        Node {
                                                            id: vQqaGWuMqoNxCJL_76
                                                            objectName: "vQqaGWuMqoNxCJL_76"
                                                            Model {
                                                                id: object_134
                                                                objectName: "Object_134"
                                                                source: "meshes/object_48_mesh.mesh"
                                                                materials: [
                                                                    bcemltzLOrRpykF_material
                                                                ]
                                                            }
                                                        }
                                                    }
                                                    Node {
                                                        id: iFGvtjwgxKwcSfE_81
                                                        objectName: "iFGvtjwgxKwcSfE_81"
                                                        Node {
                                                            id: jogphoNEqvfQKgP_78
                                                            objectName: "JogphoNEqvfQKgP_78"
                                                            Model {
                                                                id: object_137
                                                                objectName: "Object_137"
                                                                source: "meshes/object_49_mesh.mesh"
                                                                materials: [
                                                                    qUpSUfeNQBdmagr_material
                                                                ]
                                                            }
                                                        }
                                                        Node {
                                                            id: negRsDSkFzDiDvn_79
                                                            objectName: "NegRsDSkFzDiDvn_79"
                                                            Model {
                                                                id: object_139
                                                                objectName: "Object_139"
                                                                source: "meshes/object_50_mesh.mesh"
                                                                materials: [
                                                                    qUpSUfeNQBdmagr_material
                                                                ]
                                                            }
                                                        }
                                                        Node {
                                                            id: vueAjsuzRiInJsL_80
                                                            objectName: "VueAjsuzRiInJsL_80"
                                                            Model {
                                                                id: object_141
                                                                objectName: "Object_141"
                                                                source: "meshes/object_51_mesh.mesh"
                                                                materials: [
                                                                    wwrjthXqFCMqrXz_material
                                                                ]
                                                            }
                                                        }
                                                    }
                                                    Node {
                                                        id: vrMUmPyBnXyiRXC_84
                                                        objectName: "vrMUmPyBnXyiRXC_84"
                                                        Node {
                                                            id: gdOKSEZlIxQIWkb_82
                                                            objectName: "gdOKSEZlIxQIWkb_82"
                                                            Model {
                                                                id: object_144
                                                                objectName: "Object_144"
                                                                source: "meshes/object_52_mesh.mesh"
                                                                materials: [
                                                                    vdKonUzpqPTDVLw_material
                                                                ]
                                                            }
                                                        }
                                                        Node {
                                                            id: ljMXOKUzLLOHKMH_83
                                                            objectName: "ljMXOKUzLLOHKMH_83"
                                                            Model {
                                                                id: object_146
                                                                objectName: "Object_146"
                                                                source: "meshes/object_53_mesh.mesh"
                                                                materials: [
                                                                    vdKonUzpqPTDVLw_material
                                                                ]
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            Node {
                                                id: ysgSYLeJlZAUvUR_88
                                                objectName: "ysgSYLeJlZAUvUR_88"
                                                Node {
                                                    id: fPjKvyCtOeXGMAp_87
                                                    objectName: "fPjKvyCtOeXGMAp_87"
                                                    Model {
                                                        id: object_149
                                                        objectName: "Object_149"
                                                        source: "meshes/object_54_mesh.mesh"
                                                        materials: [
                                                            hsvhXbFCGvnKLqR_material
                                                        ]
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Animations:
}
