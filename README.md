# RiasPods

AirPods control for Linux with a liquid-glass UI, a live 3D model and an iPhone-like
connect card. Built for AirPods Pro 3 on Arch Linux / Hyprland.

RiasPods is based on [LibrePods](https://github.com/kavishdevar/librepods) by Kavish Devar
and stays under the same licence, GPL-3.0.

## Features

- Battery, noise control, conversational awareness and ear detection
- Connects when the case lid opens, and keeps trying while it stays open
- Connect card with a live 3D model of the AirPods
- `riaspods-ctl` command-line control

## Build and install (Arch Linux)

```
makepkg -f
sudo pacman -U riaspods-*-x86_64.pkg.tar.zst
```

## Layout

- `PKGBUILD`: Arch package
- `librepods/linux/`: the application (C++ / Qt Quick / Qt Quick 3D)
- `model/`: source 3D model and its converted meshes
- `tools/`: rendered assets

## Credits and assets

- **LibrePods** (https://github.com/kavishdevar/librepods) by Kavish Devar, GPL-3.0.
  RiasPods is a modified version of its Linux app.
- **3D model:** "AirPods Pro 3"
  (https://sketchfab.com/3d-models/airpods-pro-3-2209c17723a54331985cc080eda35266)
  by Apple User (https://sketchfab.com/apple-user), licence: Sketchfab Standard
  (https://sketchfab.com/licenses). Changes: converted to Qt Quick 3D meshes, materials
  adjusted. The model is **not** covered by this repository's GPL-3.0 licence; all rights
  stay with its author. It will be removed on the author's request.
- AirPods is a trademark of Apple Inc. This project is not affiliated with Apple.
