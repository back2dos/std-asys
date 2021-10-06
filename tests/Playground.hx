import asys.native.filesystem.*;
import haxe.io.Bytes;

function main() {
  @:privateAccess FileSystem.inBackground('test', () -> 0, (_, _) -> {});
}