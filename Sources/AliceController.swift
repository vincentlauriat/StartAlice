import Foundation
import SwiftUI

/// État + actions du launcher. La logique lourde (git, pnpm, backup, install, lancement)
/// vit dans `actions.sh` embarqué dans le bundle ; ici on ne fait qu'orchestrer.
/// Le statut est exposé de façon **sémantique** (`StatusKind`) et traduit à l'affichage.
@MainActor
final class AliceController: ObservableObject {

    /// Chemin du checkout OpenAlice, éditable et persistant.
    @AppStorage("repoPath")
    var repoPath: String = "\(NSHomeDirectory())/DevApps/FinancesTools/OpenAlice"

    @Published var localVersion  = "—"
    @Published var latestVersion = "—"
    @Published var behindCount   = -1        // -1 = inconnu
    @Published var branch        = "—"
    @Published var repoMissing   = false
    @Published var status: StatusKind = .ready
    @Published var isBusy        = false

    /// À jour ssi 0 commit de retard et version locale ≥ dernière release connue.
    var isUpToDate: Bool {
        guard !repoMissing, behindCount == 0, localVersion != "—" else { return false }
        return latestVersion == "—" || localVersion == latestVersion
    }

    /// Une action modifiant la version tourne dans Terminal : au retour sur l'app,
    /// on doit re-scanner pour refléter le résultat (update/install).
    var awaitingResync: Bool {
        status == .updateStarted || status == .installStarted
    }

    private var actionsScript: String {
        Bundle.main.path(forResource: "actions", ofType: "sh") ?? ""
    }

    // MARK: - Vérification de statut (in-app, lecture seule)

    func refresh() {
        guard !actionsScript.isEmpty else { return }
        isBusy = true
        status = .checking
        let cmd = "bash \(actionsScript.shellQuoted) status \(repoPath.shellQuoted)"
        Task.detached(priority: .userInitiated) {
            let r = Runner.capture(cmd)
            await MainActor.run {
                self.parseStatus(r.output)
                self.isBusy = false
                self.status = self.repoMissing ? .repoMissing
                            : (self.isUpToDate ? .upToDate : .updateAvailable)
            }
        }
    }

    private func parseStatus(_ out: String) {
        repoMissing = out.contains("REPO_MISSING=")
        for line in out.split(separator: "\n") {
            let kv = line.split(separator: "=", maxSplits: 1)
            guard kv.count == 2 else { continue }
            let value = String(kv[1]).trimmingCharacters(in: .whitespaces)
            switch kv[0] {
            case "LOCAL":  localVersion  = value
            case "LATEST": latestVersion = value
            case "BEHIND": behindCount   = Int(value) ?? -1
            case "BRANCH": branch        = value
            default: break
            }
        }
    }

    // MARK: - Actions (déléguées à Terminal.app)

    func update()         { runVerb("update", then: .updateStarted) }
    func launchDev()      { runVerb("dev", then: .devStarted) }
    func launchPackaged() { runVerb("packaged", then: .packagedStarted) }
    func backupConfig()   { runVerb("backup", then: .backupStarted) }
    func installRepo()    { runVerb("install", then: .installStarted) }

    private func runVerb(_ verb: String, then kind: StatusKind) {
        guard !actionsScript.isEmpty else { return }
        let cmd = "bash \(actionsScript.shellQuoted) \(verb) \(repoPath.shellQuoted)"
        Runner.runInTerminal(cmd)
        status = kind
    }
}
