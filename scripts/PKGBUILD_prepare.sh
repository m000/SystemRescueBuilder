
prepare() {
        cd "$pkgname-$pkgver"
        # apply systemrescue patches for archiso
        for p in "${sr_src}"/patches/*.patch; do
                patch -p1 < "$p"
        done
}

