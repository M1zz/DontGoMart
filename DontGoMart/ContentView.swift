//
//  ContentView.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/15.
//

import SwiftUI

struct ContentView: View {
    @State var currentDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack(spacing: 20){
                    
                    // Custom Date Picker....
                    CustomDatePicker(currentDate: $currentDate)
                }
                .padding(.vertical)
            }
            .navigationTitle("Don't go mart day")
        }
        
        // Safe Area View...
//        .safeAreaInset(edge: .bottom) {
//
//            HStack{
//
//                Button {
//
//                } label: {
//                    Text("Add Task")
//                        .fontWeight(.bold)
//                        .padding(.vertical)
//                        .frame(maxWidth: .infinity)
//                        .background(Color("Orange"),in: Capsule())
//                }
//
//                Button {
//
//                } label: {
//                    Text("Add Remainder")
//                        .fontWeight(.bold)
//                        .padding(.vertical)
//                        .frame(maxWidth: .infinity)
//                        .background(Color("Purple"),in: Capsule())
//                }
//            }
//            .padding(.horizontal)
//            .padding(.top,10)
//            .foregroundColor(.white)
//            .background(.ultraThinMaterial)
//        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
