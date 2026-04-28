import Foundation

@main
struct AuraAppWin {
    static func main() {
        print("🚀 Aura for Windows is starting...")
        
        // Initialize Windows Services
        TrayServiceWin.shared.setupTray()
        NotificationServiceWin.shared.showNotification(title: "Aura", message: "Aura is now running in the background.")
        
        let window = MainWindowWin()
        window.render()
        
        // В реальном WinUI приложении здесь был бы вызов:
        // Application.start { Application() }
        
        print("✅ Aura is running. Waiting for user input (Emulated).")
        
        // Эмулируем работу или берем из аргументов:
        let testUrl = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "https://youtube.com/watch?v=example"
        window.onDownloadClicked(url: testUrl)
        window.onPlayClicked()
        
        print("\n⌨️ Нажми ENTER, чтобы выйти...")
        _ = readLine()
    }
}