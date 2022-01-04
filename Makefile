export EXECUTABLE_NAME = CreateAPI
PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/create-api
CURRENT_PATH = $(PWD)
REPO = https://github.com/kean/$(EXECUTABLE_NAME)
SWIFT_BUILD_FLAGS = --disable-sandbox -c release # --arch arm64 # --arch x86_64
EXECUTABLE_PATH = $(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/$(EXECUTABLE_NAME)

build:
	swift build $(SWIFT_BUILD_FLAGS)

install: build
	mkdir -p $(PREFIX)/bin
	sudo cp -f $(EXECUTABLE_PATH) $(INSTALL_PATH)
