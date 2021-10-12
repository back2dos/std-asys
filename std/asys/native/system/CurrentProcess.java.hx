package asys.native.system;

import haxe.exceptions.NotImplementedException;

/**
	Additional API for the current process.

	@see asys.native.system.Process.current
**/
class CurrentProcess extends Process {
	static public final INST = new CurrentProcess();
	/**
		A stream used by the process as standard input.
	**/
	public var stdin(get,null):IReadable;
	inline function get_stdin():IReadable return stdin;

	/**
		A stream used by the process as standard output.
	**/
	public var stdout(get,null):IWritable;
	inline function get_stdout():IWritable return stdout;

	/**
		A stream used by the process as standard error output.
	**/
	public var stderr(get,null):IWritable;
	inline function get_stderr():IWritable return stderr;

	function new() {
		super();
		this.stdin = asys.native.java.IoWorker.DEFAULT.readStream(java.lang.System._in);
		this.stdout = asys.native.java.IoWorker.DEFAULT.writeStream(java.lang.System.out);
		this.stderr = asys.native.java.IoWorker.DEFAULT.writeStream(java.lang.System.err);
	}

	/**
		Set the action taken by the process on receipt of a `signal`.

		Possible `action` values:
		- `Ignore` - ignore the signal;
		- `Default` - restore default action;
		- `Handle(handler:() -> Void)` - execute `handler` on `signal` receipt.

		Actions for `Kill` and `Stop` signals cannot be changed.
	**/
	public function setSignalAction(signal:Signal, action:SignalAction):Void {
		// see https://stackoverflow.com/questions/19711062/alternative-to-sun-misc-signal
		throw new NotImplementedException();
	}
}