import Foundation

enum LaunchAtLogin {
    private static var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.pomo.app.plist")
    }

    static var isEnabled: Bool {
        get { FileManager.default.fileExists(atPath: launchAgentURL.path) }
        set {
            if newValue {
                let execPath = ProcessInfo.processInfo.arguments[0]
                let plist = """
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
                "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                    <key>Label</key>
                    <string>com.pomo.app</string>
                    <key>ProgramArguments</key>
                    <array>
                        <string>\(execPath)</string>
                    </array>
                    <key>RunAtLoad</key>
                    <true/>
                </dict>
                </plist>
                """
                try? plist.write(to: launchAgentURL, atomically: true, encoding: .utf8)
            } else {
                try? FileManager.default.removeItem(at: launchAgentURL)
            }
        }
    }
}
