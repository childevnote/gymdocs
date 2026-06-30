import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userHeight") private var userHeight: Double = 170.0
    @AppStorage("userWeight") private var userWeight: Double = 70.0
    @State private var showingSkipAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(String(localized: "onboarding.welcomeMessage", defaultValue: "정확한 맨몸운동 및 어시스트 볼륨 계산을 위해 신체 정보를 입력해주세요."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section(header: Text(String(localized: "onboarding.bodyInfo", defaultValue: "신체 정보"))) {
                    HStack {
                        Text(String(localized: "onboarding.height", defaultValue: "키 (cm)"))
                        Spacer()
                        TextField("170.0", value: $userHeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text(String(localized: "onboarding.weight", defaultValue: "몸무게 (kg)"))
                        Spacer()
                        TextField("70.0", value: $userWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle(String(localized: "onboarding.title", defaultValue: "환영합니다!"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.skip", defaultValue: "건너뛰기")) {
                        showingSkipAlert = true
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.start", defaultValue: "시작하기")) {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .alert(String(localized: "onboarding.skipAlertTitle", defaultValue: "입력 생략 시 안내"), isPresented: $showingSkipAlert) {
                Button(String(localized: "common.cancel", defaultValue: "취소"), role: .cancel) { }
                Button(String(localized: "common.skip", defaultValue: "건너뛰기"), role: .destructive) {
                    hasCompletedOnboarding = true
                }
            } message: {
                Text(String(localized: "onboarding.skipAlertMessage", defaultValue: "키와 몸무게를 입력하지 않으시면, 맨몸운동 및 어시스트 운동의 정확한 볼륨 계산이 어렵습니다. 그래도 건너뛰시겠습니까?"))
            }
        }
    }
}
