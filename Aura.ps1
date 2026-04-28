Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Xml

$xamlPath = Join-Path $PSScriptRoot "Aura.xaml"
$enginePath = Join-Path $PSScriptRoot "AuraWindows\Aura.exe"

# C# Ultimate Logic for Aura
$code = @"
using System;
using System.Windows;
using System.Windows.Markup;
using System.Windows.Controls;
using System.Windows.Media;
using System.IO;
using System.Diagnostics;
using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace AuraApp {
    public class Track {
        public string Title { get; set; }
        public string Artist { get; set; }
        public string FilePath { get; set; }
    }

    public class UIBridge {
        public static void Launch(string xamlPath, string enginePath) {
            try {
                string xaml = File.ReadAllText(xamlPath);
                Window window = (Window)XamlReader.Parse(xaml);
                
                // Elements
                Button btnHome = (Button)window.FindName("BtnHome");
                Button btnSongs = (Button)window.FindName("BtnSongs");
                Button btnImport = (Button)window.FindName("BtnImport");
                Button btnClose = (Button)window.FindName("BtnClose");
                Button btnPlayPause = (Button)window.FindName("BtnPlayPause");
                
                TextBlock lblTitle = (TextBlock)window.FindName("LblTitle");
                StackPanel contentView = (StackPanel)window.FindName("ContentView");
                WrapPanel albumGrid = (WrapPanel)window.FindName("AlbumGrid");
                
                TextBlock txtNowPlaying = (TextBlock)window.FindName("TxtNowPlaying");
                TextBlock txtArtist = (TextBlock)window.FindName("TxtArtist");
                TextBox txtSearch = (TextBox)window.FindName("TxtSearch");

                bool isPlaying = false;

                // Function to create Album Cards
                Action<string, string> addAlbumCard = (title, artist) => {
                    Border card = new Border {
                        Width = 200, Height = 270, Margin = new Thickness(0, 0, 25, 25),
                        Background = new SolidColorBrush(Color.FromArgb(25, 255, 255, 255)),
                        CornerRadius = new CornerRadius(12),
                        Cursor = System.Windows.Input.Cursors.Hand
                    };
                    StackPanel sp = new StackPanel { Margin = new Thickness(15) };
                    Border img = new Border { Width = 170, Height = 170, CornerRadius = new CornerRadius(8), Background = new SolidColorBrush(Color.FromArgb(40, 255, 255, 255)) };
                    img.Child = new TextBlock { Text = "🎵", FontSize = 40, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
                    
                    sp.Children.Add(img);
                    sp.Children.Add(new TextBlock { Text = title, Foreground = Brushes.White, FontWeight = FontWeights.Bold, Margin = new Thickness(0, 12, 0, 2), FontSize = 15 });
                    sp.Children.Add(new TextBlock { Text = artist, Foreground = new SolidColorBrush(Color.FromArgb(120, 255, 255, 255)), FontSize = 12 });
                    card.Child = sp;
                    
                    card.MouseEnter += (s, e) => card.Background = new SolidColorBrush(Color.FromArgb(40, 255, 255, 255));
                    card.MouseLeave += (s, e) => card.Background = new SolidColorBrush(Color.FromArgb(25, 255, 255, 255));
                    card.MouseDown += (s, e) => {
                        txtNowPlaying.Text = title;
                        txtArtist.Text = artist;
                        isPlaying = true;
                        btnPlayPause.Content = "⏸";
                    };

                    albumGrid.Children.Add(card);
                };

                // View Switcher
                Action<string> setView = (v) => {
                    lblTitle.Text = v;
                    albumGrid.Children.Clear();
                    // In a full app, we would hide/show different containers here
                    if (v == "Listen Now") {
                        addAlbumCard("After Hours", "The Weeknd");
                        addAlbumCard("Future Nostalgia", "Dua Lipa");
                        addAlbumCard("Certified Lover Boy", "Drake");
                        addAlbumCard("Justice", "Justin Bieber");
                    }
                };

                // Events
                btnHome.Click += (s, e) => setView("Listen Now");
                btnImport.Click += (s, e) => {
                    string url = txtSearch.Text;
                    if (string.IsNullOrEmpty(url)) {
                        MessageBox.Show("Paste a link in the Search bar first!");
                        return;
                    }
                    if (File.Exists(enginePath)) {
                        Process.Start(new ProcessStartInfo(enginePath, "\"" + url + "\"") { WindowStyle = ProcessWindowStyle.Hidden });
                        MessageBox.Show("Download added: " + url);
                    }
                };

                btnPlayPause.Click += (s, e) => { isPlaying = !isPlaying; btnPlayPause.Content = isPlaying ? "⏸" : "▶"; };
                btnClose.Click += (s, e) => window.Close();
                window.MouseLeftButtonDown += (s, e) => { if (e.LeftButton == System.Windows.Input.MouseButtonState.Pressed) window.DragMove(); };

                // Init
                setView("Listen Now");
                window.ShowDialog();
            } catch (Exception ex) {
                MessageBox.Show("UI Error: " + ex.Message);
            }
        }
    }
}
"@

Add-Type -TypeDefinition $code -ReferencedAssemblies "PresentationFramework", "PresentationCore", "WindowsBase", "System.Xaml", "System.Xml"

[AuraApp.UIBridge]::Launch($xamlPath, $enginePath)
