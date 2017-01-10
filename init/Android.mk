#
# Copyright (C) 2016 The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    init_exec.cpp \
    init_files.cpp \
    init_io.cpp \
    init_main.cpp \
    init_ramdisk.cpp \
    ../extract_ramdisk/extract_ramdisk.cpp

LOCAL_C_INCLUDES := \
    ../extract_ramdisk

ifneq ($(BOARD_SONY_INIT_INCLUDE),)
LOCAL_C_INCLUDES += \
    $(BOARD_SONY_INIT_INCLUDE)
endif

LOCAL_CPPFLAGS := \
    -Wall \
    -Wextra \
    -Werror

ifneq ($(BOARD_SONY_INIT_FLAGS),)
LOCAL_CFLAGS += \
    $(BOARD_SONY_INIT_FLAGS)
endif

LOCAL_MODULE := init_sony
LOCAL_MODULE_TAGS := optional

LOCAL_MODULE_PATH := $(PRODUCT_OUT)/utilities
LOCAL_UNSTRIPPED_PATH := $(PRODUCT_OUT)/symbols/utilities

LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_STATIC_LIBRARIES := \
    libbase \
    libc \
    libelf \
    libz

LOCAL_CLANG := true

include $(BUILD_EXECUTABLE)

# Build init.real if requested
ifeq ($(BOARD_SONY_INIT_SYMLINK),true)

# Abort if the device is not handled by init_sony
ifeq (,$(findstring DEV_BLOCK_FOTA_NUM,$(BOARD_SONY_INIT_FLAGS)))
$(error device-sony-common-init: DEV_BLOCK_FOTA_NUM missing in "$(TARGET_DEVICE)", platform "$(PRODUCT_PLATFORM)", with '$(BOARD_SONY_INIT_FLAGS)')
endif

# Init overrides for init_sony
root_init      := $(TARGET_ROOT_OUT)/init
root_init_real := $(TARGET_ROOT_OUT)/init.real

# If /init is a file and not a symlink then rename it to /init.real
# and make /init be a symlink to /sbin/init_sony (which will execute
# /init.real, if appropriate.
$(root_init_real): $(root_init) $(PRODUCT_OUT)/utilities/toybox $(PRODUCT_OUT)/utilities/keycheck $(PRODUCT_OUT)/utilities/init_sony
	cp $(PRODUCT_OUT)/utilities/toybox $(TARGET_ROOT_OUT)/sbin/toybox_init
	cp $(PRODUCT_OUT)/utilities/keycheck $(TARGET_ROOT_OUT)/sbin/keycheck
	cp $(PRODUCT_OUT)/utilities/init_sony $(TARGET_ROOT_OUT)/sbin/init_sony
	$(hide) if [ ! -L $(root_init) ]; then \
	  echo "/init $(root_init) isn't a symlink"; \
	  mv $(root_init) $(root_init_real); \
	  ln -s sbin/init_sony $(root_init); \
	else \
	  echo "/init $(root_init) is already a symlink"; \
	fi

ALL_DEFAULT_INSTALLED_MODULES += $(root_init_real)

endif
