#!/bin/bash

. ./scripts/INCLUDE.sh


# Initialize environment
init_environment() {
    log "INFO" "Start Builder Patch!"
    log "INFO" "Current Path: $PWD"
    
    cd $GITHUB_WORKSPACE/$WORKING_DIR || error "Failed to change directory"
}

# Apply distribution-specific patches
apply_distro_patches() {
    case "${BASE}" in
        "openwrt")
            log "INFO" "Applying OpenWrt specific patches"
            ;;
        "immortalwrt")
            log "INFO" "Applying ImmortalWrt specific patches"
            # Remove redundant default packages
            sed -i "/luci-app-cpufreq/d" include/target.mk
            ;;
        *)
            log "INFO" "Unknown distribution: ${BASE}"
            ;;
    esac
}

# Patch package signature checking
patch_signature_check() {
    log "INFO" "Disabling package signature checking"
    sed -i '\|option check_signature| s|^|#|' repositories.conf
}

# Patch Makefile for package installation
patch_makefile() {
    log "INFO" "Patching Makefile for force package installation"
    sed -i "s/install \$(BUILD_PACKAGES)/install \$(BUILD_PACKAGES) --force-overwrite --force-downgrade/" Makefile
}

# Configure partition sizes
configure_partitions() {
    log "INFO" "Configuring partition sizes"
    # Set kernel and rootfs partition sizes
    sed -i "s/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=128/" .config
    sed -i "s/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=2048/" .config
}

# Apply Amlogic-specific configurations
configure_amlogic() {
    if [[ "${TYPE}" == "OPHUB" || "${TYPE}" == "ULO" ]]; then    
        sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_EXT4FS=.*|# CONFIG_TARGET_ROOTFS_EXT4FS is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
        sed -i "s|CONFIG_TARGET_IMAGES_GZIP=.*|# CONFIG_TARGET_IMAGES_GZIP is not set|g" .config
    else
        # Jika tipe lain, hanya tampilkan informasi
        log "INFO" "system type: ${TYPE}"
    fi
}

# Apply x86_generic-specific configurations
configure_x86_generic() {
    if [[ "${ARCH_2}" == "x86_64" || "${ARCH_2}" == "i686" ]]; then
        log "INFO" "Applying x86 generic configurations"
        # Disable ISO images generation
        sed -i "s/CONFIG_ISO_IMAGES=y/# CONFIG_ISO_IMAGES is not set/" .config
        # Disable VHDX images generation
        sed -i "s/CONFIG_VHDX_IMAGES=y/# CONFIG_VHDX_IMAGES is not set/" .config
    fi
}



# Main execution
main() {
    init_environment
    apply_distro_patches
    patch_signature_check
    patch_makefile
    configure_partitions
    configure_amlogic
    configure_x86_generic
    log "INFO" "Builder patch completed successfully!"
}

# Execute main function
main
