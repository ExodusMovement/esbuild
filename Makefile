ESBUILD_VERSION = $(shell cat version.txt)

# Strip debug info
GO_FLAGS += "-ldflags=-s -w"

# Avoid embedding the build path in the executable for more reproducible builds
GO_FLAGS += -trimpath

esbuild: version-go cmd/esbuild/*.go pkg/*/*.go internal/*/*.go go.mod
	CGO_ENABLED=0 go build $(GO_FLAGS) ./cmd/esbuild

check-go-version:
	@go version | grep ' go1\.23\.8 ' || (echo 'Please install Go version 1.23.8' && false)

# Note: This used to only be rebuilt when "version.txt" was newer than
# "cmd/esbuild/version.go", but that caused the publishing script to publish
# invalid builds in the case when the publishing script failed once, the change
# to "cmd/esbuild/version.go" was reverted, and then the publishing script was
# run again, since in that case "cmd/esbuild/version.go" has a later mtime than
# "version.txt" but is still outdated.
#
# To avoid this problem, we now always run this step regardless of mtime status.
# This step still avoids writing to "cmd/esbuild/version.go" if it already has
# the correct contents, so it won't unnecessarily invalidate anything that uses
# "cmd/esbuild/version.go" as a dependency.
version-go:
	node scripts/esbuild.js --update-version-go

platform-all:
	@$(MAKE) --no-print-directory -j4 \
		platform-aix-ppc64 \
		platform-android-arm \
		platform-android-arm64 \
		platform-android-x64 \
		platform-darwin-arm64 \
		platform-darwin-x64 \
		platform-deno \
		platform-freebsd-arm64 \
		platform-freebsd-x64 \
		platform-linux-arm \
		platform-linux-arm64 \
		platform-linux-ia32 \
		platform-linux-loong64 \
		platform-linux-mips64el \
		platform-linux-ppc64 \
		platform-linux-riscv64 \
		platform-linux-s390x \
		platform-linux-x64 \
		platform-netbsd-arm64 \
		platform-netbsd-x64 \
		platform-neutral \
		platform-openbsd-arm64 \
		platform-openbsd-x64 \
		platform-sunos-x64 \
		platform-wasi-preview1 \
		platform-wasm \
		platform-win32-arm64 \
		platform-win32-ia32 \
		platform-win32-x64

platform-win32-x64: version-go
	node scripts/esbuild.js npm/@esbuild/win32-x64/package.json --version
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build $(GO_FLAGS) -o npm/@esbuild/win32-x64/esbuild.exe ./cmd/esbuild

platform-win32-ia32: version-go
	node scripts/esbuild.js npm/@esbuild/win32-ia32/package.json --version
	CGO_ENABLED=0 GOOS=windows GOARCH=386 go build $(GO_FLAGS) -o npm/@esbuild/win32-ia32/esbuild.exe ./cmd/esbuild

platform-win32-arm64: version-go
	node scripts/esbuild.js npm/@esbuild/win32-arm64/package.json --version
	CGO_ENABLED=0 GOOS=windows GOARCH=arm64 go build $(GO_FLAGS) -o npm/@esbuild/win32-arm64/esbuild.exe ./cmd/esbuild

platform-wasi-preview1: version-go
	node scripts/esbuild.js npm/@esbuild/wasi-preview1/package.json --version
	CGO_ENABLED=0 GOOS=wasip1 GOARCH=wasm go build $(GO_FLAGS) -o npm/@esbuild/wasi-preview1/esbuild.wasm ./cmd/esbuild

platform-unixlike: version-go
	@test -n "$(GOOS)" || (echo "The environment variable GOOS must be provided" && false)
	@test -n "$(GOARCH)" || (echo "The environment variable GOARCH must be provided" && false)
	@test -n "$(NPMDIR)" || (echo "The environment variable NPMDIR must be provided" && false)
	node scripts/esbuild.js "$(NPMDIR)/package.json" --version
	CGO_ENABLED=0 GOOS="$(GOOS)" GOARCH="$(GOARCH)" go build $(GO_FLAGS) -o "$(NPMDIR)/bin/esbuild" ./cmd/esbuild

platform-android-x64: platform-wasm
	node scripts/esbuild.js npm/@esbuild/android-x64/package.json --version

platform-android-arm: platform-wasm
	node scripts/esbuild.js npm/@esbuild/android-arm/package.json --version

platform-aix-ppc64:
	@$(MAKE) --no-print-directory GOOS=aix GOARCH=ppc64 NPMDIR=npm/@esbuild/aix-ppc64 platform-unixlike

platform-android-arm64:
	@$(MAKE) --no-print-directory GOOS=android GOARCH=arm64 NPMDIR=npm/@esbuild/android-arm64 platform-unixlike

platform-darwin-x64:
	@$(MAKE) --no-print-directory GOOS=darwin GOARCH=amd64 NPMDIR=npm/@esbuild/darwin-x64 platform-unixlike

platform-darwin-arm64:
	@$(MAKE) --no-print-directory GOOS=darwin GOARCH=arm64 NPMDIR=npm/@esbuild/darwin-arm64 platform-unixlike

platform-freebsd-x64:
	@$(MAKE) --no-print-directory GOOS=freebsd GOARCH=amd64 NPMDIR=npm/@esbuild/freebsd-x64 platform-unixlike

platform-freebsd-arm64:
	@$(MAKE) --no-print-directory GOOS=freebsd GOARCH=arm64 NPMDIR=npm/@esbuild/freebsd-arm64 platform-unixlike

platform-netbsd-arm64:
	@$(MAKE) --no-print-directory GOOS=netbsd GOARCH=arm64 NPMDIR=npm/@esbuild/netbsd-arm64 platform-unixlike

platform-netbsd-x64:
	@$(MAKE) --no-print-directory GOOS=netbsd GOARCH=amd64 NPMDIR=npm/@esbuild/netbsd-x64 platform-unixlike

platform-openbsd-arm64:
	@$(MAKE) --no-print-directory GOOS=openbsd GOARCH=arm64 NPMDIR=npm/@esbuild/openbsd-arm64 platform-unixlike

platform-openbsd-x64:
	@$(MAKE) --no-print-directory GOOS=openbsd GOARCH=amd64 NPMDIR=npm/@esbuild/openbsd-x64 platform-unixlike

platform-linux-x64:
	@$(MAKE) --no-print-directory GOOS=linux GOARCH=amd64 NPMDIR=npm/@esbuild/linux-x64 platform-unixlike

platform-linux-ia32:
	@$(MAKE) --no-print-directory GOOS=linux GOARCH=386 NPMDIR=npm/@esbuild/linux-ia32 platform-unixlike

platform-linux-arm:
	@$(MAKE) --no-print-directory GOOS=linux GOARCH=arm NPMDIR=npm/@esbuild/linux-arm platform-unixlike

platform-linux-arm64:
	@$(MAKE) --no-print-directory GOOS=linux GOARCH=arm64 NPMDIR=npm/@esbuild/linux-arm64 platform-unixlike

platform-linux-loong64:
	@$(MAKE) --no-print-directory GOOS=linux GOARCH=loong64 NPMDIR=npm/@esbuild/linux-loong64 platform-unixlike

platform-linux-mips64el:
	@$(MAKE) --no-print-directory GOOS=linux GOARCH=mips64le NPMDIR=npm/@esbuild/linux-mips64el platform-unixlike

platform-linux-ppc64:
	@$(MAKE) --no-print-directory GOOS=linux GOARCH=ppc64le NPMDIR=npm/@esbuild/linux-ppc64 platform-unixlike

platform-linux-riscv64:
	@$(MAKE) --no-print-directory GOOS=linux GOARCH=riscv64 NPMDIR=npm/@esbuild/linux-riscv64 platform-unixlike

platform-linux-s390x:
	@$(MAKE) --no-print-directory GOOS=linux GOARCH=s390x NPMDIR=npm/@esbuild/linux-s390x platform-unixlike

platform-sunos-x64:
	@$(MAKE) --no-print-directory GOOS=illumos GOARCH=amd64 NPMDIR=npm/@esbuild/sunos-x64 platform-unixlike

platform-wasm: esbuild
	node scripts/esbuild.js npm/esbuild-wasm/package.json --version
	node scripts/esbuild.js ./esbuild --wasm

platform-neutral: esbuild
	node scripts/esbuild.js npm/esbuild/package.json --version
	node scripts/esbuild.js ./esbuild --neutral

platform-deno: platform-wasm
	node scripts/esbuild.js ./esbuild --deno

clean:
	go clean -cache
	go clean -testcache
	rm -f esbuild
	rm -f npm/@esbuild/wasi-preview1/esbuild.wasm
	rm -f npm/@esbuild/win32-arm64/esbuild.exe
	rm -f npm/@esbuild/win32-ia32/esbuild.exe
	rm -f npm/@esbuild/win32-x64/esbuild.exe
	rm -f npm/esbuild-wasm/esbuild.wasm npm/esbuild-wasm/wasm_exec*.js
	rm -rf npm/@esbuild/aix-ppc64/bin
	rm -rf npm/@esbuild/android-arm/bin npm/@esbuild/android-arm/esbuild.wasm npm/@esbuild/android-arm/wasm_exec*.js
	rm -rf npm/@esbuild/android-arm64/bin
	rm -rf npm/@esbuild/android-x64/bin npm/@esbuild/android-x64/esbuild.wasm npm/@esbuild/android-x64/wasm_exec*.js
	rm -rf npm/@esbuild/darwin-arm64/bin
	rm -rf npm/@esbuild/darwin-x64/bin
	rm -rf npm/@esbuild/freebsd-arm64/bin
	rm -rf npm/@esbuild/freebsd-x64/bin
	rm -rf npm/@esbuild/linux-arm/bin
	rm -rf npm/@esbuild/linux-arm64/bin
	rm -rf npm/@esbuild/linux-ia32/bin
	rm -rf npm/@esbuild/linux-loong64/bin
	rm -rf npm/@esbuild/linux-mips64el/bin
	rm -rf npm/@esbuild/linux-ppc64/bin
	rm -rf npm/@esbuild/linux-riscv64/bin
	rm -rf npm/@esbuild/linux-s390x/bin
	rm -rf npm/@esbuild/linux-x64/bin
	rm -rf npm/@esbuild/netbsd-arm64/bin
	rm -rf npm/@esbuild/netbsd-x64/bin
	rm -rf npm/@esbuild/openbsd-arm64/bin
	rm -rf npm/@esbuild/openbsd-x64/bin
	rm -rf npm/@esbuild/sunos-x64/bin
	rm -rf npm/esbuild-wasm/esm
	rm -rf npm/esbuild-wasm/lib
	rm -rf npm/esbuild/bin npm/esbuild/lib npm/esbuild/install.js
	rm -rf require/*/bench/
	rm -rf require/*/demo/
	rm -rf require/*/node_modules/
	rm -rf require/yarnpnp/.pnp* require/yarnpnp/.yarn* require/yarnpnp/out*.js
	rm -rf validate

# This also cleans directories containing cached code from other projects
clean-all: clean
	rm -fr github demo bench

################################################################################
# This generates browser support mappings

compat-table: esbuild
	./esbuild compat-table/src/index.ts --bundle --platform=node --external:./compat-table/repos/* --outfile=compat-table/out.js --log-level=warning --sourcemap
	node --enable-source-maps compat-table/out.js

update-compat-table: esbuild
	cd compat-table && npm i @mdn/browser-compat-data@latest caniuse-lite@latest --silent
	./esbuild compat-table/src/index.ts --bundle --platform=node --external:./compat-table/repos/* --outfile=compat-table/out.js --log-level=warning --sourcemap
	node --enable-source-maps compat-table/out.js --update
