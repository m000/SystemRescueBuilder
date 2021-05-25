FROM archlinux:latest
# base stuff - don't want much customization for these
ARG sr_src="/usr/src/systemrescue"
ARG sr_src_local="./systemrescue-sources"
ARG sr_archiso_rev="HEAD"
USER root
RUN pacman -Syy
RUN pacman --noconfirm -S archiso grub mtools edk2-shell
RUN pacman --noconfirm -S asp binutils fakeroot lynx make patch rsync subversion vim zsh
RUN ln -s /usr/bin/vim /usr/bin/vi
RUN useradd -ms /bin/bash builder
COPY --chown=builder:builder "${sr_src_local}" "${sr_src}"

# expose base arguments to env
ENV sr_src="${sr_src}"
ENV sr_archiso_rev="${sr_archiso_rev}"

# build and install modified archiso
USER builder
WORKDIR /home/builder
RUN svn checkout --depth=empty svn://svn.archlinux.org/packages
WORKDIR /home/builder/packages
RUN svn update archiso -r"${sr_archiso_rev}"
WORKDIR /home/builder/packages/archiso/trunk
COPY scripts/PKGBUILD_prepare.sh .
RUN cat PKGBUILD_prepare.sh >> PKGBUILD
RUN makepkg --skippgpcheck
USER root
RUN pacman --noconfirm -U archiso-*.pkg.tar.zst

# build SRMs
ARG srm_src="/usr/src/modules"
ARG srm_src_local="./modules/modules.tar"
ARG srm_enabled=""
ADD "${srm_src_local}" "${srm_src}"
ENV srm_enabled="${srm_enabled}"
RUN "${srm_src}"/srm-bootstrap.sh

# building the SystemRescue image when the container is started
# NB: The privileged operations required to build the SystemRescue
#     image are not supported during the building phase of the 
#     Docker image.
USER root
WORKDIR "${sr_src}"
CMD ["./build.sh"]

# docker image stuff
ARG image_maintainer="Manolis Stamatogiannakis <mstamat@gmail.com>"
ARG image_description="SystemRescue Image Builder"
ARG image_version="0.0"
ARG image_packages_build=""
ARG image_packages_modules=""
LABEL maintainer="${image_maintainer}" \
      description="${image_description}" \
      version="${image_version}"
