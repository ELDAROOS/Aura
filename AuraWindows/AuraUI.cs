using System;
using System.Windows;
using System.Diagnostics;
using System.IO;

namespace Aura {
    public partial class MainWindow : Window {
        public MainWindow() {
            InitializeComponent();
        }

        private void Download_Click(object sender, RoutedEventArgs e) {
            // This would be connected to an actual text input in XAML
            string url = "https://youtube.com/watch?v=example"; 
            RunSwiftEngine(url);
        }

        private void RunSwiftEngine(string url) {
            try {
                ProcessStartInfo startInfo = new ProcessStartInfo();
                startInfo.FileName = "Aura.exe";
                startInfo.Arguments = "\"" + url + "\"";
                startInfo.UseShellExecute = false;
                startInfo.CreateNoWindow = true;
                
                Process.Start(startInfo);
            } catch (Exception ex) {
                MessageBox.Show("Error starting engine: " + ex.Message);
            }
        }

        // Add window drag support
        protected override void OnMouseLeftButtonDown(System.Windows.Input.MouseButtonEventArgs e) {
            base.OnMouseLeftButtonDown(e);
            this.DragMove();
        }
    }

    public class App : Application {
        [STAThread]
        public static void Main() {
            App app = new App();
            app.Run(new MainWindow());
        }
    }
}
