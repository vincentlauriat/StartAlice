import Foundation
import SwiftUI

/// État + actions du launcher. La logique lourde (git, pnpm, backup, lancement)
/// vit dans `actions.sh` embarqué dans le bundle ; ici on ne fait qu'orchestrer.
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
    @Published var statusLine    = "Prêt."
    @Published var isBusy        = false

    /// À jour ssi 0 commit de retard et version locale ≥ dernière release connue.
    var isUpToDate: Bool {
        guard !repoMissing, behindCount == 0, localVersion != "—" else { return false }
        return latestVersion == "—" || localVersion == latestVersion
    }

    private var actionsScript: String {
        Bundle.main.path(forResource: "actions", ofType: "sh") ?? ""
    }

    // MARK: - Vérification de statut (in-app, lecture seule)

    func refresh() {
        guard !actionsScript.isEmpty else {
            statusLine = "actions.sh introuvable dans le bundle."
            return
        }
        isBusy = true
        statusLine = "Vérification…"
        let cmd = "bash \(actionsScript.shellQuoted) status \(repoPath.shellQuoted)"
        Task.detached(priority: .userInitiated) {
            let r = Runner.capture(cmd)
            await MainActor.run {
                self.parseStatus(r.output)
                self.isBusy = false
                if self.repoMissing {
                    self.statusLine = "Checkout OpenAlice introuvable — vérifie le chemin."
                } else {
                    self.statusLine = self.isUpToDate ? "À jour ✓" : "Mise à jour disponible."
                }
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

    func update()          { runVerb("update", note: "Mise à jour lancée dans Terminal…") }
    func launchDev()       { runVerb("dev", note: "Lancement mode dev dans Terminal…") }
    func launchPackaged()  { runVerb("packaged", note: "Build + app packagée dans Terminal…") }
    func backupConfig()    { runVerb("backup", note: "Sauvegarde de la config dans Terminal…") }

    private func runVerb(_ verb: String, note: String) {
        guard !actionsScript.isEmpty else { return }
        let cmd = "bash \(actionsScript.shellQuoted) \(verb) \(repoPath.shellQuoted)"
        Runner.runInTerminal(cmd)
        statusLine = note
    }
}
