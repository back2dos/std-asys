import asys.native.system.Process;

function main() {
  Process.open('haxe', { args: ['-version'] }, (?e, p) -> {
    
  });
}