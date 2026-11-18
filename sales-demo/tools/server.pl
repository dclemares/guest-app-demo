#!/usr/bin/perl
# Tiny static file server for the sales demo (macOS ships with Perl; no install needed).
# Usage: perl server.pl <port> <folder>
use strict; use warnings;
use IO::Socket::INET;
use File::Spec;

my ($port, $root) = @ARGV;
$port ||= 7900; $root ||= '.';
my %MIME = (html=>'text/html; charset=utf-8', htm=>'text/html; charset=utf-8', js=>'text/javascript; charset=utf-8',
  mjs=>'text/javascript; charset=utf-8', css=>'text/css; charset=utf-8', json=>'application/json', svg=>'image/svg+xml',
  png=>'image/png', jpg=>'image/jpeg', jpeg=>'image/jpeg', gif=>'image/gif', webp=>'image/webp', ico=>'image/x-icon',
  woff=>'font/woff', woff2=>'font/woff2', ttf=>'font/ttf', otf=>'font/otf', pdf=>'application/pdf', mp4=>'video/mp4',
  webm=>'video/webm', mp3=>'audio/mpeg', wav=>'audio/wav', txt=>'text/plain; charset=utf-8', map=>'application/json');

my $srv = IO::Socket::INET->new(LocalAddr=>'127.0.0.1', LocalPort=>$port, Proto=>'tcp', Listen=>256, ReuseAddr=>1)
  or die "Could not start the demo server on port $port: $!\n";
$SIG{PIPE} = 'IGNORE';
print "Demo running at http://localhost:$port/  (close this window to stop it)\n";

while (my $c = $srv->accept) {
  $c->autoflush(1);
  my $req = <$c>;
  if (!defined $req) { close $c; next; }
  while (my $h = <$c>) { last if $h =~ /^\r?\n$/; }
  my ($method, $path) = $req =~ m{^(GET|HEAD)\s+(\S+)};
  if (!$method) { print $c "HTTP/1.1 405 Method Not Allowed\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"; close $c; next; }
  $path =~ s/[?#].*$//;
  $path =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
  $path = '/index.html' if $path eq '/';
  $path .= 'index.html' if $path =~ m{/$};
  if ($path =~ m{\.\.}) { print $c "HTTP/1.1 403 Forbidden\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"; close $c; next; }
  my $file = File::Spec->catfile($root, $path);
  if (-d $file) { $file = File::Spec->catfile($file, 'index.html'); }
  if (open(my $fh, '<:raw', $file)) {
    my ($ext) = $file =~ /\.([A-Za-z0-9]+)$/;
    my $type = $MIME{lc($ext // '')} // 'application/octet-stream';
    $type = 'image/jpeg' if $file =~ m{unsplash[/\\]photo-[^/\\.]+$};   # local copies of the stock photos
    my $size = -s $file;
    print $c "HTTP/1.1 200 OK\r\nContent-Type: $type\r\nContent-Length: $size\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n";
    if ($method eq 'GET') { local $/ = \65536; while (my $buf = <$fh>) { print $c $buf; } }
    close $fh;
  } else {
    my $msg = "Not found";
    print $c "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: " . length($msg) . "\r\nConnection: close\r\n\r\n$msg";
  }
  close $c;
}
