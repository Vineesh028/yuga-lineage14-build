# Nova customization overlay — prebuilt modules for the yuga cm-14.1 build.
LOCAL_PATH := $(call my-dir)

# --- Companion app (platform-signed privileged app) ---
include $(CLEAR_VARS)
LOCAL_MODULE := Nova
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := Nova.apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := platform
LOCAL_PRIVILEGED_MODULE := true
include $(BUILD_PREBUILT)

# --- Nova shell helpers -> /system/bin (executable) ---
define nova-bin
include $(CLEAR_VARS)
LOCAL_MODULE := $(1)
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := bin/$(1).sh
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_PATH := $(TARGET_OUT_EXECUTABLES)
LOCAL_MODULE_STEM := $(1).sh
include $(BUILD_PREBUILT)
endef

$(eval $(call nova-bin,nova-boot))
$(eval $(call nova-bin,nova-tune))
$(eval $(call nova-bin,nova-health))
$(eval $(call nova-bin,nova-diagnostics))
$(eval $(call nova-bin,nova-automation))
$(eval $(call nova-bin,nova-assistant))

# --- init.d entry -> /system/etc/init.d/90nova (executable) ---
include $(CLEAR_VARS)
LOCAL_MODULE := 90nova
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := init.d/90nova
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_PATH := $(TARGET_OUT)/etc/init.d
include $(BUILD_PREBUILT)
