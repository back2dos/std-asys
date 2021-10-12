package asys.native.system;

import haxe.io.BytesBuffer;
import asys.native.java.IoWorker;
import java.util.ArrayList;
import java.lang.ProcessBuilder;
import haxe.ds.ReadOnlyArray;
import haxe.io.Bytes;
import haxe.NoData;
import haxe.exceptions.NotImplementedException;

/**
	Process execution API
**/
class Process {
	/**
		Current process handle.
		Can be used to communicate with the parent process and for self-signalling.
	**/
	static public var current(get, null):CurrentProcess;
	static inline function get_current() return CurrentProcess.INST;

	/**
		Process id.
	**/
	public var pid:Int;

	/**
		Initial IO streams opened for this process.
		The first three indices always are:
		- 0 - stdin
		- 1 - stdout
		- 2 - stderr
		Indices from 3 and higher contain handlers for streams created as configured
		by the corresponding indices in `options.stdio` field of `options` argument
		for `asys.native.system.Process.open` call.
		@see asys.native.system.ProcessOptions.stdio
	**/
	public var stdio(get,never):ReadOnlyArray<Stream>;
	function get_stdio():ReadOnlyArray<Stream> throw new NotImplementedException();

	//TODO: this is a dummy constructor to make the compiler shut up about uninitialized finals.
	function new() {
		pid = -1;
	}

	/**
		Execute and wait for the `command` to fully finish and invoke `callback` with
		the exit code and the contents of stdout, and stderr.

		The `command` argument should not contain command line arguments. Those should
		be passed to `options.args`

		@see asys.native.system.ProcessOptions for various process configuration options.
	 */
	static public function execute(command:String, ?options:ProcessOptions, callback:Callback<{?stdout:Bytes, ?stderr:Bytes, exitCode:Int}>) {
		var todos = 3,
				stdout = new BytesBuffer(),
				stderr = new BytesBuffer(),
				exitCode = 0;

		function done(err, ?_)
			switch err {
				case null:
					if (--todos == 0)
						callback.success({ exitCode: exitCode, stdout: stdout.getBytes(), stderr: stderr.getBytes( )});
				default: callback.fail(err);
			}

		open(command, options, (error, process) -> switch error {
			case null:
				process.stdout.readAllInto(stdout, done);
				process.stderr.readAllInto(stderr, done);
				process.exitCode((error, code) -> {
					exitCode = code;
					done(error);
				});
			default: callback.fail(error);
		});
	}

	/**
		Start `command` execution.

		The `command` argument should not contain command line arguments. Those should
		be passed to `options.args`

		@see asys.native.system.ProcessOptions for various process configuration options.
	 */
	static public function open(command:String, ?options:ProcessOptions, callback:Callback<ChildProcess>) {
		var pb = {
			var cmd = new ArrayList();
			cmd.add(command);
			switch options.args {
				case null:
				case args: for (arg in args) cmd.add(arg);
			}
			new ProcessBuilder(cmd);
		}

		switch options.env {
			case null:
			case vars:
				var env = pb.environment();
				env.clear();// TODO: this is overkill if the user defined env is roughly the same
				for (k => v in vars)
					env.put(k, v);
		}

		switch options.cwd {
			case null:
			case v: pb.directory(new java.io.File(v));
		}

		IoWorker.DEFAULT.run(pb.start, callback.with(ChildProcess.new.bind(_, IoWorker.DEFAULT)));
	}

	/**
		Send `signal` to this process.

		This function does not wait for the process to finish.
		The `callback` only indicates if the signal was sent successfully.

		@see asys.native.system.Signal
	**/
	public function sendSignal(signal:Signal, callback:Callback<NoData>) {
		throw new NotImplementedException();
	}
}