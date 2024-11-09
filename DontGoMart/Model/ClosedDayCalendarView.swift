//
//  CustomDatePicker.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/17.
//

import SwiftUI

struct ClosedDayCalendarView: View {
    @Binding var currentDate: Date
    @State var currentMonth: Int = 0
    @State var selectedMartType: MartType = .normal
    @AppStorage("isNormal", store: UserDefaults(suiteName: "group.com.leeo.DontGoMart"))
    var isCostco: Bool = true
    @AppStorage("selectedBranch", store: UserDefaults(suiteName: "group.com.leeo.DontGoMart"))
    var selectedBranch: Int = 0
    
    var body: some View {
        VStack(spacing: 35) {
            
            let days: [String] = ["일","월","화","수","목","금","토"]
            
            HStack(spacing: 20){
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(extraDate()[0])
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(extraDate()[1])
                        .font(.title.bold())
                }
                
                Spacer(minLength: 0)
                
                Button {
                    withAnimation{
                        currentMonth -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }

                Button {
                    
                    withAnimation {
                        currentMonth += 1
                    }
                    
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            // Day View...
            
            HStack(spacing: 0){
                ForEach(days,id: \.self){day in
                    
                    Text(day)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            
            LazyVGrid(columns: columns,spacing: 10) {
                
                ForEach(extractDate()) { value in
                    
                    CardView(value: value)
                        .background(
                        
                            Capsule()
                                .fill(Color("Pink"))
                                .padding(.horizontal,8)
                                .opacity(isSameDay(date1: value.date, date2: currentDate) ? 1 : 0)
                        )
                        .onTapGesture {
                            currentDate = value.date
                        }
                }
            }
            
            VStack(spacing: 15){
                
                Text("휴무일")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .padding(.vertical,20)
                
                let filteredTasks = tasks.filter { item in
                    return item.type == selectedMartType
                }
                
                if let task = filteredTasks.first(where: { task in
                    return isSameDay(date1: task.taskDate, date2: currentDate)
                }) {
                    
                    ForEach(task.task) { task in
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text(task.title)
                                .font(.title2.bold())
                        }
                        .padding(.vertical,10)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity,alignment: .leading)
                        .background(
                            Color("Purple")
                                .opacity(0.5)
                                .cornerRadius(10)
                        )
                    }
                }
                else{
                    Text("휴일이 아닙니다")
                }
            }
            .padding()
        }
        .onChange(of: currentMonth, {
            currentDate = getCurrentMonth()
        })
    }
    
    @ViewBuilder
    func CardView(value: DateValue) -> some View {
        
        VStack{
            if value.day != -1 {
                let filteredTasks = tasks.filter { item in
                    return item.type == selectedMartType
                }
                
                if let task = filteredTasks.first(where: { task in
                    return isSameDay(date1: task.taskDate,
                                     date2: value.date)
                }){
                    
                    Text("\(value.day)")
                        .font(.title3.bold())
                        .foregroundColor(isSameDay(date1: task.taskDate, date2: currentDate) ? .white : .primary)
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    Circle()
                        .fill(isSameDay(date1: task.taskDate, date2: currentDate) ? .white : Color("Pink"))
                        .frame(width: 8,height: 8)
                }
                else{
                    
                    Text("\(value.day)")
                        .font(.title3.bold())
                        .foregroundColor(isSameDay(date1: value.date, date2: currentDate) ? .white : .primary)
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            if isCostco {
                if selectedBranch == 0 {
                    selectedMartType = .costco(type: .normal)
                } else if selectedBranch == 1 {
                    selectedMartType = .costco(type: .daegu)
                } else if selectedBranch == 2 {
                    selectedMartType = .costco(type: .ilsan)
                } else if selectedBranch == 3 {
                    selectedMartType = .costco(type: .ulsan)
                }
            } else if !isCostco {
                selectedMartType = .normal
            }
        }
        .padding(.vertical,9)
        .frame(height: 60,alignment: .top)
    }
    
    func isSameDay(date1: Date,date2: Date)->Bool{
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    // extrating Year And Month for display...
    func extraDate()->[String]{
        
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        let month = calendar.component(.month, from: currentDate) - 1
        let year = calendar.component(.year, from: currentDate)
        
        return ["\(year)",calendar.monthSymbols[month]]
    }
    
    func getCurrentMonth()->Date{
        
        let calendar = Calendar.current
        
        // Getting Current Month Date....
        guard let currentMonth = calendar.date(byAdding: .month, value: self.currentMonth, to: Date()) else{
            return Date()
        }
                
        return currentMonth
    }
    
    func extractDate()->[DateValue] {
        
        let calendar = Calendar.current
        
        // Getting Current Month Date....
        let currentMonth = getCurrentMonth()
        
        var days = currentMonth.getAllDates().compactMap { date -> DateValue in

            let day = calendar.component(.day, from: date)
            return DateValue(day: day, date: date)
        }
        
        // adding offset days to get exact week day...
        let firstWeekday = calendar.component(.weekday, from: days.first!.date)
        
        for _ in 0..<firstWeekday - 1{
            days.insert(DateValue(day: -1, date: Date()), at: 0)
        }
        
        return days
    }
}

#Preview {
    ClosedDaysView()
}
