SWIFT_BUILD_FLAGS = --disable-sandbox -c release
BINARIES_PATH = /usr/local/bin
EXECUTABLE_PATH = $(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/create-api

.PHONY: build install uninstall

build:
	swift build $(SWIFT_BUILD_FLAGS)

install: build
	sudo install -d "$(BINARIES_PATH)"
	sudo install "$(EXECUTABLE_PATH)" "$(BINARIES_PATH)"

uninstall:
	sudo rm -f "$(BINARIES_PATH)/create-api"
