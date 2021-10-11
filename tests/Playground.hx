import asys.native.filesystem.*;
import haxe.io.Bytes;

function main() {
  asys.native.system.Process.current.stdout.write(Bytes.ofString('haha'), 0, 4, (?err, len) -> {
    trace(err, len);
  });
  // @:privateAccess FileSystem.inBackground('test', () -> 0, (_, _) -> {});
}