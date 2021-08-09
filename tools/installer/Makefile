PROJECT_NAME = shrineos-installer
PROJECT_TARGET = $(PROJECT_NAME).exe

SOURCES := main.cpp

SOURCE_ROOT = .
BUILD_ROOT = out/
OUTPUT_ROOT = bin/



CONFIGURATION = Debug
TARGET = x86


BUILD_DIRECTORY = $(BUILD_ROOT)/$(TARGET)/$(CONFIGURATION)
OUTPUT_DIRECTORY = $(OUTOUT_ROOT)/$(TARGET)/$(CONFIGURATION)

OUTPUT = $(OUTPUT_DIRECTORY)/$(PROJECT_TARGET)

SET_VARS = "C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Auxiliary/Build/vcvars32.bat"
MS_BUILD = "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/Common7/Tools/vsdevcmd.bat" 

# %comspec% /k "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\VsDevCmd.bat"
# "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/Common7/Tools/vsdevcmd.bat"
# "C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/MSBuild/Current/Bin/MSBuild.exe"

MS_BUILD_PROJECT = $(BUILD_DIRECTORY)/ALL_BUILD.vcxproj

VSDEVCMD = cmd /k "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\VsDevCmd.bat"

all: $(OUTPUT)

$(OUTPUT) : $(MS_BUILD_PROJECT)
	MSBuild $(MS_BUILD_PROJECT)

#MSBuild $(MS_BUILD_PROJECT)
#cp $(BUILD_DIRECTORY)/$(CONFIGURATION)/shrineos-install.exe $(OUTPUT_DIRECTORY)/shrineos-installer.exe

$(MS_BUILD_PROJECT):
	cmake -B $(BUILD_DIRECTORY) -S $(SOURCE_ROOT)


