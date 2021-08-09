
BIN_PATH = bin

INSTALLER_SOURCE_PATH = tools/installer/
INSTALLER_NAME = shrineos-install.exe

INSTALLER = $(BIN_PATH)/$(INSTALLER_NAME)



all: installer

installer:
	make $(INSTALLER_SOURCE_PATH)
	cp "$(INSTALLER_SOURCE_PATH)/out/x86/Debug/Debug/$(INSTALLER_NAME)" "$(INSTALLER)"


#$(VSDEVCMD)
#	cl $(CL_FLAGS) 
