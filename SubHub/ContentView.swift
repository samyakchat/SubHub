//
//  ContentView.swift
//  SubHub
//
//  Created by Samyak Chatterjee on 5/29/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) public var modelContext
    @Query(filter: #Predicate<Item> { _ in true }) var items: [Item]
    @State private var searchText = ""
    @State public var newItemName = ""
    @State public var newItemDate = Date()
    @State private var showingAddSheet = false
    @State public var billingCycleDays = 30

    var filteredItems: [Item] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return items
        } else {
            return items.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }


    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Permission error: \(error.localizedDescription)")
            } else {
                print("Permission granted: \(granted)")
            }
        }
    }


    var body: some View {
        
        //CREATE LIST
        NavigationSplitView {
            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()
                List {
                    let now = Date()
                    let in15Days = Calendar.current.date(byAdding: .day, value: 15, to: now)!

                    let pastDue = filteredItems.filter { $0.timestamp < Calendar.current.startOfDay(for: now) }
                    let dueToday = filteredItems.filter { Calendar.current.isDateInToday($0.timestamp) }
                    let dueSoon = filteredItems
                        .filter { $0.timestamp > now && $0.timestamp <= in15Days && !Calendar.current.isDateInToday($0.timestamp) }
                        .sorted { $0.timestamp < $1.timestamp }
                    let remaining = filteredItems
                        .filter { $0.timestamp > in15Days }
                        .sorted { $0.name.lowercased() < $1.name.lowercased() }
                    if !pastDue.isEmpty {
                        Section(header: Text("Past Due").font(.subheadline).foregroundStyle(Color.red)) {
                            ForEach(pastDue) { item in
                                NavigationLink {
                                    SubscriptionView(item: item)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                          
                                        Text(item.timestamp, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Billing every \(item.billingCycleDays) days")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .onDelete { offsets in
                                let toDelete = offsets.map { pastDue[$0] }
                                deleteSpecificfilteredItems(toDelete)
                            }
                        }
                    }


                    if !dueToday.isEmpty {
                        Section(header: Text("Due Today").font(.subheadline).foregroundStyle(Color.red)) {
                            ForEach(dueToday) { item in
                                NavigationLink {
                                    SubscriptionView(item: item)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                            
                                        Text(item.timestamp, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Billing every \(item.billingCycleDays) days") // ← Add this
                                                                .font(.caption)
                                                                .foregroundColor(.gray)
                                    }
                                }
                            }
                            .onDelete { offsets in
                                let toDelete = offsets.map { dueToday[$0] }
                                deleteSpecificfilteredItems(toDelete)
                            }
                        }
                    }
                    if !dueSoon.isEmpty {
                        Section(header: Text("Due in 15 or Less Days").font(.subheadline).foregroundStyle(Color.orange)) {
                            ForEach(dueSoon) { item in
                                NavigationLink {
                                    SubscriptionView(item: item)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                        Text(item.timestamp, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Billing every \(item.billingCycleDays) days") // ← Add this
                                                                .font(.caption)
                                                                .foregroundColor(.gray)
                                    }
                                }
                            }
                            .onDelete { offsets in
                                let toDelete = offsets.map { dueSoon[$0] }
                                deleteSpecificfilteredItems(toDelete)
                            }
                        }
                    }
                    
                    ForEach(
                        Dictionary(grouping: remaining, by: { String($0.name.prefix(1).uppercased()) })
                            .sorted(by: { $0.key < $1.key }),
                        id: \.key
                    ) { letter, groupedfilteredItems in
                        Section(header: Text(letter)) {
                            ForEach(groupedfilteredItems) { item in
                                NavigationLink {
                                    SubscriptionView(item: item)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                            
                                        Text(item.timestamp, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Billing every \(item.billingCycleDays) days")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)

                                    }
                                }
                            }
                            .onDelete { offsets in
                                let toDelete = offsets.map { groupedfilteredItems[$0] }
                                deleteSpecificfilteredItems(toDelete)
                            }
                        }
                    }
                }
               
                .navigationTitle("My Subscriptions")
                .searchable(text: $searchText, prompt: "Search subscriptions")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: {
                            showingAddSheet = true
                        }) {
                            Label("Add Item", systemImage: "plus.app")
                        }
                    }
                }

                VStack {
                    Spacer()
                    Text("\(filteredItems.count) entr\(filteredItems.count == 1 ? "y" : "ies")")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
        } detail: {
            Text("Select an item")
        }
        
        .sheet(isPresented: $showingAddSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Item Name")) {
                        TextField("Enter a name", text: $newItemName)
                    }

                    Section(header: Text("Next Billing Date")) {
                        DatePicker("Select a date", selection: $newItemDate, displayedComponents: .date)
                    }
                    Section(header: Text("Billing Cycle (Days)")) {
                        Picker("Billing Cycle (Days)", selection: $billingCycleDays) {
                            ForEach(1...365, id: \.self) { day in
                                Text("\(day) day\(day == 1 ? "" : "s")").tag(day)
                            }
                        }
                        .pickerStyle(.wheel) //swift managed
                        .frame(height: 100)
                    }

                }
                .navigationTitle("New Subscription")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            newItemName = ""
                            newItemDate = Date()
                            billingCycleDays = 30
                            showingAddSheet = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addItem(named: newItemName, date: newItemDate)
                            newItemName = ""
                            newItemDate = Date()
                            billingCycleDays = 30
                            showingAddSheet = false
                        }
                        .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                }
            }
            .preferredColorScheme(.dark)
        }
        // AUTHORIZE NOTIFS
        .onAppear {
            
            
            requestNotificationPermission()
                
            }

    }
    
    private func scheduleNotification(for item: Item) {
        // Set up notification contents
        let content1 = UNMutableNotificationContent()
        content1.title = "Upcoming Subscription"
        content1.body = "\(item.name) is due tomorrow."
        content1.sound = .default

        let content2 = UNMutableNotificationContent()
        content2.title = "Subscription Due Today"
        content2.body = "\(item.name) is due today."
        content2.sound = .default

        let calendar = Calendar.current

        let triggerDate1 = calendar.date(byAdding: .day, value: -1, to: item.timestamp)!
        let triggerDate2 = item.timestamp

        var triggerComponents1 = calendar.dateComponents([.year, .month, .day], from: triggerDate1)
        triggerComponents1.hour = 7
        triggerComponents1.minute = 0

        var triggerComponents2 = calendar.dateComponents([.year, .month, .day], from: triggerDate2)
        triggerComponents2.hour = 7
        triggerComponents2.minute = 0

        let trigger1 = UNCalendarNotificationTrigger(dateMatching: triggerComponents1, repeats: false)
        let trigger2 = UNCalendarNotificationTrigger(dateMatching: triggerComponents2, repeats: false)

        // Generate unique identifiers for tracking
        let id1 = UUID().uuidString
        let id2 = UUID().uuidString

        let request1 = UNNotificationRequest(identifier: id1, content: content1, trigger: trigger1)
        let request2 = UNNotificationRequest(identifier: id2, content: content2, trigger: trigger2)

        //notifs
        UNUserNotificationCenter.current().add(request1)
        UNUserNotificationCenter.current().add(request2)

        item.notificationIDs = [id1, id2]
    }



    
    private func addItem(named name: String, date: Date) {
        withAnimation {
            let newItem = Item(name: name, timestamp: date, billingCycleDays: billingCycleDays)

            modelContext.insert(newItem)
            scheduleNotification(for: newItem)
        }
    }

    private func deletefilteredItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredItems[index])
            }
        }
    }

    private func deleteSpecificfilteredItems(_ filteredItemsToDelete: [Item]) {
        withAnimation {
            for item in filteredItemsToDelete {
                
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: item.notificationIDs)
                
               
                modelContext.delete(item)
            }
        }
    }

}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
