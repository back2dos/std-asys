function main() {

  asys.native.system.Process.execute('haxe.cmd', { args: ['-version'] }, (?err, out) -> {
    trace('exited with ${out.exitCode}: ${out.stdout.toString()}');
  });

  asys.native.net.Socket.connect(Net('example.com', 80), null, (error, socket) -> switch error {
    case null:
      socket.writeString('GET / HTTP/1.0\nHost: example.com\n\n', (error, res) -> {});
      socket.readAll((error, bytes) -> switch error {
        case null: trace(bytes.toString().split('<title>').pop().split('</')[0]);
        case error: trace(error);
      });
    case e:
      trace('error', e);
  });
}