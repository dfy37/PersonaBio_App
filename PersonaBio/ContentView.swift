import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
}

enum MessageRole {
    case user
    case assistant
}

struct ContentView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: "你好，我是你的传记采访助手。我们会像 ChatGPT 一样通过对话收集素材，信息足够后再开始撰写。\n\n先从第一问开始：你和主人公是什么关系？")
    ]
    @State private var inputText = ""
    @State private var interviewStep = 0
    @State private var collectedAnswers: [String] = []
    @State private var writingStarted = false

    private let interviewQuestions: [String] = [
        "你和主人公是什么关系？",
        "你最想让读者记住主人公的哪三个特质？",
        "有哪些关键人生节点（年份或阶段）必须写进去？",
        "有没有一件最能代表 TA 的故事，请尽量具体描述。"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if canStartWriting {
                                writeTipCard
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemGroupedBackground))
                    .onChange(of: messages.count) {
                        if let lastID = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }

                composerBar
            }
            .navigationTitle("采访式传记助手")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(writingStarted ? "正在撰写中" : "采访进行中")
                .font(.headline)
            Text(writingStarted
                 ? "已收集核心素材，正在生成传记初稿。"
                 : "请按问题逐步回答，达到信息阈值后将自动进入撰写阶段。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
    }

    private var composerBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("输入你的回答…", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(canSend ? .blue : .gray)
            }
            .disabled(!canSend)

            if canStartWriting && !writingStarted {
                Button("开始撰写", action: startWriting)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var writeTipCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("素材已足够", systemImage: "checkmark.seal.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
            Text("你可以继续补充细节，或点击“开始撰写”生成第一版人物传记。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canStartWriting: Bool {
        collectedAnswers.count >= interviewQuestions.count
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(role: .user, content: trimmed))
        inputText = ""

        if !canStartWriting {
            collectedAnswers.append(trimmed)
            interviewStep += 1

            if interviewStep < interviewQuestions.count {
                messages.append(ChatMessage(role: .assistant, content: "收到。下一问：\(interviewQuestions[interviewStep])"))
            } else {
                messages.append(ChatMessage(role: .assistant, content: "很好，关键素材已经收集完成。你可以点击“开始撰写”，我会先生成一版结构化初稿。"))
            }
        } else {
            messages.append(ChatMessage(role: .assistant, content: "我已记录这条补充信息，会在撰写时一并融合。"))
        }
    }

    private func startWriting() {
        guard canStartWriting, !writingStarted else { return }
        writingStarted = true

        let draft = """
        【传记初稿（示例）】
        关系背景：\(collectedAnswers[safe: 0] ?? "未提供")
        核心特质：\(collectedAnswers[safe: 1] ?? "未提供")
        关键节点：\(collectedAnswers[safe: 2] ?? "未提供")
        代表故事：\(collectedAnswers[safe: 3] ?? "未提供")

        接下来我会基于这些信息扩展为完整章节，并保持真实、克制、可读的叙事风格。
        """

        messages.append(ChatMessage(role: .assistant, content: draft))
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
            }
        }
    }

    private var bubble: some View {
        Text(message.content)
            .font(.body)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .foregroundStyle(message.role == .assistant ? Color.primary : .white)
            .background(message.role == .assistant ? Color(.systemBackground) : .blue)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(message.role == .assistant ? Color(.systemGray4) : .clear, lineWidth: 1)
            )
            .frame(maxWidth: 300, alignment: message.role == .assistant ? .leading : .trailing)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ContentView()
}
