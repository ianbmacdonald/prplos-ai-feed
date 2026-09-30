#!/bin/sh
# Unit test for lemond-fw validators + alias parsing, under busybox ash with ba-cli stubbed. Run: busybox ash test-lemond-fw.sh
F=$(dirname "$0")/files/lemond-fw; T=$(mktemp); trap "rm -f $T" EXIT
for f in valid_port svc_ids valid_src; do awk "/^$f\\(\\)/,/^}/" "$F" >> "$T"; done; for f in aliases has_alias; do awk "/^$f\\(\\)/" "$F" >> "$T"; done
TAG=lemond
. "$T"
pass=0; fail=0
chk() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1 expected $2 got $3"; fi; }
for v in 192.168.1.10 192.168.1.10/32 10.0.0.0/8 1.2.3.4/1; do valid_src "$v"; chk "src $v" 0 $?; done
for v in 0.0.0.0/1 00.0.0.0/1 0.00.0.0/1 999.1.1.1 1.2.3 1.2.3.4.5 1.2.3.4/0 1.2.3.4/33 1.2.3.4/032 01.2.3.4 "" 1..2.3 a.b.c.d 1.2.3.4/ 256.1.1.1; do valid_src "$v"; chk "src '$v'" 1 $?; done
for v in 1 8092 13305 65535; do valid_port "$v"; chk "port $v" 0 $?; done
for v in 0 013305 99999 65536 "" 12a 123456; do valid_port "$v"; chk "port '$v'" 1 $?; done
# ba-cli stub: the real output shape
ba-cli() { [ -n "$STUB_FAIL" ] && return 1; printf '%s\n' 'Firewall.Service.1.Alias="ssh"' 'Firewall.Service.4.Alias="lemond-1-8092"' 'Firewall.Service.5.Alias="lemond-2-8092"' 'Firewall.Service.7.Alias="lemond-b1-13305"' 'Firewall.Service.8.Alias="lemond--8092"' 'Firewall.Service.9.Alias="lemondx-1-8092"' 'Firewall.Service.10.Alias="beacon-relay-13305"'; }
chk "svc_ids" "4 5 7" "$(svc_ids | tr '\n' ' ' | sed 's/ $//')"
has_alias lemond-b1-13305; chk "has_alias found" 0 $?
has_alias lemond-b2-13305; chk "has_alias absent" 1 $?
STUB_FAIL=1; svc_ids >/dev/null; chk "svc_ids on query failure" 1 $?; has_alias x; chk "has_alias on query failure" 2 $?; STUB_FAIL=
ba-cli() { return 0; }; svc_ids >/dev/null; chk "svc_ids on EMPTY output" 1 $?
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
