package asys.native.java;

import java.nio.ByteBuffer;
import java.nio.channels.*;
import haxe.io.Bytes;
import haxe.*;
import haxe.NoData;

using asys.native.java.Nio;

class Nio {
	static public function read(runner, channel, ?onClose):IReadable {// TODO: consider exposing selectors
		return new Readable(channel, runner, onClose);
	}

	static public inline function readFrom(runner:IsolatedRunner, channel:ReadableByteChannel, buffer, offset, length, callback) {
		runner.run(() -> channel.read(slice(buffer, offset, length)), callback);
	}

	static public function write(runner, channel, ?onClose):IWritable {
		return new Writable(channel, runner, onClose);
	}

	static public inline function writeTo(runner:IsolatedRunner, channel:WritableByteChannel, buffer, offset, length, callback) {
		runner.run(() -> channel.write(slice(buffer, offset, length)), callback);
	}

	static public inline function slice(target:Bytes, offset:Int, length:Int) {
		var realLength = length > target.length - offset ? target.length - offset : length;
		return ByteBuffer.wrap(target.getData(), offset, realLength);
	}
}


private class Readable implements IReadable {
	final channel:ReadableByteChannel;
	final runner:IsolatedRunner;
	final onClose:()->Void;

	public function new(channel, runner, ?onClose) {
		this.channel = channel;
		this.runner = runner;
		this.onClose = onClose;
	}

	public function read(buffer:Bytes, offset:Int, length:Int, callback:Callback<Exception, Int>) {
		runner.readFrom(channel, buffer, offset, length, callback);
	}

	public function close(callback:Callback<Exception, NoData>) {
		runner.run(() -> {
			channel.close();
			switch onClose {
				case null:
				case f: f();// TODO: not sure exceptions from here should propagate, but swalling them silently doesn't seem like a good idea
			}
			NoData;
		}, callback);
	}
}

private class Writable implements IWritable {
	final channel:WritableByteChannel;
	final runner:IsolatedRunner;
	final onClose:()->Void;

	public function new(channel, runner, ?onClose) {
		this.channel = channel;
		this.runner = runner;
		this.onClose = onClose;
	}

	public function write(buffer:Bytes, offset:Int, length:Int, callback:Callback<Exception, Int>) {
		runner.writeTo(channel, buffer, offset, length, callback);
	}

	public function close(callback:Callback<Exception, NoData>) {
		runner.run(() -> {
			channel.close();
			switch onClose {
				case null:
				case f: f();// TODO: not sure exceptions from here should propagate, but swalling them silently doesn't seem like a good idea
			}
			NoData;
		}, callback);
	}

	public function flush(callback:Callback<Exception, NoData>) {
		runner.run(() -> NoData, callback);// Seems there's no flushing in NIO https://stackoverflow.com/questions/7440514/how-to-flush-a-socketchannel-in-java-nio
	}
}