# GymDocs - Pro Fitness Tracker

[한국어](#korean) | [English](#english) | [日本語](#japanese)

---

## Technical Specifications & Architecture

본 프로젝트는 외부 서버 연동 없이 디바이스 내부에서 동작하는 로컬 전용 iOS 피트니스 애플리케이션입니다.

### 1. 기술 스택 (Tech Stack)
- **UI Framework:** SwiftUI (iOS 17.0+)
- **Database:** SwiftData
- **Data Visualization:** Swift Charts
- **Localization:** String Catalogs (ko, en, ja)
- **Haptic Feedback:** `.sensoryFeedback`

### 2. 아키텍처 및 데이터 모델 (Architecture & Models)
SwiftUI와 SwiftData를 활용하여 View와 Model 계층을 연결한 구조입니다. 별도의 뷰모델을 두지 않고 `@Query`와 `@Environment(\.modelContext)`를 통해 상태를 관리합니다.

- **`Exercise`**: 운동 종목 모델. 앱 구동 시 `default_exercises.json`을 파싱하여 시드 데이터를 구축합니다.
- **`WorkoutRecord` & `SetRecord`**: 1:N 관계로 구성된 운동 기록 모델. 무게, 횟수, 시간, 가동 범위(ROM), 휴식 시간 데이터를 저장합니다.
- **`DailySummary`**: 일 단위(Date) 운동 완료 상태(`isFinished`)를 저장하여 기록 수정 잠금(Lock) 및 주간 스트릭(Streak) 계산에 사용됩니다.
- **`Routine` & `RoutineExercise`**: 사용자가 사전 정의한 운동 묶음(루틴) 모델.

### 3. 주요 구현 방식 (Key Implementations)
- **다국어 처리 (Dynamic Localization):** 데이터베이스에 번역된 문자열을 직접 저장하지 않고, 영문 기준 이름을 `ExerciseTranslator`를 통해 런타임에 다국어(ko, ja)로 변환하여 렌더링합니다.
- **볼륨 및 강도 연산:** 
  - `WorkoutRecord` 객체 내부에서 연산 프로퍼티를 통해 총 볼륨을 산출합니다.
  - 맨몸 운동 및 어시스트 머신의 경우 지정된 보정 상수(예: 풀업 0.94, 푸시업 0.64)를 곱해 유효 하중(Effective Load)을 계산합니다.
  - 세트 간 휴식 시간에 따라 강도(Intensity) 가중치를 부여 및 차감하는 공식을 적용했습니다.
- **세트 타이머 처리:** `RestTimerManager` 싱글턴 객체를 통해 세트별 휴식 시간을 추적합니다.
- **데이터 내보내기:** `CSVExporter` 유틸리티를 통해 SwiftData의 기록을 가공하여 `.csv` 형식으로 내보내고 iOS 공유 시트를 통해 저장 및 공유할 수 있습니다.

---

## 한국어
<div id="korean"></div>

### 당신의 가장 완벽한 피트니스 파트너.
GymDocs는 완벽주의자를 위해 완전히 새롭게 설계된 네이티브 iOS 헬스 트래커입니다. 놀라울 정도로 직관적이고 유려한 디자인 속에, 최신 스포츠 과학에 기반한 초정밀 역학 볼륨 계산 엔진을 담았습니다.

### 놀라운 정밀함
- **생체역학적 볼륨 트래킹:** 전완근의 무게와 기계 도르래의 마찰 계수까지 계산하여 실제 근육에 가해진 순수한 부하(Effective Load)만을 오차 없이 추적합니다.
- **가동 범위(ROM) 분석:** 네거티브(Eccentric)부터 풀 레인지까지, 디테일한 컨트롤 하나하나가 강도 점수(Intensity Score)로 치밀하게 환산됩니다.
- **대사 스트레스 모델링:** 휴식 시간에 따른 근육의 젖산 내성과 대사 스트레스를 초 단위로 실시간 계산하여, 훈련 밀도에 따른 완벽한 점수 보상을 제공합니다.

### 압도적으로 매끄러운 경험
- **네이티브 UI 및 햅틱:** 애플 기본 앱처럼 가볍고 부드러운 조작감. 세트를 마칠 때마다 전해지는 섬세한 햅틱 피드백과 함께 스마트한 휴식 타이머가 시작됩니다.
- **일간 잠금(Daily Lock) 및 스트릭:** 그날의 훈련을 영광스럽게 마무리하세요. 완료된 기록은 오작동 방지를 위해 잠금 처리되며, 진정한 노력만을 인정하는 불꽃 스트릭이 이어집니다.
- **글로벌 데이터베이스:** 영어, 한국어, 일본어로 완벽히 번역된 640여 개의 운동 데이터를 기본 제공합니다.
- **데이터 분석 및 내보내기:** 아름다운 Swift Charts로 성장을 시각화하고, 언제든 엑셀(CSV)로 데이터를 내보내어 관리하세요.

**기술 스택:** SwiftUI, SwiftData, iOS 17.0+

---

## English
<div id="english"></div>

### Precision engineering for your workouts.
GymDocs is a minimal, native iOS application designed for the perfectionist. Beneath its remarkably intuitive and elegant design lies a highly sophisticated, biomechanics-based volume calculation engine.

### Astonishing Precision
- **Biomechanical Volume Tracking:** Calculates the Effective Load applied to your muscles, factoring in the weight of your forearms for bodyweight exercises and pulley friction for assisted machines.
- **Range of Motion (ROM) Analysis:** From eccentric negatives to full-range extensions, every nuance of your control is converted into a true Intensity Score.
- **Metabolic Stress Modeling:** Analyzes workout density in real-time. By modeling metabolic stress against a 3-to-4-minute optimal recovery window, intensity is rewarded down to the second.

### An Overwhelmingly Seamless Experience
- **Fluid UI & Haptics:** A perfectly native interface resembling Apple Reminders. Complete sets with a subtle haptic pulse and an intelligent auto-rest timer.
- **Daily Lock & Streak System:** Mark your workout as finished to securely lock your data for the day, igniting your weekly streak to keep your momentum alive.
- **Global Database:** Access over 640 meticulously cataloged exercises natively localized in English, Korean, and Japanese.
- **Data & Charts:** Visualize your progressive overload with stunning Swift Charts and export your journey to Excel (CSV).

**Architecture:** SwiftUI, SwiftData, iOS 17.0+

---

## 日本語
<div id="japanese"></div>

### あなたにとって最も完璧なフィットネスパートナー。
GymDocsは、完璧主義者のために設計されたミニマルなネイティブiOSアプリです。驚くほど直感的で美しいデザインの裏には、最新のスポーツ科学に基づいた超精密なバイオメカニクス・ボリューム計算エンジンが隠されています。

### 驚異的な精度
- **生体力学的ボリューム追跡:** 前腕の重量やマシンの滑車の摩擦係数まで計算し、実際の筋肉にかかる純粋な負荷（Effective Load）を正確に追跡します。
- **可動域（ROM）分析:** エキセントリックからフルレンジまで、あなたの細かなコントロールの一つ一つが強度スコア（Intensity Score）に緻密に変換されます。
- **代謝ストレスのモデリング:** 休憩時間に応じた筋肉の乳酸耐性と代謝ストレスをリアルタイムで計算。最適な回復時間を基準に、秒単位でトレーニング密度を分析し、評価します。

### 圧倒的にシームレスな体験
- **流麗なUIとハプティクス:** Apple純正アプリのような軽快でスムーズな操作感。セットを終えるたびに繊細なハプティクスが伝わり、スマートな休憩タイマーが即座に起動します。
- **デイリーロックとストリーク:** その日のトレーニングを栄光と共に締めくくりましょう。完了した記録は安全にロックされ、本物の努力だけを認めるウィークリーストリークが燃え上がります。
- **グローバルデータベース:** 英語、韓国語、日本語に完全対応した640種類以上のエクササイズデータを標準搭載。
- **データ分析とエクスポート:** 美しいSwift Chartsで成長を可視化し、いつでもExcel（CSV）形式でデータをエクスポートして管理できます。

**アーキテクチャ:** SwiftUI, SwiftData, iOS 17.0+