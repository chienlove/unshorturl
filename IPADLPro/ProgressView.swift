import SwiftUI

struct ProgressCardView: View {
    let progress: Double
    let message: String
    let detail: String
    let steps: [ProgressStep]

    var body: some View {
        VStack(spacing: 20) {
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color("FieldBG"), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress / 100)
                    .stroke(
                        LinearGradient(colors: [Color("Accent"), Color("AccentSecondary")], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                VStack(spacing: 2) {
                    Text("\(Int(progress))%")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                }
            }

            // Status text
            VStack(spacing: 6) {
                Text(message)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            // Steps log
            if !steps.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Nhật ký")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    ForEach(steps.suffix(5)) { step in
                        StepRow(step: step)
                    }
                }
                .padding(14)
                .background(Color("FieldBG"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct StepRow: View {
    let step: ProgressStep

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color("Accent"))
                .frame(width: 6, height: 6)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.message)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
                if !step.detail.isEmpty {
                    Text(step.detail)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(formatTime(step.timestamp))
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }
}
