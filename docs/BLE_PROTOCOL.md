# OneTouch Select Plus Flex — BLE Protocol Specification

Reverse-engineered from public sources. This document describes the Bluetooth
Low Energy (BLE) GATT protocol used by the **OneTouch Select Plus Flex** blood
glucose meter to sync glucose readings with the **OneTouch Reveal** mobile app.

The same protocol is used by all LifeScan "Verio family" meters:

| Meter | Market | Regulatory ID |
|---|---|---|
| OneTouch Select Plus Flex | EU / International | CE (LifeScan Scotland) |
| OneTouch Verio Flex | US | FDA K150214 |
| OneTouch Ultra Plus Flex | US | FDA K151611 |
| OneTouch Verio Reflect | US | (Verio family) |
| OneTouch Verio | US | (older) |

The Flutter implementation in `lib/ble/` is based on this spec.

---

## 1. Device Identification

### BLE advertising name
```
"OneTouch" + <last 4 chars of meter serial number>
```
Example: a meter with serial number ending in `J7RG` advertises as
`OneTouch J7RG`.

### Advertised service UUIDs
- `af9df7a1-e595-11e3-96b4-0002a5d5c51b` — LifeScan Verio vendor service
  (128-bit custom UUID, NOT a standard Bluetooth SIG service)
- `0x1800` Generic Access (mandatory)
- `0x1801` Generic Attribute (mandatory)
- `0x180A` Device Information (readable; Manufacturer Name = `"LifeScan"`)

The meter does **NOT** advertise the standard Glucose Service `0x1808`.

### BD_ADDR type
**Random / private resolvable address.** The meter re-rolls its random
address whenever it is put back into pairing mode, so the client must persist
the bonded identity, not the raw MAC.

### Pairing mode entry
1. Press **OK** to turn the meter on.
2. Press **▲ + ▼ together** to toggle Bluetooth ON (the BT icon appears).
3. The meter advertises for ~4 hours or until a test starts.

The Bluetooth feature turns OFF automatically during a blood glucose test and
turns back ON afterwards — you cannot sync mid-test.

---

## 2. GATT Services & Characteristics

### Vendor Verio service (the only one used for sync)

| Item | UUID | Properties |
|---|---|---|
| Service | `af9df7a1-e595-11e3-96b4-0002a5d5c51b` | — |
| Command channel (client → meter) | `af9df7a2-e595-11e3-96b4-0002a5d5c51b` | WRITE |
| Notification channel (meter → client) | `af9df7a3-e595-11e3-96b4-0002a5d5c51b` | NOTIFY + CCCD `0x2902` |

The lower three nibbles (`f7a1`/`f7a2`/`f7a3`) are the per-characteristic
identifiers; the rest of the UUID is the common LifeScan Verio base
`af9df7a?-e595-11e3-96b4-0002a5d5c51b`.

### Standard services present (mandatory BLE)
- `0x1800` Generic Access — Device Name, Appearance
- `0x1801` Generic Attribute — Service Changed
- `0x180A` Device Information — Manufacturer Name (`"LifeScan"`), Model Number,
  Serial Number (readable but not required for sync)

### Authentication / Pairing
- **Bondable**: yes — GATT operations on the vendor characteristics are
  rejected until the link is encrypted.
- **Pairing method**: Passkey Entry (6-digit PIN displayed on the meter LCD).
- **LE Secure Connections**: supported (Android 7+ defaults to it). Legacy
  pairing also works for backwards compatibility.
- **Bond keys persist** across power cycles on both sides. Once bonded,
  subsequent connections re-establish encryption automatically — no PIN
  re-entry needed.
- Re-entering pairing mode on the meter causes it to advertise under a new
  random address, invalidating the previous bond on the phone side.

---

## 3. Authentication / Handshake

### Layer 1: BLE bonding (mandatory, OS-managed)
1. User puts meter into pairing mode (▲ + ▼).
2. Client scans; user selects the meter.
3. Client calls `connect()`; the OS triggers bonding.
4. Meter displays a 6-digit PIN.
5. User enters the PIN into the phone's system pairing dialog.
6. OS completes Passkey Entry pairing; bond keys stored on both sides.

The Flutter app does NOT need to handle the PIN itself — `flutter_blue_plus`
surfaces the system pairing UI automatically.

### Layer 2: AES-128-ECB application-layer auth (optional, xavaro-only)

> **Note**: xDrip skips this layer entirely and works against already-bonded
> meters. The Flutter implementation in this repo defaults to skipping it
> (`tryAuth: false`). Enable it if you see `UNAUTHORIZED` (0x07) status
> responses from the meter.

The OneTouch Reveal app performs this handshake on every connection. It uses
a static AES-128 key extracted from the APK:

```
AES-128 key (16 bytes, hex): 483bd3c2cbdf6345160004e6d56d948c
```

**Step A — Read meter challenge:**
- Client writes command `{0xE6, 0x02, 0x08}` to `af9df7a2`.
- Meter responds on `af9df7a3` with a UTF-16LE-encoded hex string
  representing 16 random bytes (32 ASCII hex characters = 64 UTF-16LE bytes).

**Step B — Compute the AES token:**
1. Reverse the 16-byte challenge.
2. Build a 16-byte plaintext block `fchallenge` by byte-shuffling:
   ```
   fchallenge[0..1] = reversed[2..3]
   fchallenge[2..5] = reversed[4..7]
   fchallenge[6..7] = reversed[0..1]
   fchallenge[8..15] = fchallenge[0..7]   (duplicate first half)
   ```
3. `token = AES-128-ECB(fchallenge, key)` (no padding, single block).

**Step C — Send EnableFeatures command:**
- Client writes `{0x11, <16-byte token>}` to `af9df7a2`.
- Meter responds with status byte `0x06` (OK) if the challenge was answered
  correctly, or `0x07` (UNAUTHORIZED) if not.

---

## 4. Sync Sequence

### Pre-conditions
- Meter is bonded to the phone (PIN pairing already completed).
- Meter is powered on with Bluetooth feature enabled.
- Within ~8 metres of the phone.

### High-level flow (xDrip-style — what this Flutter impl uses)

```
1. SUBSCRIBE  af9df7a3   (write 0x01 0x00 to CCCD 0x2902)
2. WRITE      af9df7a2 <- ReadRtc        {0x20, 0x02}
3. NOTIFY     af9df7a3 -> 4-byte LE uint32 sec since 2000-01-01
4. WRITE      af9df7a2 <- ReadTestCount  {0x0A, 0x02, 0x06}
5. NOTIFY     af9df7a3 -> 4-byte LE uint32 lifetime test count
6. WRITE      af9df7a2 <- ReadRecordCount {0x27, 0x00}
7. NOTIFY     af9df7a3 -> 2-byte LE uint16 records-in-memory count
8. For seq = test_count down to (test_count - record_count + 1):
     WRITE   af9df7a2 <- ReadRecord {0xB3, lo(seq), hi(seq)}
     NOTIFY  af9df7a3 -> 11-byte record
     WRITE   af9df7a2 <- ACK {0x81}
9. DISCONNECT (or stay connected for live readings)
```

### Full flow (xavaro-style — with auth, unit, and ranges)

```
1.   SUBSCRIBE af9df7a3
2.   WRITE  af9df7a2 <- QueryChallenge  {0xE6, 0x02, 0x08}
3.   NOTIFY af9df7a3 -> challenge (UTF-16LE hex)
4.   WRITE  af9df7a2 <- EnableFeatures  {0x11, <16-byte AES token>}
5.   NOTIFY af9df7a3 -> status (0x06)
6.   WRITE  af9df7a2 <- ReadParameter   {0x09, 0x02, 0x02}
7.   NOTIFY af9df7a3 -> unit (0x00=mg/dL, 0x01=mmol/L)
8.   WRITE  af9df7a2 <- ReadRtc         {0x20, 0x02}
9.   NOTIFY af9df7a3 -> meter_time (uint32 sec since 2000-01-01)
10.  WRITE  af9df7a2 <- ReadLowRange    {0x0A, 0x02, 0x07}
11.  NOTIFY af9df7a3 -> low_range (uint32 mg/dL)
12.  WRITE  af9df7a2 <- ReadHighRange   {0x0A, 0x02, 0x08}
13.  NOTIFY af9df7a3 -> high_range (uint32 mg/dL)
14.  WRITE  af9df7a2 <- ReadRecordCount {0x27, 0x00}
15.  NOTIFY af9df7a3 -> record_count (uint16)
16.  WRITE  af9df7a2 <- ReadTestCount   {0x0A, 0x02, 0x06}
17.  NOTIFY af9df7a3 -> test_count (uint32)
18.  For i = test_count down to (test_count - record_count + 1):
       WRITE  af9df7a2 <- ReadRecord {0xB3, lo(i), hi(i)}
       NOTIFY af9df7a3 -> record (11 bytes)
       WRITE  af9df7a2 <- ACK {0x81}
19.  DISCONNECT
```

### Opcode reference

| Opcode bytes | Function | Response |
|---|---|---|
| `0xE6 0x02 0x08` | QUERY challenge | 16-byte challenge (UTF-16LE hex) |
| `0x11 <16-byte token>` | EnableFeatures (auth response) | status 0x06 |
| `0x09 0x02 0x02` | READ PARAMETER — glucose unit | 0x00=mg/dL, 0x01=mmol/L |
| `0x20 0x02` | READ RTC (meter clock) | 4-byte LE uint32 sec since 2000-01-01 |
| `0x20 0x01 <4-byte ts>` | WRITE RTC (set clock) | (optional) |
| `0x0A 0x02 0x06` | Read test count (lifetime) | 4-byte LE uint32 |
| `0x0A 0x02 0x07` | Read low range threshold | 4-byte LE uint32 (mg/dL) |
| `0x0A 0x02 0x08` | Read high range threshold | 4-byte LE uint32 (mg/dL) |
| `0x27 0x00` | READ RECORD COUNT | 2-byte LE uint16 |
| `0xB3 <lo> <hi>` | READ RECORD by sequence number | 11-byte record |
| `0x1A` | ERASE MEMORY (DANGEROUS) | status 0x06 |

### Record numbering
- Records are addressed by a **1-based sequence number that increments with
  each test** (lifetime counter — never resets, even after ERASE MEMORY).
- The highest sequence number on the meter = `test_count`.
- The number of records still in memory = `record_count`.
- The lowest sequence number in memory = `test_count - record_count + 1`.
- **There is no "report records newer than sequence N" opcode** like the
  standard RACP `0x01 0x03 0x01 <seq>`. You must iterate `0xB3 <seq>` one
  by one.

### ACK protocol
- **All GATT writes to `af9df7a2` must be strictly serialized**: send one
  command, wait for the data notification on `af9df7a3`, send the ACK byte,
  then send the next command.
- After each data notification, the client writes a single-byte ACK to
  `af9df7a2`:
  - Single-packet case (the common one): `{0x81}` (= `0x80 | 1`).
  - Multi-packet non-final: `0x80 | packet_index`.
  - Multi-packet final: `0xC0 | packet_index`.
- The meter does NOT pipeline commands. Pipelining will cause sync to fail.

### End-of-records detection
There is no explicit end-of-records signal. You stop when:
- You've read `record_count` records, OR
- A READ RECORD for a sequence number that doesn't exist returns a non-OK
  status byte.

### Status byte (first byte of every response message)

| Value | Meaning |
|---|---|
| `0x06` | OK / success |
| `0x07` | UNAUTHORIZED (auth failed — re-do AES handshake or bond) |
| `0x08` | UNSUPPORTED |
| `0x09` | INVALID_VALUE / parameter error |
| `0x0F` | FAILED (generic) |

---

## 5. Record Format

### Wire framing (LifeScan Shared Binary Protocol)

Each command and each response is wrapped in the LifeScan shared binary
packet format:

```
packet = STX length link-control command-prefix message ETX CRC16_LE
STX           = 0x02
length        = 1 byte, total packet length INCLUDING STX/length/ETX/CRC
                (so message length = length - 6)
link-control  = 1 byte, always 0x00 for Verio meters
command-prefix= 1 byte, always 0x03 for Verio
message       = (length - 6) bytes
ETX           = 0x03
checksum      = 2 bytes, CRC-16/CCITT-FALSE little-endian
                poly 0x1021, init 0xFFFF, no reflection, no xor-out
                computed over everything from STX through ETX (inclusive)
```

Test vector: CRC16 of ASCII `"123456789"` = `0x29B1`.

### CRC-16/CCITT-FALSE (reference implementation)

```python
def crc16_ccitt_false(data: bytes) -> int:
    crc = 0xFFFF
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            if crc & 0x8000:
                crc = ((crc << 1) ^ 0x1021) & 0xFFFF
            else:
                crc = (crc << 1) & 0xFFFF
    return crc
```

### BLE transport wrapping

Each GATT write/notification carries a 1-byte **packet header** followed by
(a chunk of) a framed packet. The header's top 2 bits identify the packet
type; the low 6 bits carry a count or index.

```
Header byte layout:
  bits 7..6  meaning
  ---------  ----------------------------------------
    00       First data packet; bits 5..0 = total packet count (1..63)
    01       Continuation data packet; bits 5..0 = 0-based index
    10       ACK byte (non-final); bits 5..0 = packet number
    11       ACK byte (final); bits 5..0 = packet number
```

For Verio commands every response fits in a single packet, so the common
case is:

| Direction | Payload |
|---|---|
| Client → Meter (TX) | `[0x01, ...framed_packet]` |
| Meter → Client (RX) | `[0x01, ...framed_packet]` |
| Client ACK | `[0x81]` |

Maximum payload per packet: **18 bytes** (fits one ATT_MTU=23 write request:
23 - 1 opcode - 3 ATT header - 1 transport header = 18).

### Glucose record (BLE, 11-byte payload)

Returned by the `0xB3 <lo> <hi>` command, inside the standard framing. After
stripping the framing and status byte (`0x06`), the remaining 11 bytes are:

| Offset | Length | Field | Notes |
|---|---|---|---|
| 0 | 4 | timestamp | LE uint32, seconds since 2000-01-01 (epoch 946684800) |
| 4 | 2 | glucose_value | LE int16, **mg/dL** (range typically 20–600) |
| 6 | 1 | control_solution_flag | 0 = normal blood test, 1 = control solution (skip) |
| 7 | 2 | counter/metadata | LE uint16; Verio Reflect: "Blood Sugar Mentor" data |
| 9 | 1 | meal_flag | 0 = none, 1 = before meal, 2 = after meal |
| 10 | 1 | sensor_status / other_flags | 0 = normal; non-zero on Verio Reflect |

### Glucose units
- The meter **always returns the value in mg/dL** as a LE int16, regardless
  of the meter's display setting.
- The meter's display unit (mg/dL or mmol/L) can be read via the
  `0x09 0x02 0x02` READ PARAMETER command, but this only affects display,
  not transmission.
- Conversion: `mmol/L = mg/dL × 0.0555` (equivalently `mg/dL / 18.018`).

### Context records
**No separate context record** — the meal flag is inline in the glucose
record (byte 9). Verio meters do NOT use the standard Bluetooth SIG
Glucose Measurement Context characteristic (`0x2A34`).

### Timestamp encoding
- LE uint32, **seconds since 2000-01-01 00:00:00 UTC**.
- Epoch offset to convert to Unix epoch: `946684800` seconds.
- Example: `seconds = 735_000_000` → Unix time `1681684800` → 2023-04-16.

---

## 6. Known Quirks

### Time sync
- The meter has its own real-time clock. xDrip does **NOT** set the meter's
  clock — it reads it and computes an offset to the phone's clock. This
  offset is then applied to every record's timestamp.
- ⚠️ If the user changes the meter's clock (daylight saving, battery
  replacement, manual adjustment) between two syncs, the timestamps of
  records taken with the old clock setting will be wrong after the change.
  **Always sync before changing the meter clock.**
- The WRITE RTC command (`0x20 0x01 <4-byte ts>`) exists if you want to set
  the meter clock, but xDrip avoids doing this.

### MTU
- Default 23-byte ATT MTU works. No need to request a larger MTU.

### Connection interval preferences
- Not publicly documented. Default slave latency / interval (7.5–4000 ms)
  works.

### Disconnection behavior
- The meter advertises only when powered on AND Bluetooth feature is enabled.
- The Bluetooth icon stays on the meter display for ~4 hours after the last
  reading. After 4 hours of inactivity the meter may power down the BLE radio.
- The Bluetooth feature **turns OFF during a blood glucose test** and turns
  back ON afterwards (Owner's Booklet page 29).

### Multiple phones paired simultaneously
- **Supported in theory** ("Your OneTouch Select Plus Flex™ Meter can be
  paired with multiple compatible wireless devices" — Owner's Booklet
  page 30) but **flaky in practice**.
- Recommendation: assume **one phone per meter at a time**. If the user
  wants to switch phones, unpair from the old phone first.

### CRC / checksum
- **CRC-16/CCITT-FALSE**: poly `0x1021`, init `0xFFFF`, no reflection, no
  xor-out. Stored **little-endian** as the last 2 bytes of the packet.

### MTU / queue serialization
- **All GATT writes to `af9df7a2` must be strictly serialized**: send one
  command, wait for the data notification, send ACK, then send the next
  command. The meter does not handle pipelined commands.

---

## 7. Code References

### Primary: xDrip (Apache-2.0)
- Repo: https://github.com/NightscoutFoundation/xDrip
- Issue #120 with full discussion:
  https://github.com/NightscoutFoundation/xDrip/issues/120
- Commit that added Verio Flex support (2017-06-08):
  https://github.com/NightscoutFoundation/xDrip/commit/49bfb340c5fefa66cfed154a995ab1ec47122923

Key files:
| File | Purpose |
|---|---|
| `app/src/main/java/com/eveningoutpost/dexdrip/glucosemeter/VerioHelper.java` | Verio protocol parser. UUIDs, command templates, packet framing, CRC verification, record parsing. **Skips auth.** |
| `app/src/main/java/com/eveningoutpost/dexdrip/services/BluetoothGlucoseMeter.java` | GATT state machine. LifeScan branch at line 357. Manages service discovery, notification subscription, command queue with ACK blocking. |
| `app/src/main/java/com/eveningoutpost/dexdrip/utils/CRC16ccitt.java` | CRC-16-CCITT implementation. |

### Secondary: xavaro (GPL-3.0) — has the AES auth!
- Repo: https://github.com/dezi/xavaro
- File: `asp/SafeHome/app/src/main/java/de/xavaro/android/safehome/BlueToothGlucoseOneTouch.java`

The **only** public source that implements the AES-128-ECB application-layer
authentication. Key methods:
| Method | Purpose |
|---|---|
| `getReadMeterChallenge()` | Sends `{0xE6, 0x02, 0x08}` |
| `parseMeterChallenge(byte[])` | Decodes the UTF-16LE hex challenge |
| `makeCipherToken(byte[])` | Byte-shuffles the challenge and AES-encrypts |
| `getEnableFeatures()` | Sends `{0x11, <token>}` |
| `parseResponseInternal(...)` | Multi-packet RX reassembly with ACK |
| `parseGlucoseRecord(byte[])` | Record field extraction |

Also see `asp/Common/common/src/main/java/de/xavaro/android/common/Simple.java`
for the `dezify()` XOR-deobfuscation function — the obfuscated key string
`"==:@M6J0JGMD?6=7839291L4M0?F011A"` decodes to hex
`483bd3c2cbdf6345160004e6d56d948c`.

### Tertiary: glucometerutils (MIT) — USB protocol reference
- Repo: https://github.com/glucometers-tech/glucometerutils
- File: `glucometerutils/drivers/otverio2015.py` — USB driver for OneTouch
  Verio 2015 / Select Plus / Select Plus Flex (USB). Confirms the opcodes
  and packet framing used over BLE.
- File: `glucometerutils/support/lifescan.py` — `crc_ccitt()` Python
  implementation (matches xDrip).

### Protocol documentation (Creative Commons BY 4.0)
- https://protocols.glucometers.tech/lifescan/onetouch-verio-2015 — explicitly
  lists the Select Plus Flex as a Verio 2015 family device.
- https://protocols.glucometers.tech/lifescan/shared-binary-protocol — packet
  framing spec.

### Commercial reference: Glucera.app (closed source, informative release notes)
- https://glucera.app — iOS app that supports OneTouch Verio meters via the
  proprietary protocol. Release notes confirm:
  - AF9DF7A1 service covers Verio Flex, Verio Reflect, HCD7.
  - Pairing is PIN/passkey-based.
  - Commands must be serialized one-at-a-time with ACK between writes.
  - 15-second sync timeout.
  - Random BD_ADDR that changes after re-entering pairing mode.

### Official OneTouch documentation
- OneTouch Select Plus Flex Owner's Booklet (PDF):
  https://www.diabetesarabia.me/sites/default/files/2021-05/Select%20Plus%20Flex%20-%20Owner%27s%20Handbook%20-%20EN.pdf
- FDA 510(k) for the US sibling Verio Flex (K150214):
  https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfpmn/pmn.cfm?ID=K150214
- FDA 510(k) for the US sibling Ultra Plus Flex (K151611):
  https://fda.innolitics.com/submissions/CH/subpart-b.../K151611

### Standard Bluetooth SIG Glucose Service (for reference, NOT used by this meter)
- Glucose Service `0x1808`:
  https://www.bluetooth.com/specifications/specs/glucose-service-1-0/
- Glucose Profile (GLP) 1.0.1:
  https://www.bluetooth.com/specifications/specs/glucose-profile-1-0.1/
- Glucose Measurement `0x2A18`, Glucose Measurement Context `0x2A34`,
  Glucose Feature `0x2A51`, Record Access Control Point `0x2A52`.

---

## 8. Open Questions

Things that are NOT publicly documented and would require either an HCI snoop
log or APK teardown to resolve:

1. **Is the AES-128-ECB application-layer auth required on every connection,
   or only on first-time pairing?** xDrip skips it and works against
   already-bonded meters. The safest assumption is "required on first BLE
   session after pairing, optional on subsequent sessions where the bond
   keys are still valid" — but this needs an HCI snoop log of the OneTouch
   Reveal app to confirm.

2. **Does the Select Plus Flex specifically carry non-zero "Blood Sugar
   Mentor" metadata in bytes 6–10** (like the Verio Reflect, which breaks
   xDrip's sanity check)? Or is it clean like the Verio Flex? Needs an
   actual capture. **Mitigation**: don't use xDrip's `info == 0` sanity
   check; instead validate `control_solution_flag == 0` and
   `20 ≤ glucose_value ≤ 600`.

3. **Exact byte assignment of the meal flag in the BLE 11-byte record.**
   The USB Verio 2015 protocol documents byte offsets clearly, but the BLE
   format is undocumented in public sources. xavaro doesn't decode it;
   xDrip skips it. Best guess: byte 9 (matches the USB protocol's meal-flag
   slot, modulo the missing inverse/lifetime counters).

4. **MTU and connection interval preferences** advertised by the meter. Not
   in any public source. Capture with an HCI snoop.

5. **Manufacturer-specific data in the advertising packet.** Not in any
   public source. Capture with an HCI snoop.

6. **Multi-packet reassembly rules for >18-byte responses.** The xavaro
   code implements it but the only responses that would exceed 18 bytes
   are the QUERY-language list response (USB only) and possibly some
   future firmware feature. For typical Verio sync (time, counts, single
   records), all responses fit in one packet.

7. **Whether there is a "report records newer than sequence N" filter
   opcode** on BLE (analogous to standard RACP `0x01 0x03 0x01 <seq>`).
   No public source documents one. You must iterate `0xB3 <seq>` one-by-one.

8. **The exact semantics of the `0x01` byte prefix** that xDrip prepends to
   single-packet TX. Is it a "single-packet marker"? Or is it a fixed
   command-framing byte that the meter expects on every write? Needs an HCI
   snoop comparing xDrip vs xavaro to determine.

9. **Does the Select Plus Flex expose the standard Device Information
   Service (0x180A) and Current Time Service (0x1805)?** xDrip reads them
   but the LifeScan branch skips the time read. Glucera.app reads them for
   diagnostic clock offset on standard 0x1808 meters but explicitly narrowed
   the OneTouch Verio path to skip them. Not critical for sync.

10. **The exact AES plaintext block layout** (`fchallenge` byte shuffle in
    `makeCipherToken`). The xavaro code does the shuffle as documented
    above and works empirically. If auth fails against a Select Plus Flex,
    try alternative shuffles. An HCI snoop of OneTouch Reveal connecting to
    a fresh meter would settle this definitively.

11. **LE Secure Connections vs Legacy Pairing.** The meter pairs with a
    6-digit PIN (Passkey Entry). Both LE Secure Connections (BT 4.2+) and
    Legacy Pairing support Passkey Entry. The meter supports Android 4.4+
    per xDrip testing, which implies Legacy Pairing is supported; modern
    Android/iOS will prefer LE Secure Connections. Not critical for the
    Flutter implementation — `flutter_blue_plus` handles this transparently.

---

## 9. Testing Checklist

Use this checklist to verify the Flutter implementation against a real meter:

### Prerequisites
- [ ] OneTouch Select Plus Flex meter, powered on, Bluetooth enabled
- [ ] Android phone (or Linux laptop with BlueZ 5.55+)
- [ ] Meter NOT currently paired to another phone (or unpair first)
- [ ] GlucoTrack app installed and onboarded

### Scan
- [ ] Tap "Sync from Meter" on the home screen
- [ ] Tap "Scan for OneTouch meters"
- [ ] Verify the meter appears in the list with name `OneTouch <serial4>`
- [ ] Verify the remote ID is shown (random MAC, changes after re-pairing)

### Pair
- [ ] Tap the meter in the list
- [ ] System pairing dialog appears
- [ ] Enter the 6-digit PIN shown on the meter LCD
- [ ] Pairing succeeds (bond stored on both sides)

### Sync
- [ ] Progress bar appears with "Subscribing to notifications…"
- [ ] Status changes to "Reading meter time…"
- [ ] Meter time is logged in the debug panel
- [ ] Status changes to "Reading test count…"
- [ ] Test count is logged
- [ ] Status changes to "Reading record count…"
- [ ] Record count is logged
- [ ] Records are read one-by-one (progress bar advances)
- [ ] Each record is logged with `seq`, `glucose`, `timestamp`
- [ ] Control solution records are skipped
- [ ] Final status: "Synced N record(s)."

### Persist
- [ ] Tap "Save to GlucoTrack"
- [ ] Snackbar shows "Saved N new reading(s)"
- [ ] Records appear on the home screen
- [ ] Re-syncing shows "skipped N duplicate(s)" — IDs are deterministic

### Troubleshooting
- If you see `UNAUTHORIZED (0x07)` status responses:
  - Set `tryAuth: true` in `OneTouchBleService` constructor
  - Re-sync — the AES challenge-response handshake will run
- If you see `Device disconnected unexpectedly`:
  - The meter's Bluetooth radio may have timed out (4 hours)
  - Re-enable Bluetooth on the meter (▲ + ▼)
- If scan finds no devices:
  - Verify meter is in pairing mode (BT icon visible on LCD)
  - Verify Android Bluetooth is on
  - Verify location permission is granted (Android 11-)
- If `OneTouch vendor service not found`:
  - The meter is connected but not paired (or bond was lost)
  - Unpair from Android Bluetooth settings and re-pair

---

## License & Attribution

This protocol specification is reverse-engineered from public sources and is
provided for interoperability purposes under fair use. All trademarks belong
to their respective owners. The OneTouch Reveal app and LifeScan meters are
products of LifeScan Inc. (Johnson & Johnson).

The Flutter implementation in `lib/ble/` is licensed under the same license
as the rest of GlucoTrack. The reference implementations it was derived from
are:
- xDrip (Apache-2.0): https://github.com/NightscoutFoundation/xDrip
- xavaro (GPL-3.0): https://github.com/dezi/xavaro
- glucometerutils (MIT): https://github.com/glucometers-tech/glucometerutils
