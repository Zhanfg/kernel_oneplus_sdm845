# BBRv3 backport — Linux 4.19 / OnePlus 6

## Upstreams

- Semantic upstream: `google/bbr@v3`
- Google tcp_bbr.c blob observed: `e09389c378cc99e39aa8e143fa090a687ad6d4c4`
- 4.19 compatibility donor: `zesakain/4.19-android-bbr3@lineage-23.2`
- Donor tcp_bbr.c blob: `51aafa51cf44685bafee0f602a967e027861942c`

## Policy

The donor is only a compatibility reference. Behaviour must stay aligned with
Google BBRv3; unrelated vendor/network changes are not imported.

The backport is staged:

1. Compile the 4.19-adapted BBRv3 tcp_bbr.c.
2. Backport only missing TCP/rate-sample/pacing/ECN/loss APIs.
3. Verify FQ pacing and rate sampling.
4. Keep CUBIC available as a recovery algorithm.
5. Make BBRv3 the ROM default only after runtime validation.

Known missing APIs in the current OP6 4.19 tree include newer BBRv3 support
such as TLP sample state, tx_in_flight sampling, PLB helpers, newer cwnd accessors
and fast-ACK state. CI failures are expected until these are backported.

## Runtime gate

Compile success is not enough. Before making BBRv3 default:

- iperf3 Wi-Fi LAN
- LTE/VoLTE data
- high RTT + packet loss
- transparent proxy/TProxy path
- screen-off/background transfer
- suspend/resume
- thermal and battery impact

CUBIC remains compiled in as fallback.
