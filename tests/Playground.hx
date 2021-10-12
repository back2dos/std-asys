import asys.native.system.*;

function main() {
  Process.execute('haxe.cmd', { args: ['-version'] }, (?err, out) -> {
    trace(err, out.stdout.toString(), out.stderr.toString(), out.exitCode);
  });
  // @:privateAccess FileSystem.inBackground('test', () -> 0, (_, _) -> {});
}