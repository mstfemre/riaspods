# Maintainer: local
# RiasPods: AirPods control for Linux with a liquid-glass UI, a live 3D model and an
# iPhone-like connect card. Based on LibrePods (GPL-3.0) by Kavish Devar.
pkgname=riaspods
pkgver=1.0.2
pkgrel=1
pkgdesc="AirPods control with a liquid glass UI and connect animation (based on LibrePods)"
arch=('x86_64')
license=('GPL-3.0-only')
conflicts=('librepods' 'librepods-glass')
replaces=('librepods-glass')
depends=('glibc' 'hicolor-icon-theme' 'libgcc' 'libpulse' 'libstdc++' 'openssl'
         'qt6-base' 'qt6-connectivity' 'qt6-declarative' 'qt6-quick3d')
makedepends=('cmake' 'qt6-tools')
optdepends=('inter-font: Apple-like typography')

build() {
  cmake -B "$srcdir/build" -S "$startdir/librepods/linux" -G 'Unix Makefiles' \
    -W no-author -DCMAKE_BUILD_TYPE=None -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_SKIP_RPATH=ON
  cmake --build "$srcdir/build"
}

package() {
  DESTDIR="$pkgdir" cmake --install "$srcdir/build"
  install -Dm644 "$startdir/librepods/LICENSE" -t "$pkgdir/usr/share/licenses/$pkgname"
}
