
function main() {
  asys.native.system.Process.execute('haxe.cmd', { args: ['-version'] }, (?err, out) -> {
    trace('exited with ${out.exitCode}: ${out.stdout.toString()}');
  });
}