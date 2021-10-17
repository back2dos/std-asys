package asys.native.java;

import java.io.*;
import haxe.NoData;
import haxe.*;

class Streams {

	static public function readStream(runner, stream:InputStream, ?onClose):IReadable {
		return new Readable(stream, runner, onClose);
	}

	static public function writeStream(runner, stream:OutputStream, ?onClose):IWritable {
		return new Writable(stream, runner, onClose);
	}
}

private class Readable implements IReadable {
	final stream:InputStream;
	final runner:IsolatedRunner;
	final onClose:()->Void;

	public function new(stream, runner, ?onClose) {
		this.stream = stream;
		this.runner = runner;
		this.onClose = onClose;
	}

	public function read(buffer:haxe.io.Bytes, offset:Int, length:Int, callback:Callback<Exception, Int>) {
		runner.run(() -> stream.read(buffer.getData(), offset, length), callback);
	}

	public function close(callback:Callback<Exception, NoData>) {
		runner.run(() -> {
			stream.close();
			switch onClose {
				case null:
				case f: f();// TODO: not sure exceptions from here should propagate, but swalling them silently doesn't seem like a good idea
			}
			NoData;
		}, callback);
	}
}


private class Writable implements IWritable {
	final stream:OutputStream;
	final runner:IsolatedRunner;
	final onClose:()->Void;

	public function new(stream, runner, ?onClose) {
		this.stream = stream;
		this.runner = runner;
		this.onClose = onClose;
	}

	public function write(buffer:haxe.io.Bytes, offset:Int, length:Int, callback:Callback<Exception, Int>) {
		runner.run(() -> { stream.write(buffer.getData(), offset, length); length; }, callback);
	}

	public function close(callback:Callback<Exception, NoData>) {
		runner.run(() -> {
			stream.close();
			switch onClose {
				case null:
				case f: f();// TODO: not sure exceptions from here should propagate, but swalling them silently doesn't seem like a good idea
			}
			NoData;
		}, callback);
	}

	public function flush(callback:Callback<Exception, NoData>) {
		runner.run(() -> { stream.flush(); NoData; }, callback);
	}
}