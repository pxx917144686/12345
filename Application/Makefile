.PHONY: all clean build_clean

all: 12345.ipa

X.ipa: build/Build/Products/Debug-iphoneos/12345.app
	@echo Ad-Hoc signing 12345
	xattr -rc build/Build/Products/Debug-iphoneos/12345.app
	ldid -SX/12345.entitlements build/Build/Products/Debug-iphoneos/12345.app/12345
	ldid -s build/Build/Products/Debug-iphoneos/X.app
	rm -rf Payload 12345.ipa
	mkdir Payload
	cp -r build/Build/Products/Debug-iphoneos/X.app Payload/X.app
	zip -Ar 12345.ipa Payload
	rm -rf Payload
	rm -rf 12345.tipa
	cp 12345.ipa 12345.tipa

ifeq ($(NIGHTLY), 1)
build/Build/Products/Debug-iphoneos/12345.app: FORCE
	xcodebuild -scheme 12345 -derivedDataPath build -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO GCC_PREPROCESSOR_DEFINITIONS='NIGHTLY=1 COMMIT_HASH=\"$(COMMIT_HASH)\"' OTHER_LDFLAGS="-ldl"
else
build/Build/Products/Debug-iphoneos/X.app: FORCE
	xcodebuild -scheme 12345 -derivedDataPath build -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO OTHER_LDFLAGS="-ldl"
endif

clean:
	rm -rf build Payload 12345.ipa 12345.tipa

build_clean:
	rm -rf Payload build

FORCE: ;