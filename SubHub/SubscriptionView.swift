//
//  SubscriptionView.swift
//  SubHub
//
//  Created by Samyak Chatterjee on 5/30/25.
//

import SwiftUI
import SwiftData
struct SubscriptionView: View {

    let item: Item

    var imageName: String {
        let lowercasedName = item.name.lowercased()

        if lowercasedName.contains("netflix") || lowercasedName.contains("hulu") ||
           lowercasedName.contains("prime") || lowercasedName.contains("disney") ||
           lowercasedName.contains("max") || lowercasedName.contains("peacock") {
            return "tv.inset.filled"
        } else if lowercasedName.contains("spotify") || lowercasedName.contains("apple music") {
            return "music.note"
        } else if lowercasedName.contains("youtube") {
            return "play.rectangle.fill"
        } else if lowercasedName.contains("icloud") || lowercasedName.contains("apple one") {
            return "icloud.fill"
        } else {
            return "apple.image.playground"
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text(item.name)
                    .font(.largeTitle)
                    .foregroundColor(.primary).fontWeight(.bold)
                    .padding()
                
                Image(systemName: imageName)
                    
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.accentColor)
                    .padding(3)
                Spacer()
                
                

                    
                
            }
            
            Spacer()
            Button(action: {
                markAsPaid()
                
                let generator = UIImpactFeedbackGenerator(style: .light)
                for _ in 1...3 {
                        generator.impactOccurred()
                
                    }
                    
            }) {
                Label("Mark Paid", systemImage: "checkmark.circle")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
                    .frame(width: 150, height: 40, alignment: .center)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(50)
                    
            }
            
        }
       
        
    }
    func markAsPaid() {
        let calendar = Calendar.current
        let nextBillingDate = calendar.date(byAdding: .day, value: item.billingCycleDays, to: item.timestamp)!

        item.timestamp = nextBillingDate

        // Cancel old notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: item.notificationIDs)

        // Reschedule notifications for the new date
        let content1 = UNMutableNotificationContent()
        content1.title = "Upcoming Subscription"
        content1.body = "\(item.name) is due tomorrow."
        content1.sound = .default

        let content2 = UNMutableNotificationContent()
        content2.title = "Subscription Due Today"
        content2.body = "\(item.name) is due today."
        content2.sound = .default

        let triggerDate1 = calendar.date(byAdding: .day, value: -1, to: nextBillingDate)!
        let triggerDate2 = nextBillingDate

        var triggerComponents1 = calendar.dateComponents([.year, .month, .day], from: triggerDate1)
        triggerComponents1.hour = 7
        triggerComponents1.minute = 0

        var triggerComponents2 = calendar.dateComponents([.year, .month, .day], from: triggerDate2)
        triggerComponents2.hour = 7
        triggerComponents2.minute = 0

        let trigger1 = UNCalendarNotificationTrigger(dateMatching: triggerComponents1, repeats: false)
        let trigger2 = UNCalendarNotificationTrigger(dateMatching: triggerComponents2, repeats: false)

        let id1 = UUID().uuidString
        let id2 = UUID().uuidString

        let request1 = UNNotificationRequest(identifier: id1, content: content1, trigger: trigger1)
        let request2 = UNNotificationRequest(identifier: id2, content: content2, trigger: trigger2)

        UNUserNotificationCenter.current().add(request1)
        UNUserNotificationCenter.current().add(request2)

        item.notificationIDs = [id1, id2]
    }

}

#Preview {
    SubscriptionView(item: Item(name: "icloud", timestamp: Date()))
        .modelContainer(for: Item.self, inMemory: true)
}
