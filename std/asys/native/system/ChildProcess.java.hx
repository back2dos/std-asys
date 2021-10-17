package asys.native.system;

import haxe.NoData;
using asys.native.java.Streams;

/**
	Additional API for child processes spawned by the current process.

	@see asys.native.system.Process.open
**/
class ChildProcess extends Process {
	/**
		A stream used by the process as standard input.
	**/
	public var stdin(get,null):IWritable;
	inline function get_stdin():IWritable return stdin;

	/**
		A stream used by the process as standard output.
	**/
	public var stdout(get,null):IReadable;
	inline function get_stdout():IReadable return stdout;

	/**
		A stream used by the process as standard error output.
	**/
	public var stderr(get,null):IReadable;
	inline function get_stderr():IReadable return stderr;

	final native:java.lang.Process;
	final worker:asys.native.java.IsolatedRunner;

	public function new(native:java.lang.Process, worker) {
		this.native = native;
		this.worker = worker;
		this.stdin = worker.fork().writeStream(native.getOutputStream());
		this.stdout = worker.fork().readStream(native.getInputStream());
		this.stderr = worker.fork().readStream(native.getErrorStream());
		super([Write(stdin), Read(stdout), Read(stderr)]);

	}

	/**
		Wait the process to shutdown and get the exit code.
		If the process is already dead at the moment of this call, then `callback`
		may be invoked with the exit code immediately.
	**/
	public function exitCode(callback:Callback<Int>) {
		waitForExit(callback.with(_ -> native.exitValue()));
	}

	function waitForExit(callback:Callback<NoData>) {
		if (!native.isAlive())
			return callback.success(NoData);

		worker.run(() -> native.waitFor(100, java.util.concurrent.TimeUnit.MILLISECONDS), (?error, done) -> {
			if (error != null) callback.fail(error);
			else if (done) callback.success(NoData);
			else waitForExit(callback);
		});
	}

	/**
		Close the process handle and release associated resources.

		TODO: should this method wait for the process to finish? - right now it does
	**/
	public function close(callback:Callback<NoData>) {
		native.destroyForcibly();
		waitForExit(callback);
	}
}