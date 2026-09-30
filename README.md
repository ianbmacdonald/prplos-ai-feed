# prplos-ai-feed

OpenWrt / prplOS package recipes for running [Lemonade](https://github.com/lemonade-sdk/lemonade)'s `lemond` and a
LiteRT-LM inference server on a prplOS gateway. They package prebuilt, musl-native builds that give a prpl Foundation
prplOS gateway one OpenAI-compatible API, with on-box runtimes (LiteRT-LM, TFLite, ONNX Runtime,
ExecuTorch) and policy routing to hosts on the LAN or in a private data centre.

> Status: **experimental**. Tested on prplOS 5.1.0 x86_64 (a 2 vCPU, 2 GB virtual gateway). Only x86_64 packages are
> released. The aarch64 recipe of litert-lm-server (a glibc bundle run on the musl host) is **unvalidated**: it builds,
> but has not been run on hardware; do not deploy it until it has been.

## Packages

| Package | What it installs | Source it packages |
|---|---|---|
| `lemonade-lemond` | `lemond` + the `lemonade` CLI (musl, x86_64), a procd service, a supervisor that enforces an API key and binds only the LAN address, and a TR-181 firewall helper that opens a source-restricted rule only while lemond listens | [lemonade fork release, musl build 69080e669](https://github.com/ianbmacdonald/lemonade/releases/tag/prpl-demo-musl-2026.41.0-69080e669) |
| `litert-lm-server` | an OpenAI-compatible server over Google [LiteRT-LM](https://github.com/google-ai-edge/LiteRT-LM) (CPU): musl on x86_64 (v0.3.0), a self-contained glibc bundle on aarch64 (v0.2.2) | [litert-lm-server releases](https://github.com/ianbmacdonald/litert-lm-server/releases) |

The other runtime servers lemond can launch are published as standalone musl tarballs and are not packaged here yet:
[tflite-server](https://github.com/ianbmacdonald/tflite-server/releases),
[ort-server](https://github.com/ianbmacdonald/ort-server/releases),
[et-server](https://github.com/ianbmacdonald/et-server/releases). Unpack them on persistent storage and point lemond
at them (`option server_path` in `/etc/config/lemond`, or the runtime's `*_bin` key in `/etc/lemond/config.json`).

## Install the prebuilt packages (x86_64)

Download the `.ipk` files and `SHA256SUMS` from this repository's
[Releases](https://github.com/ianbmacdonald/prplos-ai-feed/releases), then on the gateway:

```sh
sha256sum -c SHA256SUMS                       # every line must say OK
opkg update                                   # if the image's feeds are reachable; the dependencies below are
                                              # usually already installed on a prplOS image
opkg install lemonade-lemond_*_x86_64.ipk litert-lm-server_*_x86_64.ipk
```

Dependencies come from the image's own feeds: `zlib`, `libcurl`, `libwebsockets4` (libwebsockets4-full),
`libcap`, `libstdcpp`, `libgcc`.

Then configure (lemond is **disabled and closed by default**):

```sh
umask 077; head -c 24 /dev/urandom | hexdump -v -e '/1 "%02x"' > /etc/lemond/api_key   # 48 hex chars
chmod 0600 /etc/lemond/api_key                                       # the service refuses any other mode
uci set lemond.main.cache_dir='/mnt/data/lemond'                     # persistent, writable, not tmpfs
# and in /etc/lemond/config.json set "models_dir" to persistent storage too (the default /srv/lemond/models
# is on the flash overlay, too small for most models)
uci add_list lemond.fw.allow_src='192.168.1.10/32'                   # who may reach the API (else: nobody)
uci set lemond.main.enabled='1'; uci commit lemond
/etc/init.d/lemond start
```

Models go in `/etc/lemond/user_models.json` or are pulled by name (`lemonade pull ...`) from Hugging Face or
ModelScope (`option modelscope_endpoint` / `option hf_endpoint` choose a non-default site or a mirror; each must be a
bare `https://host[:port]`, with no path or trailing slash, or lemond refuses to start).

## Build from the feed

In a prplOS (OpenWrt) SDK or buildroot:

```sh
echo "src-git prplos_ai https://github.com/ianbmacdonald/prplos-ai-feed.git" >> feeds.conf
./scripts/feeds update prplos_ai && ./scripts/feeds install -a -p prplos_ai
make package/lemonade-lemond/compile package/litert-lm-server/compile
```

The recipes download the prebuilt release assets and check them against the sha256 in each Makefile; nothing is
compiled. In an SDK, `feeds install` warns "No feed for package 'zlib'" (and libcap): expected, since the SDK does not
carry those base packages; the gateway image does. `net/lemonade-lemond/test-lemond-fw.sh` tests the firewall helper's input validation on any POSIX shell.

## Security model (lemond)

- Binds only an IPv4 address on `br-lan`: never `0.0.0.0`, loopback or the WAN.
- Refuses to start without an API key file (root-owned, mode 0600). The key reaches lemond through its environment,
  never its command line. With the key set, every lemond route, admin included, answered 401 without it on our test
  gateway (lemond's behaviour; checked, not enforced by this package).
- The firewall rule admits only the configured sources to lemond's port. It is opened once lemond listens and removed
  on a normal stop and on any exit the supervisor can catch (a crash of lemond, a failed start). If the supervisor
  itself is killed without running its cleanup (SIGKILL, the OOM killer), the rule can outlive it until the next lemond
  start or a reboot. A start that finds an orphaned lemond removes the rule before retiring it, and these TR-181
  service rules are runtime-only on prplOS 5.1, so a reboot (or power loss) always clears them.
- On a stock prplOS 5.1 image the firewall's INPUT policy is DROP (IPv4 and IPv6) with no broad LAN accept, so
  anything the helper does not open stays closed. lemond's websocket port (9000 in the default `config.json`)
  listens on the LAN address but is not opened by the helper; open it deliberately if you need realtime audio.
- The runtime servers lemond launches listen on localhost. litert-lm-server's own service (when run standalone)
  defaults to `127.0.0.1`; that default is not enforced and the server has no authentication of its own, so do not
  bind it to a routable address without separate protection.
- Start-up model update checks are off by default (`auto_check_model_updates: false`), so models change only when
  an operator asks. lemond hash-checks downloaded files against what the hub publishes (per its source and docs).
- LAN discovery (`beacon_listen`) is list-only per lemond's documentation: it never contacts or registers a host it
  hears.

## Licences

The recipes in this repository, and the scripts they install (supervisor, firewall helper, init scripts, wrapper),
are licensed under **GPL-2.0-only** (see `LICENSE`), like the OpenWrt packages feed.
The packaged software keeps its own licences, declared in each Makefile's `PKG_LICENSE` and installed with the
package: lemond is Apache-2.0; litert-lm-server is Apache-2.0 plus the statically linked components listed in its
`licenses/INDEX.md` (and, for the aarch64 glibc bundle, the LGPL/GCC-runtime-exception notices of that runtime).

## Where the builds come from

The lemond build comes from a release branch of a public fork
([ianbmacdonald/lemonade](https://github.com/ianbmacdonald/lemonade)), not from upstream
[Lemonade](https://github.com/lemonade-sdk/lemonade); its musl support and the LiteRT, TFLite and ExecuTorch recipes
are not in upstream Lemonade. These recipes are not part of any prpl-foundation feed.
