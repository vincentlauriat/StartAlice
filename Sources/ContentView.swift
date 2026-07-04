import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var alice = AliceController()
    @StateObject private var l10n = L10n()
    @State private var editingPath = false

    private var s: Strings { l10n.s }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            statusCard
            if alice.repoMissing {
                installBlock
            } else {
                actions
            }
            settings
            Spacer(minLength: 0)
            footer
        }
        .padding(22)
        .frame(width: 480, height: 540)
        .onAppear { alice.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // De retour sur StartAlice après une update/install lancée dans Terminal :
            // re-scanner pour refléter le résultat (pastille + statut).
            if alice.awaitingResync { alice.refresh() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("StartAlice").font(.title2).bold()
                Text(s.subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button { alice.refresh() } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help(s.refreshHelp)
            .disabled(alice.isBusy)
        }
    }

    // MARK: - Status card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(statusColor).frame(width: 10, height: 10)
                Text(s.status(alice.status)).font(.headline)
                if alice.isBusy { ProgressView().scaleEffect(0.6) }
                Spacer()
            }
            Divider()
            infoRow(s.rowLocal, alice.localVersion)
            infoRow(s.rowLatest, alice.latestVersion)
            infoRow(s.rowBranch, alice.branch)
            infoRow(s.rowBehind, s.behind(alice.behindCount))
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

    // MARK: - Install (repo manquant)

    private var installBlock: some View {
        VStack(spacing: 10) {
            Text(s.installHint)
                .font(.callout).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button { alice.installRepo() } label: {
                Label(s.btnInstall, systemImage: "square.and.arrow.down.on.square.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 10) {
            Button { alice.update() } label: {
                Label(alice.isUpToDate ? s.btnRecheckUpdate : s.btnUpdate,
                      systemImage: "arrow.down.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)

            HStack(spacing: 10) {
                Button { alice.launchDev() } label: {
                    Label(s.btnDev, systemImage: "hammer.fill").frame(maxWidth: .infinity)
                }
                Button { alice.launchPackaged() } label: {
                    Label(s.btnApp, systemImage: "app.badge.fill").frame(maxWidth: .infinity)
                }
            }
            .controlSize(.large)

            Button { alice.backupConfig() } label: {
                Label(s.btnBackup, systemImage: "externaldrive.fill.badge.timemachine")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.regular)
        }
    }

    // MARK: - Settings (langue)

    private var settings: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            HStack {
                Label(s.settings, systemImage: "gearshape.fill")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            HStack {
                Text(s.languageLabel).font(.callout).foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $l10n.language) {
                    Text(s.langSystem).tag(AppLanguage.system)
                    Text(s.langFr).tag(AppLanguage.fr)
                    Text(s.langEn).tag(AppLanguage.en)
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .labelsHidden()
            }
        }
    }

    // MARK: - Footer (chemin du repo)

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            HStack {
                Image(systemName: "folder").foregroundStyle(.secondary)
                if editingPath {
                    TextField(s.pathPlaceholder, text: $alice.repoPath, onCommit: {
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
                    Button(s.edit) { editingPath = true }
                        .buttonStyle(.link).font(.caption)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
