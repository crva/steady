import SwiftUI
import WidgetKit

@main
struct SteadyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        SingleHabitWidget()
        HabitListWidget()
    }
}
