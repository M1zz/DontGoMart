//
//  SettingsView.swift
//  DontGoMart
//
//  Created by hyunho lee on 7/8/23.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isNormal", store: UserDefaults(suiteName: "group.com.leeo.DontGoMart")) var isCostco: Bool = false
    @Binding var isShowingSettings: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General")) {
                    Toggle(isOn: $isCostco, label: {
                        Text("코스트코")
                    })
                    NavigationLink {
                        CostcoSettings()
                    } label: {
                        Text("코스트코 지점")
                    }.disabled(!isCostco)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingSettings = false
                    }) {
                        Text("Done")
                    }
                }
            }
        }
    }
}


struct CostcoSettings: View {
    @AppStorage("selectedLocation", store: UserDefaults(suiteName: "group.com.leeo.DontGoMart")) var selectedLocation: Int = 0
    @State var selectedLocal: CostcoMartType = .normal
    var body: some View {
        
        VStack {
            HStack {
                Text("매장을 선택해주세요")
                    .padding()
                Spacer()
            }
            HStack {
                Picker("선택된 매장", selection: $selectedLocal) {
                    ForEach(CostcoMartType.allCases, id: \.self) { type in
                        
                        Text(type.storeName)
                            .lineLimit(3)
                    }
                }
                Spacer()
            }
            .onChange(of: selectedLocal, { oldValue, newValue in
                selectedLocation = selectedLocal.storeID
            })
            .frame(alignment: .leading)
            //.pickerStyle()
            Spacer()
        }
        .navigationTitle("Select costco")
        .onAppear(perform: {
            if selectedLocation == 0 {
                selectedLocal = .normal
            } else if selectedLocation == 1 {
                selectedLocal = .daegu
            } else if selectedLocation == 2 {
                selectedLocal = .ilsan
            } else if selectedLocation == 3 {
                selectedLocal = .ulsan
            }
        })
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isShowingSettings: .constant(true))
    }
}

