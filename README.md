# GymDocs

[English](#english) | [한국어](#한국어) | [日本語](#日本語)

---

## English

GymDocs is a minimal, native iOS application designed for quick and raw workout data logging. It focuses on entering workout records as seamlessly as using a spreadsheet, eliminating unnecessary steps like starting or stopping a workout session.

### Key Features
- **Quick Logging:** Vertical list-based data entry without explicit start/stop session buttons.
- **Weekly Streak:** Home screen banner tracking consecutive weeks of workouts.
- **Rest Timer:** Simple built-in rest timer for each set.
- **Progressive Overload Charts:** Visualizes progress using Swift Charts.
- **Custom Exercises:** Users can define their own exercises (Weight & Reps or Time based).
- **On-device Storage:** Completely offline, using SwiftData for local persistence.
- **Data Portability:** Export and import capabilities via JSON.
- **Localization:** Supports English, Korean, and Japanese using String Catalogs.

### Architecture
- **UI Framework:** SwiftUI (Native dynamic system colors for perfect light/dark mode support)
- **Local Database:** SwiftData
- **Minimum Target:** iOS 17.0+
- **Charts:** Swift Charts

**Data Models:**
- `Exercise`: Represents an exercise type.
- `WorkoutRecord`: A collection of sets for an exercise on a specific date.
- `SetRecord`: An individual set tracking weight, reps, duration, and rest time.

**Project Structure:**
- `GymDocsApp.swift`: App entry point and ModelContainer.
- `/Models`: SwiftData schemas and Codable DTOs for backup.
- `/Views`: SwiftUI views organized by feature.
- `/Resources`: Localizable.xcstrings for multi-language support.

---

## 한국어

GymDocs는 직관적이고 빠른 운동 데이터 기록을 위해 디자인된 미니멀한 네이티브 iOS 애플리케이션입니다. 번거로운 운동 시작/종료 버튼 없이 엑셀처럼 날것의 데이터를 즉각적으로 입력하는 데 초점을 맞추었습니다.

### 핵심 기능
- **빠른 기록:** 세션 시작/종료 없이 수직 리스트 형태로 즉시 데이터 입력.
- **주간 스트릭:** 홈 화면에서 연속 주간 운동 달성 여부를 배너로 표시.
- **휴식 타이머:** 각 세트별로 간편하게 측정 가능한 내장 휴식 타이머.
- **점진적 과부하 그래프:** Swift Charts를 활용한 직관적인 성장 그래프 시각화.
- **커스텀 운동 종목:** 사용자가 직접 운동(무게+횟수 또는 시간 기반)을 추가 및 관리.
- **온디바이스 저장:** 서버 연동 없이 SwiftData를 사용한 100% 로컬 데이터 관리.
- **데이터 백업:** JSON 파일을 통한 데이터 내보내기 및 가져오기 지원.
- **다국어 지원:** String Catalogs를 활용하여 영어, 한국어, 일본어 완벽 지원.

### 아키텍처
- **UI 프레임워크:** SwiftUI (시스템 동적 색상을 사용해 다크모드 완벽 대응)
- **로컬 데이터베이스:** SwiftData
- **최소 지원 기기:** iOS 17.0+
- **차트:** Swift Charts

**데이터 모델:**
- `Exercise`: 운동 종목 모델.
- `WorkoutRecord`: 특정 날짜에 수행한 운동 세트의 모음.
- `SetRecord`: 무게, 횟수, 시간, 휴식 시간을 기록하는 개별 세트.

**프로젝트 구조:**
- `GymDocsApp.swift`: 앱 진입점 및 ModelContainer 설정.
- `/Models`: SwiftData 스키마 및 JSON 백업용 Codable DTO.
- `/Views`: 기능별로 정리된 SwiftUI 뷰.
- `/Resources`: 다국어 지원을 위한 Localizable.xcstrings 파일.

---

## 日本語

GymDocsは、素早く直感的にトレーニングデータを記録するために設計されたミニマルなネイティブiOSアプリケーションです。不要なトレーニング開始・終了ボタンを排除し、スプレッドシートのように即座にデータを入力することに焦点を当てています。

### 主な機能
- **クイック記録:** セッションの開始/終了なしで、垂直リストから直接データを入力。
- **週間ストリーク:** ホーム画面に連続してトレーニングを行った週数をバナーで表示。
- **休憩タイマー:** 各セットごとに簡単に測定できる内蔵の休憩タイマー。
- **漸進的過負荷グラフ:** Swift Chartsを使用した直感的な成長グラフの視覚化。
- **カスタム種目:** ユーザー自身で種目（重量+回数、または時間ベース）を追加・管理可能。
- **オンデバイス保存:** サーバー不要、SwiftDataを使用した完全なローカルデータ管理。
- **データバックアップ:** JSONファイルを通じたデータのエクスポートとインポートをサポート。
- **多言語対応:** String Catalogsを活用し、英語、韓国語、日本語を完全にサポート。

### アーキテクチャ
- **UIフレームワーク:** SwiftUI (システムダイナミックカラーを使用し、ダークモードに完全対応)
- **ローカルデータベース:** SwiftData
- **最小サポート要件:** iOS 17.0+
- **チャート:** Swift Charts

**データモデル:**
- `Exercise`: トレーニング種目のモデル。
- `WorkoutRecord`: 特定の日に実行したトレーニングセットのまとまり。
- `SetRecord`: 重量、回数、時間、休憩時間を記録する個別のセット。

**プロジェクト構造:**
- `GymDocsApp.swift`: アプリのエントリーポイントとModelContainerの設定。
- `/Models`: SwiftDataスキーマとJSONバックアップ用のCodable DTO。
- `/Views`: 機能ごとに整理されたSwiftUIビュー。
- `/Resources`: 多言語対応のためのLocalizable.xcstringsファイル。