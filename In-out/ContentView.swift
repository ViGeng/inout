import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie")
                }

            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
