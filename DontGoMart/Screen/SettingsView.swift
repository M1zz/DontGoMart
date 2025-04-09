//
//  SettingsView.swift
//  DontGoMart
//
//  Created by hyunho lee on 7/8/23.
//

import SwiftUI
import WidgetKit
import TipKit

struct StoreTip: Tip {
    var title: Text { Text("해당 지점") }
    var message: Text? {
        Text("양평점, 대전점, 양재점, \n상봉점, 부산점, 광명점, \n천안점, 의정부점, 공세점, \n송도점, 세종점, 하남점, \n김해점, 고척점")
    }
    var options: [Option] {
        MaxDisplayCount(10)
    }
}


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
    @State private var isTipShowing = false
    var storeTip = StoreTip()
    
    
    var body: some View {
        VStack {
            HStack {
                Text("매장을 선택해주세요")
                    .padding()
                Spacer()
            }
            VStack(spacing: 10) {
                Toggle(isOn: Binding(
                    get: { isNormalSelected },
                    set: { _ in updateSelection(for: .normal) }
                )) {
                    HStack {
                        Text("일반매장")
                        
                        if isTipShowing {
                            Image(systemName: "questionmark.circle")
                                .popoverTip(storeTip)
                                .onTapGesture {
                                    isTipShowing.toggle()
                                }
                        } else {
                            Image(systemName: "questionmark.circle")
                                .onTapGesture {
                                    isTipShowing.toggle()
                                }
                        }
                    }
                }
                
                
                Toggle("대구 지점", isOn: Binding(
                    get: { isDaeguSelected },
                    set: { _ in updateSelection(for: .daegu) }
                ))
                
                Toggle("일산 지점", isOn: Binding(
                    get: { isIlsanSelected },
                    set: { _ in updateSelection(for: .ilsan) }
                ))
                
                Toggle("울산 지점", isOn: Binding(
                    get: { isUlsanSelected },
                    set: { _ in updateSelection(for: .ulsan) }
                ))
            }
            .padding()
            
            Spacer()
        }
        .onAppear {
            syncSelectionState()
        }
        .task {
            try? Tips.resetDatastore()
            try? Tips.configure([.displayFrequency(.immediate)])
        }
    }
    
    private func updateSelection(for branch: CostcoBranch) {
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
    
    private func resetAllSelections() {
        isNormalSelected = false
        isDaeguSelected = false
        isIlsanSelected = false
        isUlsanSelected = false
    }
    
    private func syncSelectionState() {
        switch selectedBranch {
        case 1:
            updateSelection(for: .normal)
        case 2:
            updateSelection(for: .daegu)
        case 3:
            updateSelection(for: .ilsan)
        case 4:
            updateSelection(for: .ulsan)
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

