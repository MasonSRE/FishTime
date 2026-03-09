import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel

    var body: some View {
        List(viewModel.records, id: \.date) { record in
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(record.presentationTitle)
                        .font(.headline)
                    Spacer()
                    Text(record.scoreText)
                        .font(.subheadline.weight(.semibold))
                }

                Text(record.verdict)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(record.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("复制这天战报") {
                        viewModel.copyReport(for: record)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.vertical, 6)
        }
        .onAppear {
            viewModel.reload()
        }
        .frame(minWidth: 320, minHeight: 420)
    }
}
