//
//  SettingsView.swift
//  DontGoMart
//
//  Created by hyunho lee on 7/8/23.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Binding var isShowingSettings: Bool
    @AppStorage(AppStorageKeys.selectedBranch, store: UserDefaults(suiteName: Utillity.appGroupId)) var selectedBranch: Int = 0
    @AppStorage(AppStorageKeys.isCostco, store: UserDefaults(suiteName: Utillity.appGroupId)) var isCostco: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("대형마트")) {
                    Toggle(isOn: $isCostco, label: {
                        Text("코스트코")
                    })
                    .onChange(of: isCostco) {
                        selectedBranch = isCostco ? 1 : 0
                        WidgetManager.shared.updateWidget()
                    }
                    if isCostco {
                        CostcoSettings()
                    }
                }
            }
            .navigationTitle("매장선택")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        WidgetManager.shared.updateWidget()
                        isShowingSettings = false
                    }) {
                        Text("완료")
                    }
                }
            }
        }
    }
}


struct CostcoSettings: View {
    @AppStorage(AppStorageKeys.selectedBranch, store: UserDefaults(suiteName: Utillity.appGroupId)) var selectedBranch: Int = 0
    @State var selectedCostcoBranch: CostcoBranch = .normal
    
    @State private var isNormalSelected = false
    @State private var isDaeguSelected = false
    @State private var isIlsanSelected = false
    @State private var isUlsanSelected = false
    
    var body: some View {
        VStack {
            HStack {
                Text("매장을 선택해주세요")
                    .padding()
                Spacer()
            }
            VStack(spacing: 10) {
                Toggle("일반 지점", isOn: Binding(
                    get: { isNormalSelected },
                    set: { newValue in updateSelection(for: .normal, isSelected: newValue) }
                ))
                
                Toggle("대구 지점", isOn: Binding(
                    get: { isDaeguSelected },
                    set: { newValue in updateSelection(for: .daegu, isSelected: newValue) }
                ))
                
                Toggle("일산 지점", isOn: Binding(
                    get: { isIlsanSelected },
                    set: { newValue in updateSelection(for: .ilsan, isSelected: newValue) }
                ))
                
                Toggle("울산 지점", isOn: Binding(
                    get: { isUlsanSelected },
                    set: { newValue in updateSelection(for: .ulsan, isSelected: newValue) }
                ))
            }
            .padding()
            
            Spacer()
        }
        .onAppear {
            syncSelectionState()
        }
    }
    
    private func updateSelection(for branch: CostcoBranch, isSelected: Bool) {
        if isSelected {
            // 다른 선택지를 초기화하고 현재 선택지를 저장
            resetAllSelections()
            selectedCostcoBranch = branch
            selectedBranch = branch.branchID
            
            switch branch {
            case .normal:
                isNormalSelected = true
            case .daegu:
                isDaeguSelected = true
            case .ilsan:
                isIlsanSelected = true
            case .ulsan:
                isUlsanSelected = true
            }
        }
    }
    
    private func resetAllSelections() {
        isNormalSelected = false
        isDaeguSelected = false
        isIlsanSelected = false
        isUlsanSelected = false
    }
    
    private func syncSelectionState() {
        switch selectedBranch {
        case 1:
            updateSelection(for: .normal, isSelected: true)
        case 2:
            updateSelection(for: .daegu, isSelected: true)
        case 3:
            updateSelection(for: .ilsan, isSelected: true)
        case 4:
            updateSelection(for: .ulsan, isSelected: true)
        default:
            resetAllSelections()
        }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isShowingSettings: .constant(true))
    }
}

