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

enum AppSection: Hashable {
    case chat
    case draft
}

struct ContentView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: "你好，我是你的传记采访助手。我们会像 ChatGPT 一样通过对话收集素材，信息足够后再开始撰写。\n\n先从第一问开始：你和主人公是什么关系？")
    ]
    @State private var inputText = ""
    @State private var interviewStep = 0
    @State private var collectedAnswers: [String] = []
    @State private var writingStarted = false
    @State private var generatedDraft: String?
    @State private var selectedSection: AppSection? = .chat

    private let interviewQuestions: [String] = [
        "你和主人公是什么关系？",
        "你最想让读者记住主人公的哪三个特质？",
        "有哪些关键人生节点（年份或阶段）必须写进去？",
        "有没有一件最能代表 TA 的故事，请尽量具体描述。"
    ]

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                NavigationLink(value: AppSection.chat) {
                    Label("采访聊天", systemImage: "message")
                }

                NavigationLink(value: AppSection.draft) {
                    Label("传记初稿", systemImage: "doc.text")
                }
                .disabled(generatedDraft == nil)
            }
            .navigationTitle("PersonaBio")
        } detail: {
            NavigationStack {
                switch selectedSection ?? .chat {
                case .chat:
                    chatView
                case .draft:
                    draftView
                }
            }
        }
    }

    private var chatView: some View {
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

            if generatedDraft != nil {
                Button {
                    selectedSection = .draft
                } label: {
                    Label("查看初稿", systemImage: "doc.text.magnifyingglass")
                }
                .buttonStyle(.bordered)
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

            if generatedDraft != nil {
                Button {
                    selectedSection = .draft
                } label: {
                    Label("进入初稿页面查看", systemImage: "arrow.right.circle")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var draftView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("传记初稿")
                    .font(.title2.bold())

                if let generatedDraft {
                    Text(generatedDraft)
                        .font(.body)
                        .textSelection(.enabled)
                } else {
                    ContentUnavailableView(
                        "暂无初稿",
                        systemImage: "doc.text",
                        description: Text("请先在采访聊天中完成素材收集，并点击“开始撰写”。")
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("初稿查看")
        .navigationBarTitleDisplayMode(.inline)
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

        generatedDraft = draft
        messages.append(ChatMessage(role: .assistant, content: "初稿已生成。你可以点击输入框右侧“查看初稿”，或从侧边栏进入“传记初稿”页面查看。"))
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
