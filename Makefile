SWIFT_BUILD_FLAGS = --disable-sandbox -c release --arch x86_64 --arch arm64
BINARIES_PATH = /usr/local/bin
EXECUTABLE_PATH = $(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/create-api

.PHONY: build install uninstall documentation artifactbundle

build:
	swift build $(SWIFT_BUILD_FLAGS)

install: build
	sudo install -d "$(BINARIES_PATH)"
	sudo install "$(EXECUTABLE_PATH)" "$(BINARIES_PATH)"

uninstall:
	sudo rm -f "$(BINARIES_PATH)/create-api"

artifactbundle: build
	scripts/artifactbundle.sh "$(version)" "$(EXECUTABLE_PATH)"

documentation:
	sourcery
