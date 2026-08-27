"""
vdump.py — ARM64 NEON 벡터 레지스터 디버깅용 lldb 커스텀 명령어
RealManMastery (상남자마스터코스) 강좌용

■ 배경 지식 (강의 참고용)
  ARM64의 벡터 레지스터 V0~V31 은 각각 128비트(16바이트) 크기다.
  같은 물리적 공간을 몇 칸으로 쪼개서 보느냐에 따라 접미사가 바뀐다:

      .B  (Byte)   →  8비트  × 16칸   V1.16B
      .H  (Half)   → 16비트  ×  8칸   V1.8H
      .S  (Single) → 32비트  ×  4칸   V1.4S
      .D  (Double) → 64비트  ×  2칸   V1.2D

  또한 메모리에 저장된 바이트를 "숫자"로 해석하는 방식도 여러 가지다:
      부호 없는 정수(unsigned) / 부호 있는 정수(signed) / 부동소수점(float)
  같은 비트 패턴이라도 어떻게 해석하느냐에 따라 화면에 찍히는 값이 완전히
  달라진다는 걸 눈으로 직접 보여주기 위해, 이 스크립트는 -m 옵션으로
  해석 방식을 바꿔가며 볼 수 있게 만들었다.

  ARM64는 리틀 엔디안(little-endian)이 기본이라, 바이트를 조합해 숫자로
  만들 때 "낮은 주소 바이트가 숫자의 하위 자리"가 된다. 이 스크립트도
  그 규칙을 그대로 따른다 (byteorder="little").

사용법 (lldb 프롬프트 안에서):
    vdump v1                # V1.4S, 부호 없는 정수(기본값)
    vdump v1 2d              # V1.2D = 64비트 2칸
    vdump v1 4s s             # V1.4S 를 "부호 있는" 정수로 해석
    vdump v1 4s f              # V1.4S 를 "32비트 float" 4개로 해석 (FADD/FMUL 결과 확인용)
    vdump v1 2d f               # V1.2D 를 "64비트 double" 2개로 해석
    vdump v1 4s x                # V1.4S 를 16진수(hex)로 표시
    vdumpall v0 v3               # V0~V3 을 한 번에 4S/unsigned로 덤프
    vdumpall v0 v3 4s f            # V0~V3 을 float 로 한 번에 덤프

로드 방법 (.lldbinit 에서):
    command script import scripts/vdump.py
"""

import struct

# lldb 커맨드 스크립트로 로드될 때는 lldb 모듈이 이미 준비되어 있다.
# (혹시 lldb 밖에서 이 파일을 python 인터프리터로 직접 실행해볼 경우를
#  대비해서만 안전하게 예외 처리 — 평소엔 이 except 블록을 탈 일이 없다.)
try:
    import lldb
except ImportError:
    lldb = None  # lldb 세션 밖에서 import될 때를 위한 안전장치


# 레이아웃: 접미사 -> (칸 개수, 칸당 비트 수)
LAYOUTS = {
    "16b": (16, 8),
    "8h":  (8, 16),
    "4s":  (4, 32),
    "2d":  (2, 64),
    # 개수 표기 없이 문자만 쳐도 되게 허용 (예: vdump v1 s)
    "b":   (16, 8),
    "h":   (8, 16),
    "s":   (4, 32),
    "d":   (2, 64),
}
DEFAULT_LAYOUT = "4s"

# 해석 모드: u=부호없음(기본), s=부호있음, x=16진수, f=부동소수점
VALID_MODES = ("u", "s", "x", "f")
DEFAULT_MODE = "u"

SUFFIX_DISPLAY = {8: "B", 16: "H", 32: "S", 64: "D"}


def _get_frame(debugger):
    process = debugger.GetSelectedTarget().GetProcess()
    thread = process.GetSelectedThread()
    return thread.GetSelectedFrame()


def _read_bytes(frame, reg_name):
    """128비트 벡터 레지스터의 raw 바이트를 반환. 못 찾으면 None."""
    reg = frame.FindRegister(reg_name)
    if not reg.IsValid():
        # 일부 lldb 버전/타깃에서는 v1 대신 q1 이름으로 노출되기도 함
        alt = "q" + reg_name[1:] if reg_name.startswith("v") else None
        if alt:
            reg = frame.FindRegister(alt)
        if not reg.IsValid():
            return None

    err = lldb.SBError()
    data = reg.GetData()
    size = data.GetByteSize()
    raw = bytearray()
    for i in range(size):
        raw.append(data.GetUnsignedInt8(err, i))
    return bytes(raw)


def _format_value(chunk, bits, mode):
    """바이트 조각(chunk) 하나를 지정된 모드로 해석해 사람이 읽을 문자열로 변환."""
    if mode == "x":
        width = bits // 4  # 16진수 자릿수 = 비트수/4
        val = int.from_bytes(chunk, byteorder="little", signed=False)
        return f"0x{val:0{width}x}"

    if mode == "f":
        if bits == 32:
            return f"{struct.unpack('<f', chunk)[0]:.6g}"
        if bits == 64:
            return f"{struct.unpack('<d', chunk)[0]:.6g}"
        # 8비트/16비트 칸은 IEEE 표준 float로 해석할 수 없음 (half-float은 별도 처리 필요)
        raise ValueError(f"{bits}비트 칸은 float 모드를 지원하지 않는다네 (32S 또는 2D만 가능)")

    signed = (mode == "s")
    val = int.from_bytes(chunk, byteorder="little", signed=signed)
    return str(val)


def _split_layout_mode(args, start_idx):
    """args 리스트에서 [레이아웃] [모드] 부분을 파싱. 대소문자 관계없이 허용."""
    layout_key = DEFAULT_LAYOUT
    mode = DEFAULT_MODE

    remaining = [a.lower() for a in args[start_idx:]]
    for token in remaining:
        if token in LAYOUTS:
            layout_key = token
        elif token in VALID_MODES:
            mode = token
        else:
            raise ValueError(
                f"'{token}' 을(를) 이해 못했네. "
                f"레이아웃: {sorted(set(LAYOUTS))} / 모드: {list(VALID_MODES)}"
            )
    return layout_key, mode


def _dump_one_register(frame, reg_name, layout_key, mode):
    """레지스터 하나를 해석해서 (표시용 라벨, 값 리스트) 로 반환. 실패 시 None."""
    raw = _read_bytes(frame, reg_name)
    if raw is None:
        return None

    count, bits = LAYOUTS[layout_key]
    nbytes = bits // 8
    values = [
        _format_value(raw[i * nbytes:(i + 1) * nbytes], bits, mode)
        for i in range(count)
    ]
    label = f"{reg_name.upper()}.{count}{SUFFIX_DISPLAY[bits]}"
    if mode != "u":
        label += f" [{ {'s': 'signed', 'x': 'hex', 'f': 'float'}[mode] }]"
    return label, values


def dump_vector(debugger, command, result, internal_dict):
    """vdump <레지스터> [레이아웃] [모드] — 벡터 레지스터 하나를 보기 좋게 출력."""
    args = command.split()
    if not args:
        result.SetError("사용법: vdump <레지스터> [레이아웃] [모드]  예) vdump v1 4s f")
        return

    reg_name = args[0].lower()
    if not (reg_name.startswith("v") and reg_name[1:].isdigit() and 0 <= int(reg_name[1:]) <= 31):
        result.SetError(f"'{args[0]}' 은(는) 유효한 벡터 레지스터가 아니네. v0~v31 형식으로 입력해줘.")
        return

    try:
        layout_key, mode = _split_layout_mode(args, 1)
    except ValueError as e:
        result.SetError(str(e))
        return

    frame = _get_frame(debugger)
    try:
        dumped = _dump_one_register(frame, reg_name, layout_key, mode)
    except ValueError as e:
        result.SetError(str(e))
        return

    if dumped is None:
        result.SetError(f"레지스터 '{reg_name}' 을(를) 찾을 수 없다네.")
        return

    label, values = dumped
    print(f"{label} = [{', '.join(values)}]")


def dump_all_vectors(debugger, command, result, internal_dict):
    """vdumpall <시작레지스터> <끝레지스터> [레이아웃] [모드] — 범위 전체를 한 번에 덤프."""
    args = command.split()
    if len(args) < 2:
        result.SetError(
            "사용법: vdumpall <시작레지스터> <끝레지스터> [레이아웃] [모드]  "
            "예) vdumpall v0 v3 4s f"
        )
        return

    start_token = args[0].lower()
    end_token = args[1].lower()
    if not (start_token.startswith("v") and end_token.startswith("v")):
        result.SetError("레지스터는 v0, v1 ... 형식으로 입력해줘 (예: vdumpall v0 v3).")
        return

    try:
        start_idx = int(start_token.lstrip("v"))
        end_idx = int(end_token.lstrip("v"))
    except ValueError:
        result.SetError(f"'{args[0]}' / '{args[1]}' 에서 레지스터 번호를 못 읽었네.")
        return

    if not (0 <= start_idx <= 31 and 0 <= end_idx <= 31):
        result.SetError("레지스터 번호는 0~31 범위여야 하네.")
        return
    if start_idx > end_idx:
        start_idx, end_idx = end_idx, start_idx  # 순서 바뀌어 들어와도 알아서 정렬

    try:
        layout_key, mode = _split_layout_mode(args, 2)
    except ValueError as e:
        result.SetError(str(e))
        return

    frame = _get_frame(debugger)
    for i in range(start_idx, end_idx + 1):
        reg_name = f"v{i}"
        try:
            dumped = _dump_one_register(frame, reg_name, layout_key, mode)
        except ValueError as e:
            print(f"{reg_name.upper()} = (에러: {e})")
            continue
        if dumped is None:
            print(f"{reg_name.upper()} = (읽기 실패)")
            continue
        label, values = dumped
        print(f"{label} = [{', '.join(values)}]")


def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand('command script add -f vdump.dump_vector vdump')
    debugger.HandleCommand('command script add -f vdump.dump_all_vectors vdumpall')
    print('vdump / vdumpall 명령어 로드 완료 (RealManMastery) — 모드: u(기본)/s/x/f')