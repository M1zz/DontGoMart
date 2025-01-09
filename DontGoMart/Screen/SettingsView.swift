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
    @AppStorage("selectedBranch", store: UserDefaults(suiteName: appGroupId)) var selectedBranch: Int = 0
    @AppStorage("isNormal", store: UserDefaults(suiteName: appGroupId)) var isCostco: Bool = false
    
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
                    NavigationLink {
                        CostcoSettings()
                    } label: {
                        Text("코스트코 지점")
                    }.disabled(!isCostco)
                }
            }
            .navigationTitle("매장선택")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
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
    @AppStorage("selectedBranch", store: UserDefaults(suiteName: appGroupId)) var selectedBranch: Int = 0
    @State var selectedCostcoBranch: CostcoBranch = .normal
    
    var body: some View {
        
        VStack {
            HStack {
                Text("매장을 선택해주세요")
                    .padding()
                Spacer()
            }
            HStack {
                Picker("선택된 매장", selection: $selectedCostcoBranch) {
                    ForEach(CostcoBranch.allCases, id: \.self) { type in
                        Text(type.storeName)
                            .lineLimit(3)
                    }
                }
                Spacer()
            }
            .onChange(of: selectedCostcoBranch, { oldValue, newValue in
                selectedBranch = selectedCostcoBranch.branchID

            })
            .frame(alignment: .leading)

            Spacer()
        }
        .navigationTitle("코스트코 지점 선택하기")
        .onAppear(perform: {
            if selectedBranch == 1 {
                selectedCostcoBranch = .normal
            } else if selectedBranch == 2 {
                selectedCostcoBranch = .daegu
            } else if selectedBranch == 3 {
                selectedCostcoBranch = .ilsan
            } else if selectedBranch == 4 {
                selectedCostcoBranch = .ulsan
            }
        })
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isShowingSettings: .constant(true))
    }
}

