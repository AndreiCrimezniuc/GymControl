import ActivityKit
import SwiftUI
import WidgetKit

struct GymControlWorkoutAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var completedSets: Int
    var totalSets: Int
    var restEnd: Date?
  }

  var workoutName: String
  var startedAt: Date
}

@main
struct GymControlActivityBundle: WidgetBundle {
  var body: some Widget {
    GymControlWorkoutActivity()
  }
}

struct GymControlWorkoutActivity: Widget {
  private let signalRed = Color(red: 0.945, green: 0.357, blue: 0.341)

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: GymControlWorkoutAttributes.self) { context in
      HStack(spacing: 12) {
        mark
        VStack(alignment: .leading, spacing: 3) {
          Text(context.attributes.workoutName)
            .font(.headline)
            .lineLimit(1)
          status(context)
        }
        Spacer()
        Text("\(context.state.completedSets)/\(context.state.totalSets)")
          .font(.headline.monospacedDigit())
          .foregroundStyle(signalRed)
      }
      .padding(16)
      .activityBackgroundTint(Color(red: 0.04, green: 0.04, blue: 0.045))
      .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) { mark }
        DynamicIslandExpandedRegion(.center) {
          VStack(spacing: 2) {
            Text(context.attributes.workoutName).font(.subheadline.bold()).lineLimit(1)
            status(context)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(context.state.completedSets)/\(context.state.totalSets)")
            .font(.headline.monospacedDigit())
            .foregroundStyle(signalRed)
        }
      } compactLeading: {
        Image(systemName: "figure.strengthtraining.traditional").foregroundStyle(signalRed)
      } compactTrailing: {
        timer(context).font(.caption2.monospacedDigit()).frame(width: 44)
      } minimal: {
        Image(systemName: "timer").foregroundStyle(signalRed)
      }
      .keylineTint(signalRed)
    }
  }

  private var mark: some View {
    Image(systemName: "figure.strengthtraining.traditional")
      .font(.title3.weight(.semibold))
      .foregroundStyle(signalRed)
  }

  @ViewBuilder
  private func status(_ context: ActivityViewContext<GymControlWorkoutAttributes>) -> some View {
    if let restEnd = context.state.restEnd, restEnd > Date() {
      HStack(spacing: 4) {
        Text("Rest")
        Text(timerInterval: Date()...restEnd, countsDown: true)
          .monospacedDigit()
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    } else {
      HStack(spacing: 4) {
        Text("Training")
        Text(timerInterval: context.attributes.startedAt...Date.distantFuture, countsDown: false)
          .monospacedDigit()
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private func timer(_ context: ActivityViewContext<GymControlWorkoutAttributes>) -> some View {
    if let restEnd = context.state.restEnd, restEnd > Date() {
      Text(timerInterval: Date()...restEnd, countsDown: true)
    } else {
      Text(timerInterval: context.attributes.startedAt...Date.distantFuture, countsDown: false)
    }
  }
}
