# Tiny static file server for the sales demo (Windows PowerShell, built into Windows; no install needed).
# Usage: powershell -ExecutionPolicy Bypass -File server.ps1 <port> <folder>
param([int]$Port = 7900, [string]$Root = '.')
$Root = (Resolve-Path $Root).Path
$mime = @{ '.html'='text/html; charset=utf-8'; '.htm'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8';
  '.mjs'='text/javascript; charset=utf-8'; '.css'='text/css; charset=utf-8'; '.json'='application/json'; '.svg'='image/svg+xml';
  '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.gif'='image/gif'; '.webp'='image/webp'; '.ico'='image/x-icon';
  '.woff'='font/woff'; '.woff2'='font/woff2'; '.ttf'='font/ttf'; '.otf'='font/otf'; '.pdf'='application/pdf'; '.mp4'='video/mp4';
  '.webm'='video/webm'; '.mp3'='audio/mpeg'; '.wav'='audio/wav'; '.txt'='text/plain; charset=utf-8' }
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try { $listener.Start() } catch { Write-Host "Could not start the demo server on port $Port. Is it already running?"; Read-Host 'Press Enter to close'; exit 1 }
Write-Host "Demo running at http://localhost:$Port/  (close this window to stop it)"
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $res = $ctx.Response
  try {
    $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
    if ($path -eq '/' -or $path.EndsWith('/')) { $path += 'index.html' }
    if ($path.Contains('..')) { $res.StatusCode = 403; $res.Close(); continue }
    $file = Join-Path $Root ($path.TrimStart('/').Replace('/', '\'))
    if (Test-Path $file -PathType Container) { $file = Join-Path $file 'index.html' }
    if (Test-Path $file -PathType Leaf) {
      $ext = [IO.Path]::GetExtension($file).ToLower()
      $res.ContentType = $(if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' })
      if ($file -match 'unsplash\\photo-[^\\.]+$') { $res.ContentType = 'image/jpeg' }   # local copies of the stock photos
      $res.Headers.Add('Cache-Control', 'no-store')
      $bytes = [IO.File]::ReadAllBytes($file)
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else { $res.StatusCode = 404 }
  } catch { $res.StatusCode = 500 }
  finally { try { $res.Close() } catch {} }
}
