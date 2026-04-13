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
