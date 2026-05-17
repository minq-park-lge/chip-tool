`chip-tool` 자체는 Matter Controller 역할을 하고,
실제 transport 는 아래처럼 조합됩니다.

* BLE → 커미셔닝 시작
* Thread → operational network
* Wi-Fi → operational network
* NFC → onboarding payload 전달용(QR 대체)

즉, `chip-tool` 에서 핵심은:

1. BLE 로 commissioning
2. Wi-Fi 또는 Thread credential 전달
3. NFC 는 별도 NDEF payload 생성

입니다.

보통 아래 조합으로 사용합니다.

---

# 1. Wi-Fi Matter Device Commissioning

Wi-Fi 디바이스를 붙일 때:

```bash
./chip-tool pairing ble-wifi <node-id> <ssid> <password> <setup-pin-code> <discriminator>
```

예시:

```bash
./chip-tool pairing ble-wifi 1234 mywifi mypass 20202021 3840
```

의미:

* `1234`
  → Matter node id
* `mywifi`
  → AP SSID
* `mypass`
  → AP password
* `20202021`
  → setup PIN
* `3840`
  → discriminator

---

# 2. Thread Matter Device Commissioning

Thread 는 Active Operational Dataset 을 넘겨야 함.

명령:

```bash
./chip-tool pairing ble-thread <node-id> <dataset-hex> <setup-pin-code> <discriminator>
```

예시:

```bash
./chip-tool pairing ble-thread 1234 \
0e080000000000010000000300000f35060004001fffe00208dead00beef00cafe0708fd123456789abcde051000112233445566778899aabbccddeeff030f4f70656e5468726561642d64656d6f010212340410ad463152f9622c7297ec6c6c543a63e30c0402a0f7f8 \
20202021 3840
```

---

# 3. Thread + Wi-Fi 둘 다 가능한 디바이스

Matter spec 상 실제 operational network 는 하나 선택됩니다.

즉 commissioning 시:

* `ble-thread`
* 또는 `ble-wifi`

중 하나를 사용.

둘 다 동시에 넘기는 인자는 없음.

---

# 4. NFC 사용

Matter 의 NFC 는 commissioning payload 전달용입니다.

즉:

* QR code
* manual code
* NFC tag

셋 중 하나.

`chip-tool` 에 NFC 직접 읽기 옵션은 거의 없고,
보통 onboarding payload 생성 후 NFC tag 에 기록합니다.

payload 생성:

```bash
./chip-tool payload generate-qrcode \
  --vendor-id 0xFFF1 \
  --product-id 0x8000 \
  --discriminator 3840 \
  --setup-pin-code 20202021
```

또는 manual code:

```bash
./chip-tool payload generate-manualcode \
  --vendor-id 0xFFF1 \
  --product-id 0x8000 \
  --discriminator 3840 \
  --setup-pin-code 20202021
```

이 문자열을 NFC NDEF 에 저장.

스마트폰 Matter commissioner 가 NFC 를 읽고 commissioning 시작.

---

# 5. Controller 측 필수 조건

## Thread commissioning 하려면

controller 머신에:

* Thread Border Router
* OpenThread BR
* Apple HomePod
* Google Nest Hub

같은 Thread network access 가 필요.

그리고 dataset 확보 필요:

```bash
ot-ctl dataset active -x
```

---

# 6. 실사용에서 가장 많이 쓰는 형태

## Wi-Fi Device

```bash
chip-tool pairing ble-wifi ...
```

## Thread Device

```bash
chip-tool pairing ble-thread ...
```

## NFC onboarding

NFC tag 안에:

* QR payload
* Manual pairing code

저장.

---

# 7. Linux에서 Thread + BLE + NFC까지 다 붙이는 전형적인 구성

보통:

* Ubuntu/Linux
* BlueZ
* OpenThread Border Router
* libnfc
* chip-tool

조합.

빌드 옵션 예:

```bash
gn gen out/debug \
  --args='
    chip_enable_openthread=true
    chip_inet_config_enable_ipv4=true
    chip_config_network_layer_ble=true
'
```

빌드:

```bash
ninja -C out/debug chip-tool
```

---

# 8. 핵심 정리

`chip-tool` 인자는 실제로는:

| 기능                   | 명령                   |
| -------------------- | -------------------- |
| Wi-Fi commissioning  | `pairing ble-wifi`   |
| Thread commissioning | `pairing ble-thread` |
| NFC onboarding       | `payload generate-*` |

입니다.

NFC 는 transport 가 아니라 onboarding carrier 라서,
`pairing ble-nfc` 같은 개념은 없습니다.

