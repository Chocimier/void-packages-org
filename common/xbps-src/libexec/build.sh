#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
#   $1 - current pkgname to build [REQUIRED]
#   $2 - target pkgname (origin) to build [REQUIRED]
#   $3 - xbps target [REQUIRED]
#   $4 - cross target [OPTIONAL]
#   $5 - internal [OPTIONAL]

if [ $# -lt 3 -o $# -gt 5 ]; then
    echo "${0##*/}: invalid number of arguments: pkgname targetpkg target [cross-target]"
    exit 1
fi

readonly PKGNAME="$1"
readonly XBPS_TARGET_PKG="$2"
readonly XBPS_TARGET="$3"
readonly XBPS_CROSS_BUILD="$4"
readonly XBPS_CROSS_PREPARE="$5"

export XBPS_TARGET

for f in $XBPS_SHUTILSDIR/*.sh; do
    . $f
done

last="${XBPS_DEPENDS_CHAIN##*,}"
case "$XBPS_DEPENDS_CHAIN" in
    *,$last,*)
        msg_error "Build-time cyclic dependency$last,${XBPS_DEPENDS_CHAIN##*,$last,} detected.\n"
esac

setup_pkg "$PKGNAME" $XBPS_CROSS_BUILD
readonly SOURCEPKG="$sourcepkg"

check_existing_pkg

show_pkg_build_options
check_pkg_arch $XBPS_CROSS_BUILD

if [ -z "$XBPS_CROSS_PREPARE" ]; then
    prepare_cross_sysroot $XBPS_CROSS_BUILD || exit $?
fi
# Install dependencies from binary packages

# Fetch distfiles after installing required dependencies,
# because some of them might be required for do_fetch().

# Fetch, extract, build and install into the destination directory.

# Run patch phrase

# Run configure phase

# Run build phase

# Run check phase

# Install pkgs into destdir.


# Clean list of preregistered packages
printf "" > ${XBPS_STATEDIR}/.${sourcepkg}_register_pkg
# If install went ok generate the binpkgs.
for subpkg in ${subpackages} ${sourcepkg}; do
    $XBPS_LIBEXECDIR/xbps-src-dopkg.sh $subpkg "$XBPS_REPOSITORY" "$XBPS_CROSS_BUILD" || exit 1
done

# Registering packages at once per repository. This makes sure that staging is
# triggered for all new packages if any of them introduces inconsistencies.
cut -d: -f 1,2 ${XBPS_STATEDIR}/.${sourcepkg}_register_pkg | sort -u | \
    while IFS=: read -r arch repo; do
        paths=$(grep "^$arch:$repo:" "${XBPS_STATEDIR}/.${sourcepkg}_register_pkg" | \
            cut -d : -f 2,3 | tr ':' '/')
        additional_args=
        if [ -z "$XBPS_PRESERVE_PKGS" ] || [ "$XBPS_BUILD_FORCEMODE" ]; then
            additional_args+=" -f"
        fi
        if [ "$XBPS_REPO_COMPTYPE" ]; then
            additional_args+=" --compression $XBPS_REPO_COMPTYPE"
        fi
        if [ "$XBPS_RINDEX_TARGET" == stagedata ]; then
            additional_args+=" --stage"
        fi
        if [ -n "${arch}" ]; then
            msg_normal "Registering new packages to $repo ($arch)\n"
            XBPS_TARGET_ARCH=${arch} $XBPS_RINDEX_CMD ${additional_args} -a ${paths}
        else
            msg_normal "Registering new packages to $repo\n"
            if [ -n "$XBPS_CROSS_BUILD" ]; then
                $XBPS_RINDEX_XCMD ${additional_args} -a ${paths}
            else
                $XBPS_RINDEX_CMD ${additional_args} -a ${paths}
            fi
        fi
        rm -v $paths
    done

# pkg cleanup

if [ -n "$XBPS_DEPENDENCY" -o -z "$XBPS_KEEP_ALL" ]; then
    remove_pkg_autodeps
    remove_pkg_wrksrc
    remove_pkg $XBPS_CROSS_BUILD
    remove_pkg_statedir
fi

exit 0
