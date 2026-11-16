import SwiftUI

// MARK: - Model

struct Expense: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var note: String
    var category: String
    var date: Date = Date()
}

let categories = ["Ăn uống", "Đi lại", "Mua sắm", "Hóa đơn", "Khác"]

func formatVND(_ value: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.groupingSeparator = "."
    f.maximumFractionDigits = 0
    return (f.string(from: NSNumber(value: value)) ?? "0") + " ₫"
}

// MARK: - Store (lưu offline bằng UserDefaults)

final class ExpenseStore: ObservableObject {
    @Published var items: [Expense] = [] {
        didSet { save() }
    }
    private let key = "expenses_v1"

    init() { load() }

    var monthTotal: Double {
        let cal = Calendar.current
        return items
            .filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    func add(_ e: Expense) {
        items.insert(e, at: 0)
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Expense].self, from: data)
        else { return }
        items = decoded
    }
}

// MARK: - Màn hình chính

struct ContentView: View {
    @StateObject private var store = ExpenseStore()
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Chi tiêu tháng này")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(formatVND(store.monthTotal))
                            .font(.system(size: 32, weight: .bold))
                    }
                    .padding(.vertical, 8)
                }

                Section("Gần đây") {
                    if store.items.isEmpty {
                        Text("Chưa có khoản chi nào. Bấm + để thêm.")
                            .foregroundColor(.secondary)
                    }
                    ForEach(store.items) { e in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.note.isEmpty ? e.category : e.note)
                                    .font(.body)
                                Text("\(e.category) • \(e.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(formatVND(e.amount))
                                .fontWeight(.semibold)
                        }
                    }
                    .onDelete(perform: store.delete)
                }
            }
            .navigationTitle("Sổ chi tiêu")
            .toolbar {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddExpenseView { store.add($0) }
            }
        }
    }
}

// MARK: - Thêm khoản chi

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var note = ""
    @State private var category = categories[0]

    var onSave: (Expense) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Số tiền (₫)", text: $amountText)
                    .keyboardType(.numberPad)
                TextField("Ghi chú (không bắt buộc)", text: $note)
                Picker("Danh mục", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0) }
                }
            }
            .navigationTitle("Thêm khoản chi")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        if let amount = Double(amountText), amount > 0 {
                            onSave(Expense(amount: amount, note: note, category: category))
                            dismiss()
                        }
                    }
                    .disabled(Double(amountText) == nil)
                }
            }
        }
    }
}
