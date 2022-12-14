#
# This file is the core-test recipe.
#

SUMMARY = "Simple core-test application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://core-test.c \
		file://dsc-driver.h \
	   file://Makefile \
		  "

S = "${WORKDIR}"

DEPENDS += "dsc-driver"

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}${bindir}
	     install -m 0755 core-test ${D}${bindir}
}
