import SwiftUI

struct ContentView: View {
    @StateObject private var alice = AliceController()
    @State private var editingPath = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            statusCard
            actions
            Spacer(minLength: 0)
            footer
        }
        .padding(22)
        .frame(width: 480, height: 460)
        .onAppear { alice.refresh() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("StartAlice").font(.title2).bold()
                Text("Mise à jour & lancement d'OpenAlice")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                alice.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Revérifier le statut")
            .disabled(alice.isBusy)
        }
    }

    // MARK: - Status card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                Text(alice.statusLine).font(.headline)
                if alice.isBusy { ProgressView().scaleEffect(0.6) }
                Spacer()
            }
            Divider()
            infoRow("Version locale", alice.localVersion)
            infoRow("Dernière release", alice.latestVersion)
            infoRow("Branche", alice.branch)
            infoRow("Retard sur master",
                    alice.behindCount < 0 ? "?" : "\(alice.behindCount) commit(s)")
        }
        .padding(14)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    private var statusColor: Color {
        if alice.repoMissing { return .red }
        if alice.isBusy { return .yellow }
        return alice.isUpToDate ? .green : .orange
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontDesign(.monospaced)
        }
        .font(.callout)
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                alice.update()
            } label: {
                Label(alice.isUpToDate ? "Revérifier / mettre à jour" : "Mettre à jour",
                      systemImage: "arrow.down.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)

            HStack(spacing: 10) {
                Button {
                    alice.launchDev()
                } label: {
                    Label("Lancer (dev)", systemImage: "hammer.fill")
                        .frame(maxWidth: .infinity)
                }
                Button {
                    alice.launchPackaged()
                } label: {
                    Label("Lancer (app)", systemImage: "app.badge.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .controlSize(.large)

            Button {
                alice.backupConfig()
            } label: {
                Label("Sauvegarder ma config", systemImage: "externaldrive.fill.badge.timemachine")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.regular)
        }
        .disabled(alice.repoMissing)
    }

    // MARK: - Footer (chemin du repo)

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            HStack {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                if editingPath {
                    TextField("Chemin du checkout OpenAlice", text: $alice.repoPath, onCommit: {
                        editingPath = false
                        alice.refresh()
                    })
                    .textFieldStyle(.roundedBorder)
                    .font(.caption.monospaced())
                } else {
                    Text(alice.repoPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1).truncationMode(.head)
                    Spacer()
                    Button("Modifier") { editingPath = true }
                        .buttonStyle(.link).font(.caption)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
