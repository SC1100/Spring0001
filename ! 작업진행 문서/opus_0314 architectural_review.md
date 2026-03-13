# PJ_Dear — 아키텍처 리뷰 보고서

> 코더가 아닌 **아키텍트 관점**에서, `godot lorebook.md`의 4대 원칙을 기준으로 현재 코드베이스를 평가합니다.

---

## 1. Lorebook 원칙별 준수 현황

### ✅ 원칙 1 — 컴포넌트 중심 (Composition)

**판정: 매우 양호**

현재 프로젝트는 이 원칙을 교과서적으로 따르고 있습니다.

| 컴포넌트 | 역할 | 평가 |
|----------|------|------|
| [MovementComponent.gd](file:///c:/GODOT%20PJ/PJ_Dear/scenes/components/MovementComponent.gd) | 이동 가속/감속/중력 | ✅ 순수 로직, 부모에 의존 주입 |
| [CameraControllerComponent.gd](file:///c:/GODOT%20PJ/PJ_Dear/scenes/components/CameraControllerComponent.gd) | 마우스 룩 | ✅ `@export`로 노드 주입 |
| [InteractionComponent.gd](file:///c:/GODOT%20PJ/PJ_Dear/scenes/components/InteractionComponent.gd) | 상호작용 감지 | ✅ 레이캐스트 기반, 느슨한 결합 |
| [Interactable.gd](file:///c:/GODOT%20PJ/PJ_Dear/scenes/components/Interactable.gd) | 상호작용 대상 마커 | ✅ 시그널 방출 패턴 |
| [BillboardViewerComponent.gd](file:///c:/GODOT%20PJ/PJ_Dear/scenes/components/BillboardViewerComponent.gd) | 3D 빌보드 미디어 표시 | ✅ 독립 연출 컴포넌트 |
| [AtmosphericLightingComponent.gd](file:///c:/GODOT%20PJ/PJ_Dear/scenes/components/AtmosphericLightingComponent.gd) | 환경 조명/안개 | ✅ 분위기 제어 분리 |

[Player.gd](file:///c:/GODOT%20PJ/PJ_Dear/scenes/characters/Player.gd)가 단 21줄이라는 사실이 좋은 징표입니다 — "거대한 단일 스크립트" 안티패턴을 완벽히 피하고 있습니다.

---

### ✅ 원칙 2 — 결합도 최소화 (Decoupling)

**판정: 양호 (경미한 주의사항 1건)**

| 파일 | 방식 | 평가 |
|------|------|------|
| CameraControllerComponent | `@export`로 노드 주입 | ✅ 하드코딩 없음 |
| InteractionComponent | `@export`로 RayCast 주입 | ✅ 하드코딩 없음 |
| Player.gd | `$MovementComponent` (onready) | ⚠️ 아래 설명 |
| MediaFrame.gd | `$Interactable`, `$FileDialog`, `$BillboardViewer` | ⚠️ 아래 설명 |

> [!NOTE]
> **`$`(NodePath) 사용에 대하여** — `Player.gd`의 `$MovementComponent`나 `MediaFrame.gd`의 `$Interactable` 등은 **자기 자신의 직속 자식 노드**를 참조하는 것이므로, lorebook이 금지하는 "다른 노드의 트리 경로를 하드코딩하여 참조"와는 성격이 다릅니다. 같은 씬 내 부모→자식 참조는 Godot에서 관용적으로 허용되는 패턴이기 때문에, 현 수준은 **위반이 아닌 허용 범위**입니다.
>
> 다만, 한 가지 아쉬운 점은 `MovementComponent`의 `get_parent() as CharacterBody3D` 패턴입니다. 이것은 부모의 **타입**에 암묵적으로 의존하는 것이라 `@export var body: CharacterBody3D`로 명시적 주입 방식으로 바꾸면 lorebook 철학에 더 부합합니다. (CameraControllerComponent가 이미 이 방식을 쓰고 있어, 일관성 차원에서도 권장됩니다.)

**한 가지 주의할 점:**
- [MediaFrame.gd](file:///c:/GODOT%20PJ/PJ_Dear/scenes/environment/MediaFrame.gd) 40~42행에서 `get_node_or_null("/root/Global")`로 싱글톤에 접근합니다. 이것 자체는 안전한 패턴이지만, lorebook이 말하는 "무분별한 남용 금지"를 위해 향후 이런 접근이 늘어나면 **이벤트 버스(신호 기반)** 패턴으로 전환하는 것을 검토해야 합니다.

---

### ⚠️ 원칙 3 — 데이터 주도 설계 (Data-Driven)

**판정: 부분 준수 (개선 여지 존재)**

**잘 된 부분:**
- [PetData.gd](file:///c:/GODOT%20PJ/PJ_Dear/resources/data/PetData.gd)가 `extends Resource`로 `.tres` 파일로 직렬화 가능한 데이터 컨테이너 역할을 합니다 → ✅
- 대부분의 컴포넌트가 `@export`로 수치를 외부에서 주입받습니다 → ✅
- 씬 파일(`Player.tscn`)에서 `speed = 4.0`, `acceleration = 8.0` 등을 인스펙터 수준에서 오버라이드합니다 → ✅

**개선이 필요한 부분:**

| 위치 | 하드코딩된 값 | lorebook 기준 |
|------|-------------|---------------|
| MovementComponent.gd:21 | `9.8` (중력) | ⚠️ `@export var gravity: float = 9.8` 권장 |
| AtmosphericLightingComponent.gd:7 | `Color(1.0, 0.95, 0.8)` (기본값) | △ `@export` 기본값이므로 허용 범위 |
| BillboardViewerComponent.gd:38 | `0.3` (페이드 시간) | ⚠️ `@export var fade_duration` 권장 |
| MediaFrame.gd:6 | `5.0` (상호작용 거리) | ✅ 이미 `@export`로 되어 있음 |

> [!IMPORTANT]
> 중력 `9.8`은 전형적인 **Magic Number**입니다. lorebook이 명시적으로 금지하는 패턴이므로 `@export`로 빼는 것이 원칙에 부합합니다. 이것이 현재 코드베이스에서 가장 명확한 lorebook 위반 사례입니다.

---

### ✅ 원칙 4 — 로직 제어 및 통신 (Signal Up, Call Down)

**판정: 양호**

| 사례 | 방향 | 패턴 | 평가 |
|------|------|------|------|
| Interactable → MediaFrame | 자식 → 부모 | `signal interacted` | ✅ Signal Up |
| MediaFrame → BillboardViewer | 부모 → 자식 | `viewer_instance.show_media()` | ✅ Call Down |
| Player → MovementComponent | 부모 → 자식 | `movement_component.handle_movement()` | ✅ Call Down |
| GameStateManager | 전역 | `signal state_changed` | ✅ Signal 기반 |
| FileDialog → MediaFrame | 시그널 연결 | `.tscn`에서 connection 설정 | ✅ |

통신 패턴이 lorebook의 "위로는 시그널, 아래로는 함수" 원칙을 정확히 따르고 있습니다.

---

### ⚠️ 원칙 5 — FSM (유한 상태 머신)

**판정: 골격만 존재, 실제 적용 미완**

[GameStateManager.gd](file:///c:/GODOT%20PJ/PJ_Dear/scripts/global/GameStateManager.gd)에 `enum GameState { START, CUSTOMIZE, TRANSITION, MEMORIAL }` 상태가 정의되어 있으나:

- `_handle_scene_transition`의 4개 상태 중 **MEMORIAL만 실제 구현**, 나머지 3개는 `pass` 상태
- 플레이어(Player) 레벨의 FSM이 **아직 없음** — lorebook에서 "플레이어 및 주요 객체의 행동(대기, 이동, 컷신 등)은 FSM 패턴으로 철저히 통제"라고 되어 있으므로, 향후 Player에 `IDLE / WALKING / INTERACTING / CUTSCENE` 같은 상태 머신이 필요합니다
- 현재 `Player.gd`는 항상 이동 입력을 받으므로, 컷신이나 UI 조작 중에도 이동이 가능한 버그가 발생할 수 있는 구조입니다

---

### ✅ 원칙 6 — 폴더 구조 및 명명

**판정: 우수**

```
현재 구조                              lorebook 기준
─────────────────────────────         ─────────────────────
scenes/components/                    ✅ 일치
scenes/characters/                    ✅ (lorebook 확장)
scenes/environment/                   ✅ (lorebook 확장)
scenes/ui/                            ✅ (lorebook 확장)
resources/data/                       ✅ 일치
scripts/global/                       ✅ 일치
shaders/                              ✅ 합리적 확장
assets/{models,textures,audio,anim}/  ✅ 합리적 확장
```

파일명도 `[역할]Component.gd` 규칙을 일관되게 따르고 있습니다. 유일한 예외는 [Interactable.gd](file:///c:/GODOT%20PJ/PJ_Dear/scenes/components/Interactable.gd)인데, 이것은 "Component"가 아닌 "마커/인터페이스" 성격이므로 현재 이름이 더 적절합니다.

---

### ✅ 원칙 7 — 파일 I/O 및 프라이버시

**판정: 양호**

- `Global.gd`의 `save_game()`이 `user://` 경로를 사용합니다 → ✅
- `MediaFrame.gd`의 `FileDialog`가 로컬 파일만 접근합니다 → ✅
- 외부 서버 통신 코드가 전혀 없습니다 → ✅

---

## 2. 설계상 주의 깊게 볼 점

### 2-1. `MediaViewer.tscn` — 인라인 스크립트

[MediaViewer.tscn](file:///c:/GODOT%20PJ/PJ_Dear/scenes/ui/MediaViewer.tscn)은 GDScript가 `.tscn` 파일 내부에 `sub_resource`로 인라인 작성되어 있습니다.

```
[sub_resource type="GDScript" id="GDScript_viewer"]
script/source = "extends Control..."
```

이 방식은:
- 버전 관리(Git)에서 변경 추적이 어렵습니다
- 에디터 자동완성/린팅 등 IDE 기능을 활용하기 어렵습니다
- lorebook의 "독립적인 노드/컴포넌트" 철학과 맞지 않습니다

**제안:** 별도 `.gd` 파일로 분리하여 `scenes/ui/MediaViewer.gd`로 만드는 것이 좋습니다.

### 2-2. `MovementComponent`의 부모 타입 암묵적 의존

```gdscript
@onready var body: CharacterBody3D = get_parent() as CharacterBody3D
```

이것은 "이 컴포넌트의 부모는 반드시 CharacterBody3D여야 한다"는 **암묵적 계약**입니다. `CameraControllerComponent`가 `@export var character_body: CharacterBody3D`로 명시적 주입을 하는 것과 비교하면 **일관성이 깨져** 있습니다.

### 2-3. `BillboardViewerComponent` vs `MediaViewer` — 역할 중복

현재 **같은 미디어 표시 기능**이 두 곳에 나뉘어 있습니다:
- `BillboardViewerComponent` — 3D 월드에서 빌보드로 표시
- `MediaViewer.tscn` — 2D UI 오버레이로 표시

현 시점에서 `MediaViewer.tscn`은 **어디서도 인스턴스화/사용되지 않고 있습니다**. 향후 어떤 뷰어 전략을 채택할지 결정하고, 사용하지 않는 쪽을 정리하거나 역할을 명확히 분리할 필요가 있습니다.

---

## 3. 전체 완성도 평가

### 스코어카드

| 영역 | 완성도 | 설명 |
|------|--------|------|
| **아키텍처/설계** | ⭐⭐⭐⭐☆ (80%) | lorebook 원칙을 대부분 훌륭히 준수. Magic Number 1건, FSM 미적용 1건 |
| **코어 시스템** | ⭐⭐⭐☆☆ (55%) | 이동/카메라/상호작용/조명의 기초가 있지만, FSM·세이브/로드·시간연동 미구현 |
| **게임 플로우** | ⭐⭐☆☆☆ (25%) | GameStateManager 골격만 존재, 4개 상태 중 1개만 동작 |
| **콘텐츠** | ⭐☆☆☆☆ (10%) | CSG 프로토타입 방 1개, 3D 에셋 없음 (기획 단계로서는 정상) |
| **연출/감정** | ⭐⭐☆☆☆ (20%) | 페이드 인/아웃, 안개, 빌보드 등 기초 연출 있음. 셰이더·사운드 미구현 |

### 종합 완성도: **약 25~30%** (프로토타입 초기 단계)

---

## 4. 아키텍트로서의 종합 소견

### 잘한 점 — 진짜 칭찬할 부분

1. **입문자 수준을 넘는 구조적 사고** — 첫 프로젝트에서 컴포넌트 패턴, Signal Up/Call Down, `@export` 의존성 주입을 일관되게 적용한 것은 흔치 않습니다. 대부분의 입문자는 하나의 거대한 스크립트에 모든 것을 때려넣는데, 그 함정을 처음부터 피하고 있습니다.

2. **Lorebook을 "규칙서"가 아닌 "철학"으로 이해** — 단순히 규칙을 따르는 것이 아니라 각 스크립트에 `## 로어북 규칙 준수: ...` 주석을 달아 **왜 이런 구조인지**를 기록한 것은 유지보수 관점에서 매우 좋은 습관입니다.

3. **폴더 구조의 성숙도** — `scenes/components`, `resources/data`, `scripts/global` 등의 분류가 깔끔합니다. 프로젝트가 커져도 이 구조가 흔들리지 않을 기반이 되어 있습니다.

### 앞으로의 핵심 과제 (우선순위 순)

1. 🔴 **Player FSM 도입** — 현재 가장 시급한 아키텍처 부재입니다. `IDLE / WALKING / INTERACTING / CUTSCENE` 상태 없이는 게임 플로우(문 열기, 커스터마이즈 등) 구현 시 반드시 꼬임이 발생합니다.
2. 🟡 **Magic Number 정리** — 중력 `9.8`, 페이드 `0.3초` 등의 상수를 `@export`로 전환
3. 🟡 **MediaViewer.tscn 인라인 스크립트 분리** — `.gd` 파일로 분리
4. 🟡 **MovementComponent의 `get_parent()` 패턴 통일** — `@export` 패턴으로 일관성 확보
5. 🟢 **GameStateManager 상태 전환 구현 채우기** — 현재 `pass`인 3개 상태 실제 구현

> [!TIP]
> 현재 코드베이스의 "뼈대"는 매우 건강합니다. 이 구조를 유지하면서 살을 붙여 나가면 됩니다. 입문자가 이 수준의 아키텍처를 첫 프로젝트에서 구축한 것은 lorebook이라는 명확한 가이드라인의 힘이기도 하고, 그것을 충실히 따른 결과이기도 합니다.
