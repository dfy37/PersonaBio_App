import SwiftUI

struct ContentView: View {
    @State private var selectedBio = "我的父亲"
    @State private var writeByChapter = false
    @State private var basicInfo = ""
    @State private var chapterDraft = ""
    @State private var showChapterList = false

    private let biographies = ["我的父亲", "创业导师", "人生合伙人"]
    private let chapterList = ["第一章·童年", "第二章·求学", "第三章·事业转折", "第四章·传承"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                topBar

                Text("LLM Agent 自动化采访与人物传记")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if writeByChapter {
                    chapterLayout
                } else {
                    nonChapterLayout
                }

                Spacer(minLength: 6)

                Button(action: startWriting) {
                    Label("开始编写传记", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showChapterList) {
                NavigationStack {
                    List(chapterList, id: \.self) { chapter in
                        Text(chapter)
                    }
                    .navigationTitle("章节列表")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("完成") { showChapterList = false }
                        }
                    }
                }
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Toggle(isOn: $writeByChapter) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("按章节编写")
                        .font(.subheadline.weight(.semibold))
                    Text(writeByChapter ? "后期精修建议开启" : "初期建议关闭")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            Spacer()

            Menu {
                ForEach(biographies, id: \.self) { bio in
                    Button {
                        selectedBio = bio
                    } label: {
                        Label(bio, systemImage: selectedBio == bio ? "checkmark" : "book")
                    }
                }
            } label: {
                Label(selectedBio, systemImage: "person.text.rectangle")
                    .font(.subheadline.weight(.medium))
            }
        }
    }

    private var chapterLayout: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                infoCard
                    .frame(maxWidth: .infinity, minHeight: 190)

                VStack(spacing: 12) {
                    actionCard(
                        title: "新建章节",
                        subtitle: "让 Agent 规划采访问题",
                        icon: "plus.square.on.square"
                    )

                    Button {
                        showChapterList = true
                    } label: {
                        actionCard(
                            title: "编辑章节",
                            subtitle: "点击弹出章节列表",
                            icon: "square.and.pencil"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 190)
            }

            coCreateCard
        }
    }

    private var nonChapterLayout: some View {
        VStack(spacing: 12) {
            infoCard

            actionCard(
                title: "查看传记",
                subtitle: "浏览已有内容并继续采访",
                icon: "book.pages"
            )
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("基本信息")
                .font(.headline)

            Text("可手动输入：编写人关系、重要节点等；也可跳过")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $basicInfo)
                .frame(minHeight: writeByChapter ? 112 : 150)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text("示例：我是主人公女儿，希望突出创业与家庭平衡。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var coCreateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("共创章节")
                .font(.headline)
            Text("其他用户可协作编辑同一传记章节，按权限决定是否可编辑。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Label("王小明：可评论", systemImage: "person.2")
                Spacer()
                Text("只读")
                    .foregroundStyle(.orange)
            }
            HStack {
                Label("李华：可共同编辑", systemImage: "person.2.fill")
                Spacer()
                Text("可编辑")
                    .foregroundStyle(.green)
            }
            .font(.caption)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func actionCard(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            if title == "新建章节" {
                TextField("例如：第五章·后疫情时代", text: $chapterDraft)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func startWriting() {
        // 预留：后续接入 LLM Agent 自动化采访与写作流程。
    }
}

#Preview {
    ContentView()
}
