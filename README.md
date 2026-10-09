# prplos-ai-feed

OpenWrt / prplOS package recipes for running [Lemonade](https://github.com/lemonade-sdk/lemonade)'s `lemond` and a
LiteRT-LM inference server on a prplOS gateway. They package prebuilt, musl-native builds that give a prpl Foundation
prplOS gateway one OpenAI-compatible API, with on-box runtimes (LiteRT-LM, TFLite, ONNX Runtime,
ExecuTorch) and policy routing to hosts on the LAN or in a private data centre.

> Status: **experimental**. The x86_64 packages are tested on prplOS 5.2.0 x86_64 (a 2 vCPU, 2 GB virtual gateway);
> earlier releases were tested on 5.1.0. From release v2026.10.09 `lemonade-lemond`, `tflite-server`, `ort-server` and
> `et-server` are also released for **aarch64** (`aarch64_cortex-a53`, built in a prplOS 5.2.0 ipq807x buildroot). Of
> those, `lemonade-lemond` has been installed with `opkg` over a running prplOS 5.2.0 image on a 1 GB Dynalink DL-WRX36
> (IPQ8072A) and run there as a routing-only gateway: it forwards chat to a LAN AI server through a router model
> (9 October 2026; lemond 19 MB resident, 4 MB anonymous). The three runtime servers have not been run on Arm hardware
> (their authors tested them under qemu); treat them as **unvalidated** until they have been.
> The aarch64 recipe of litert-lm-server (a glibc bundle run on the musl host) is also unvalidated and is not released.

## Packages

| Package | What it installs | Source it packages |
|---|---|---|
| `lemonade-lemond` | `lemond` + the `lemonade` CLI (musl, x86_64 and aarch64), a procd service that runs lemond and every runtime it starts as the unprivileged user `lemond`, a supervisor that enforces an API key and binds only the LAN address, and a TR-181 firewall helper that opens a source-restricted rule only while lemond listens | [lemonade fork release, musl build 6e16ce1c3](https://github.com/ianbmacdonald/lemonade/releases/tag/prpl-demo-musl-2026.42.0-6e16ce1c3) |
| `litert-lm-server` | an OpenAI-compatible server over Google [LiteRT-LM](https://github.com/google-ai-edge/LiteRT-LM) (CPU): musl on x86_64 (v0.3.0), a self-contained glibc bundle on aarch64 (v0.2.2) | [litert-lm-server releases](https://github.com/ianbmacdonald/litert-lm-server/releases) |
| `tflite-server` | LiteRT v2.2.0 (TFLite) behind lemonade's `/v1/classify` contract: text classifiers and image CNNs (musl, x86_64 and aarch64; curated operator set) | [tflite-server v0.3.0](https://github.com/ianbmacdonald/tflite-server/releases/tag/v0.3.0) |
| `ort-server` | ONNX Runtime behind the same contract (musl, x86_64 and aarch64; curated minimal build, `.ort` models only); the wrapper starts it with 2 worker threads unless `--threads` is given or `ORT_SERVER_THREADS` is set | [ort-server v0.2.1-musl](https://github.com/ianbmacdonald/ort-server/releases/tag/v0.2.1-musl) |
| `et-server` | ExecuTorch v1.5.1 (XNNPACK backend) behind the same contract (musl, x86_64 and aarch64; curated kernel set) | [et-server v0.2.0](https://github.com/ianbmacdonald/et-server/releases/tag/v0.2.0) |

Each runtime server installs under `/usr/lib/<name>/` with a `/usr/bin/<name>` wrapper; install only the runtimes you
use. lemond finds litert-lm-server, tflite-server and et-server on its default `PATH`. For ort-server, name it in
`/etc/lemond/config.json`: `"onnxruntime": {"cpu_bin": "/usr/bin/ort-server"}`. The packaged `config.json` sets
`"no_fetch_executables": true`, so lemond never downloads a runtime binary of its own.

## Install the prebuilt packages

Download the `.ipk` files and `SHA256SUMS` from this repository's
[Releases](https://github.com/ianbmacdonald/prplos-ai-feed/releases), then on the gateway:

```sh
sha256sum -c SHA256SUMS                       # every line must say OK
opkg update                                   # if the image's feeds are reachable; the dependencies below are
                                              # usually already installed on a prplOS image
opkg install lemonade-lemond_*_x86_64.ipk litert-lm-server_*_x86_64.ipk \
    tflite-server_*_x86_64.ipk ort-server_*_x86_64.ipk et-server_*_x86_64.ipk   # any subset
# aarch64 (see Status: lemond run on hardware, the runtime servers not yet): the same names ending _aarch64_cortex-a53.ipk; litert-lm-server is not released
```

The three runtime servers carry a **curated** operator set: the operators the reference models of six gateway use cases
need (text classification, sentence embeddings, image classification, object detection, audio, time series). A model
that needs an operator outside the set is refused at load, with an error naming it; each server's repository documents
how to build the general (all-operator) version.

Dependencies come from the image's own feeds: `zlib`, `libcurl`, `libwebsockets4` (libwebsockets4-full),
`libcap`, `libstdcpp`, `libgcc`.

Then configure (lemond is **disabled and closed by default**):

```sh
umask 077; head -c 24 /dev/urandom | hexdump -v -e '/1 "%02x"' > /etc/lemond/api_key   # 48 hex chars
chmod 0600 /etc/lemond/api_key                                       # the service refuses any other mode
uci set lemond.main.cache_dir='/mnt/data/lemond'                     # persistent, not tmpfs, below /mnt or /srv
uci set lemond.main.models_dir='/mnt/data/lemond-models'             # where pulls land; below /mnt or /srv
# and set the SAME path as "models_dir" in /etc/lemond/config.json (the default /srv/lemond/models is on the
# flash overlay, too small for most models). Both directories are handed to the 'lemond' user at start.
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
make package/lemonade-lemond/compile package/litert-lm-server/compile \
    package/tflite-server/compile package/ort-server/compile package/et-server/compile
```

The recipes download the prebuilt release assets and check them against the sha256 in each Makefile; nothing is
compiled. In an SDK, `feeds install` warns "No feed for package 'zlib'" (and libcap): expected, since the SDK does not
carry those base packages; the gateway image does. `net/lemonade-lemond/test-lemond-fw.sh` tests the firewall helper's input validation on any POSIX shell.

## Security model (lemond)

- lemond, and every runtime server it starts, runs as the unprivileged user `lemond` (created by the package), with
  `no_new_privs` set and an empty capability set (through procd's `ujail`), so a setuid binary cannot raise it.
  Only the root supervisor reads the API key and manages the firewall rule. The paths lemond may write come from the
  root-owned `/etc/config/lemond`, must be real directories below `/mnt` or `/srv`, and are refused if any path
  component is a symlink. Accelerator device nodes are opened to the service only when listed (`list device`).
  `option user 'root'` restores the old, privileged behaviour.
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
package: lemond is Apache-2.0; tflite-server, ort-server and et-server are Apache-2.0 plus the statically linked
components each Makefile lists; litert-lm-server is Apache-2.0 plus the statically linked components listed in its
`licenses/INDEX.md` (and, for the aarch64 glibc bundle, the LGPL/GCC-runtime-exception notices of that runtime).

## Where the builds come from

The lemond build comes from a release branch of a public fork
([ianbmacdonald/lemonade](https://github.com/ianbmacdonald/lemonade)), not from upstream
[Lemonade](https://github.com/lemonade-sdk/lemonade); its musl support and the LiteRT, TFLite and ExecuTorch recipes
are not in upstream Lemonade. These recipes are not part of any prpl-foundation feed.
