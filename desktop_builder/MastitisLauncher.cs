using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Diagnostics;
using System.Threading;
using System.Collections.Generic;

namespace MastitisResearchDesktop
{
    static class Program
    {
        private static HttpListener _listener;
        private static string _webRoot;
        private static bool _isRunning = true;

        [STAThread]
        static void Main()
        {
            // Ensure single instance per user session
            bool createdNew;
            using (Mutex mutex = new Mutex(true, "MastitisResearchDesktop_App_Mutex_2026", out createdNew))
            {
                if (!createdNew)
                {
                    // Already running
                    return;
                }

                try
                {
                    string exeDir = AppDomain.CurrentDomain.BaseDirectory;
                    _webRoot = Path.Combine(exeDir, "app_data");

                    if (!Directory.Exists(_webRoot))
                    {
                        // Fallback check
                        _webRoot = Path.Combine(exeDir, "web");
                    }

                    if (!Directory.Exists(_webRoot))
                    {
                        System.Windows.Forms.MessageBox.Show(
                            "Application data folder ('app_data') not found.\nPlease reinstall the application.",
                            "Mastitis Research Desktop",
                            System.Windows.Forms.MessageBoxButtons.OK,
                            System.Windows.Forms.MessageBoxIcon.Error
                        );
                        return;
                    }

                    // Find free TCP port
                    int port = GetFreeTcpPort();

                    // Start local HTTP listener
                    _listener = new HttpListener();
                    _listener.Prefixes.Add("http://127.0.0.1:" + port + "/");
                    _listener.Start();

                    // Start background server thread
                    Thread serverThread = new Thread(ServerWorker)
                    {
                        IsBackground = true
                    };
                    serverThread.Start();

                    // Launch dedicated desktop window
                    string appUrl = "http://127.0.0.1:" + port + "/";
                    Process browserProc = LaunchDedicatedAppWindow(appUrl);

                    if (browserProc != null)
                    {
                        browserProc.WaitForExit();
                    }
                    else
                    {
                        // Fallback: wait until process kill
                        Thread.Sleep(Timeout.Infinite);
                    }
                }
                catch (Exception ex)
                {
                    System.Windows.Forms.MessageBox.Show(
                        "Error starting application: " + ex.Message,
                        "Mastitis Research Desktop",
                        System.Windows.Forms.MessageBoxButtons.OK,
                        System.Windows.Forms.MessageBoxIcon.Error
                    );
                }
                finally
                {
                    _isRunning = false;
                    try { if (_listener != null) _listener.Stop(); } catch { }
                    try { if (_listener != null) _listener.Close(); } catch { }
                }
            }
        }

        private static int GetFreeTcpPort()
        {
            TcpListener l = new TcpListener(IPAddress.Loopback, 0);
            l.Start();
            int port = ((IPEndPoint)l.LocalEndpoint).Port;
            l.Stop();
            return port;
        }

        private static Process LaunchDedicatedAppWindow(string url)
        {
            string profileDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "MastitisResearchDesktop",
                "BrowserProfile"
            );

            try { Directory.CreateDirectory(profileDir); } catch { }

            // Candidate browser paths
            string[] candidatePaths = new string[]
            {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), @"Microsoft\Edge\Application\msedge.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Microsoft\Edge\Application\msedge.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Google\Chrome\Application\chrome.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), @"Google\Chrome\Application\chrome.exe"),
            };

            foreach (string path in candidatePaths)
            {
                if (File.Exists(path))
                {
                    string args = string.Format(
                        "--app=\"{0}\" --window-size=1320,860 --user-data-dir=\"{1}\" --no-first-run --no-default-browser-check",
                        url,
                        profileDir
                    );

                    ProcessStartInfo psi = new ProcessStartInfo(path, args)
                    {
                        UseShellExecute = false
                    };
                    return Process.Start(psi);
                }
            }

            // Fallback: system default browser
            ProcessStartInfo defaultPsi = new ProcessStartInfo(url)
            {
                UseShellExecute = true
            };
            return Process.Start(defaultPsi);
        }

        private static void ServerWorker()
        {
            while (_isRunning && _listener != null && _listener.IsListening)
            {
                try
                {
                    HttpListenerContext context = _listener.GetContext();
                    ThreadPool.QueueUserWorkItem(ProcessRequest, context);
                }
                catch
                {
                    if (!_isRunning) break;
                }
            }
        }

        private static void ProcessRequest(object state)
        {
            HttpListenerContext context = (HttpListenerContext)state;
            try
            {
                string rawUrl = context.Request.Url.AbsolutePath.TrimStart('/');
                if (string.IsNullOrEmpty(rawUrl))
                {
                    rawUrl = "index.html";
                }

                // Sanitize path against directory traversal
                rawUrl = rawUrl.Replace('/', Path.DirectorySeparatorChar);
                string filePath = Path.Combine(_webRoot, rawUrl);

                if (!File.Exists(filePath))
                {
                    // Fallback to index.html for SPA routing
                    filePath = Path.Combine(_webRoot, "index.html");
                }

                if (!File.Exists(filePath))
                {
                    context.Response.StatusCode = 404;
                    context.Response.Close();
                    return;
                }

                byte[] bytes = File.ReadAllBytes(filePath);
                string mime = GetMimeType(Path.GetExtension(filePath));

                context.Response.ContentType = mime;
                context.Response.ContentLength64 = bytes.Length;
                context.Response.Headers.Add("Access-Control-Allow-Origin", "*");
                context.Response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate");

                context.Response.OutputStream.Write(bytes, 0, bytes.Length);
                context.Response.OutputStream.Flush();
                context.Response.Close();
            }
            catch
            {
                try { context.Response.Close(); } catch { }
            }
        }

        private static string GetMimeType(string ext)
        {
            if (string.IsNullOrEmpty(ext)) return "application/octet-stream";
            switch (ext.ToLowerInvariant())
            {
                case ".html": return "text/html; charset=utf-8";
                case ".js":
                case ".mjs": return "application/javascript; charset=utf-8";
                case ".css": return "text/css; charset=utf-8";
                case ".json": return "application/json; charset=utf-8";
                case ".wasm": return "application/wasm";
                case ".png": return "image/png";
                case ".jpg":
                case ".jpeg": return "image/jpeg";
                case ".gif": return "image/gif";
                case ".svg": return "image/svg+xml";
                case ".ico": return "image/x-icon";
                case ".ttf": return "font/ttf";
                case ".otf": return "font/otf";
                case ".woff": return "font/woff";
                case ".woff2": return "font/woff2";
                case ".map": return "application/json";
                case ".txt": return "text/plain; charset=utf-8";
                default: return "application/octet-stream";
            }
        }
    }
}
