import Foundation
import SwiftUI

/// Langue de l'interface. `.system` résout vers `fr` si la machine est en français,
/// sinon `en`.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, fr, en
    var id: String { rawValue }
}

/// État sémantique du statut, traduit à l'affichage (jamais du texte figé dans le contrôleur).
enum StatusKind {
    case ready, checking, upToDate, updateAvailable, repoMissing
    case updateStarted, devStarted, packagedStarted, backupStarted, installStarted
}

/// Fournisseur de traductions, observable pour un switch de langue instantané.
@MainActor
final class L10n: ObservableObject {
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue
        language = AppLanguage(rawValue: raw) ?? .system
    }

    /// Langue effective (résout `.system` d'après la préférence machine).
    var effective: AppLanguage {
        switch language {
        case .system:
            let code = (Locale.preferredLanguages.first ?? "en").prefix(2).lowercased()
            return code == "fr" ? .fr : .en
        case .fr: return .fr
        case .en: return .en
        }
    }

    var s: Strings { Strings(lang: effective) }
}

/// Toutes les chaînes de l'UI, résolues selon la langue. `tr(fr, en)` garde les deux
/// versions côte à côte pour éviter les clés orphelines.
struct Strings {
    let lang: AppLanguage
    private func tr(_ fr: String, _ en: String) -> String { lang == .fr ? fr : en }

    var subtitle: String       { tr("Mise à jour & lancement d'OpenAlice", "Update & launch OpenAlice") }
    var refreshHelp: String    { tr("Revérifier le statut", "Re-check status") }

    var rowLocal: String       { tr("Version locale", "Local version") }
    var rowLatest: String      { tr("Dernière release", "Latest release") }
    var rowBranch: String      { tr("Branche", "Branch") }
    var rowBehind: String      { tr("Retard sur master", "Behind master") }

    var btnUpdate: String        { tr("Mettre à jour", "Update") }
    var btnRecheckUpdate: String { tr("Revérifier / mettre à jour", "Re-check / update") }
    var btnDev: String           { tr("Lancer (dev)", "Launch (dev)") }
    var btnApp: String           { tr("Lancer l'application", "Launch the app") }
    var btnBackup: String        { tr("Sauvegarder ma config", "Back up my config") }

    // Libellés courts pour la rangée d'actions à trois boutons
    var btnUpdateShort: String   { tr("Mettre à jour", "Update") }
    var btnDevShort: String      { tr("Dev", "Dev") }
    var btnBackupShort: String   { tr("Sauver", "Back up") }
    var btnInstall: String       { tr("Installer OpenAlice", "Install OpenAlice") }
    var installHint: String      { tr("OpenAlice n'est pas installé à cet emplacement.",
                                      "OpenAlice isn't installed at this location.") }

    var edit: String            { tr("Modifier", "Edit") }
    var pathPlaceholder: String { tr("Chemin du checkout OpenAlice", "Path to the OpenAlice checkout") }

    var settings: String   { tr("Paramètres", "Settings") }
    var languageLabel: String { tr("Langue", "Language") }
    var langSystem: String { tr("Système", "System") }
    var langFr: String     { "Français" }
    var langEn: String     { "English" }

    func behind(_ n: Int) -> String {
        n < 0 ? "?" : "\(n) commit\(n > 1 ? "s" : "")"
    }

    func status(_ k: StatusKind) -> String {
        switch k {
        case .ready:           return tr("Prêt.", "Ready.")
        case .checking:        return tr("Vérification…", "Checking…")
        case .upToDate:        return tr("À jour ✓", "Up to date ✓")
        case .updateAvailable: return tr("Mise à jour disponible.", "Update available.")
        case .repoMissing:     return tr("OpenAlice introuvable — installe-le ci-dessous.",
                                         "OpenAlice not found — install it below.")
        case .updateStarted:   return tr("Mise à jour lancée dans Terminal…", "Update started in Terminal…")
        case .devStarted:      return tr("Lancement (dev) dans Terminal…", "Launch (dev) started in Terminal…")
        case .packagedStarted: return tr("Build + app dans Terminal…", "Build + app started in Terminal…")
        case .backupStarted:   return tr("Sauvegarde config dans Terminal…", "Config backup started in Terminal…")
        case .installStarted:  return tr("Installation dans Terminal…", "Installation started in Terminal…")
        }
    }
}
