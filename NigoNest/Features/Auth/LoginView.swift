import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var studentId = ""
    @State private var password = ""
    @State private var busy = false
    @State private var error = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Spacer()
                    StreetCat()
                }
                InkTitle(text: "泥工小窝", size: 40)
                Text("用学校账号登录")
                    .font(InkFont.body())
                    .foregroundStyle(Palette.ink)
                field("学号", text: $studentId)
                field("密码", text: $password, secure: true)
                if !error.isEmpty {
                    Text(error)
                        .font(InkFont.body(14))
                        .foregroundStyle(Palette.ink)
                }
                InkButton(title: busy ? "登录中" : "登录") {
                    Task { await submit() }
                }
                .disabled(busy)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.paper)
    }

    private func field(_ title: String, text: Binding<String>, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(InkFont.body(14))
            Group {
                if secure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(InkFont.body())
            .padding(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink, lineWidth: 3))
        }
    }

    private func submit() async {
        error = ""
        busy = true
        defer { busy = false }
        do {
            try await session.login(username: studentId.trimmingCharacters(in: .whitespaces), password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
