.PHONY: all build release run clean

all: build

build:
	swift build

release:
	bash Scripts/build_app.sh

run: release
	open EasyFinder.app

clean:
	swift package clean
	rm -rf EasyFinder.app .build
