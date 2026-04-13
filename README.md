## 게임 소개

*   추억을 3D공간에 보관하는 '퍼스널 메모리얼 갤러리(Personal Memorial Gallery)' 프로젝트입니다
*   1인칭 시점으로 오브젝트와 상호작용하며 해당 오브젝트에 사진을 담아 추억이 담긴 자신만의 인터렉티브 갤러리를 만들고 감상할 수 있습니다 

<img width="562" height="339" alt="image" src="https://github.com/user-attachments/assets/499f45a7-0f10-4ad9-b3ef-78f78294d066" />
<img width="562" height="307" alt="image" src="https://github.com/user-attachments/assets/33e407c1-1cdc-4779-b73d-cfcffd4f8862" />
<img width="562" height="353" alt="image" src="https://github.com/user-attachments/assets/62517cec-d5c8-4aaf-a3ea-10eeec7f851e" />

---

##  Tech Stack

### Core Engine & Language
*   **Game Engine**: Godot Engine v4.6.1
*   **Scripting Language**: GDScript

### Architecture & Design Patterns
*   **Component-Based Architecture**: 단일 거대 스크립트를 지양하고, 시스템을 철저히 독립적인 컴포넌트(`MovementComponent`, `InteractionComponent`, `MediaFrameComponent` 등) 노드로 분리하여 결합도 최소화
*   **Data-Driven Design**: 모든 주요 수치는 하드코딩하지 않고 외부 Resource 데이터(`*.tres`) 주입 방식을 채택하여 확장성 및 유지보수성 극대화
*   **Observer Pattern**: "Call down, Signal up" 원칙을 기반으로, 하위 컴포넌트의 상태 변화를 상위 시스템에 Signal로 전달하여 디커플링 구현
*   **Finite State Machine (FSM)**: 플레이어 및 주요 객체 행동을 유한 상태 머신으로 통제하여 논리적 충돌 방지

### Key Systems & Features
*   **Dynamic Media System**: 로컬 저장소 상호작용 및 해상도 비율 자동 계산을 적용한 동적 이미지 오버레이/텍스처 시스템 구축 
*   **Raycast Interaction**: 물리 엔진과 Raycast3D를 활용한 시야 기반 상호작용 및 UI 힌트 시스템 구현
*   **Native Save/Load System**: `.tres` 파일 포맷과 `user://` 경로를 활용한 로컬 독립적인 게임 진행도 저장 시스템

---

### 개발 방식
*   Antigravity를 통한 바이브 코딩을 활용하였으며 다음과 같은 아키텍쳐 원칙을 설계하고 이를 바탕으로 개발되었습니다 (`godot rules.md`)

1. **컴포넌트 중심 아키텍처 (Component-Based Design)**
   - 거대한 단일 스크립트(God Object)를 배제하고, `MovementComponent`, `InteractionComponent`, `MediaFrameComponent` 등 철저하게 단일 책임을 지는 소형 노드 단위로 기능을 분리했습니다.
   - 이를 통해 에러 발생 시 추적이 쉽고, 새로운 물체에 레고 블록처럼 기능을 쉽게 조립하여 재사용할 수 있습니다.

2. **결합도 최소화 (Loose Coupling)와 Observer 패턴**
   - 부모 노드나 다른 시스템을 직접 참조(하드코딩)하는 것을 피했습니다.
   - 자식 노드의 상태 변화는 오직 `Signal(Event)`을 통해서만 상위로 전달되며, 상위 구조는 하위 구조에 직접 함수를 호출하는 "Call Down, Signal Up" 방식을 채택하여 시스템 간의 간섭을 최소화했습니다.

3. **데이터 주도 설계 (Data-Driven Design)**
   - 스크립트 내부에 `hp = 100`, `speed = 5.0` 같은 매직 넘버를 적지 않고, 고도의 리소스 시스템(`.tres`)과 `@export` 변수를 활용하여 외부에서 데이터를 주입받는 형태로 구축했습니다. 
   - 기획자가 코드를 열지 않고도 에디터에서 수치를 조정할 수 있는 유연한 구조를 지향합니다.

---

### QA & Troubleshooting
*   상세 테스트케이스와 버그리포트 `QA_TestCase, BugReport.xlsx `

---

### Credits
*   이 프로젝트는 미완성(WIP) 상태이며, 무료 에셋들을 사용해 테스트 중입니다
*   이 프로젝트에서 사용된 3D 에셋 및 기타 리소스의 저작권과 라이선스 정보는 Credits.txt 파일에서 확인하실 수 있습니다.
