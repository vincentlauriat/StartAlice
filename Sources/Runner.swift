import Foundation

/// Exécution de commandes shell, avec deux modes :
///  - `capture` : synchrone, capture stdout+stderr (pour les vérifs de statut).
///  - `runInTerminal` : ouvre Terminal.app et y lance une commande longue/interactive
///    (pnpm dev, mise à jour…) pour que l'utilisateur voie les logs en direct.
enum Runner {

    /// Login shell (`zsh -lc`) afin d'hériter du PATH utilisateur (node, pnpm, gh via nvm/homebrew…).
    @discardableResult
    static func capture(_ command: String, cwd: String? = nil) -> (ok: Bool, output: String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-lc", command]
        if let cwd { proc.currentDirectoryURL = URL(fileURLWithPath: cwd) }

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe

        do {
            try proc.run()
        } catch {
            return (false, "Échec de lancement : \(error.localizedDescription)")
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        let out = String(data: data, encoding: .utf8) ?? ""
        return (proc.terminationStatus == 0, out)
    }

    /// Ouvre Terminal.app et y exécute `command`. Nécessite l'autorisation Automation au 1er appel.
    static func runInTerminal(_ command: String) {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let appleScript = """
        tell application "Terminal"
            activate
            do script "\(escaped)"
        end tell
        """
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", appleScript]
        try? p.run()
    }
}

extension String {
    /// Quoting sûr pour insérer une valeur dans une ligne de commande shell.
    var shellQuoted: String {
        "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
