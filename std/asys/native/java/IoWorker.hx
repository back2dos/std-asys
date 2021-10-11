package asys.native.java;

import java.nio.ByteBuffer;
import java.nio.channels.*;
import haxe.io.Bytes;
import haxe.NoData;
import java.io.IOException;
import haxe.Exception;
import asys.native.filesystem.FsException;
import java.nio.file.*;
import haxe.Callback;

abstract IoWorker(sys.thread.IThreadPool) from sys.thread.IThreadPool {

	static public final DEFAULT = new IoWorker(new sys.thread.ElasticThreadPool(2 * java.lang.Runtime.getRuntime().availableProcessors()));
	public inline function new(t)
		this = t;

	public function run<R>(task:()->R, callback:Callback<Exception, R>) {
		var events = sys.thread.Thread.current().events;
		events.promise();

		inline function fail(e)
			events.runPromised(() -> callback.fail(e));

		inline function iofail(e:IOException, reason)
			fail(new IoException(reason, null, e));

		inline function fsfail(e:FileSystemException, reason)
			fail(new FsException(reason, e.getFile(), null, e));

		this.run(() -> {
			var result = try {
				task();
			} catch (e:NoSuchFileException) {
				fsfail(e, FileNotFound);
				return;
			} catch (e:AccessDeniedException) {
				fsfail(e, AccessDenied);
				return;
			} catch (e:DirectoryNotEmptyException) {
				fsfail(e, NotEmpty);
				return;
			} catch (e:FileAlreadyExistsException) {
				fsfail(e, FileExists);
				return;
			} catch (e:FileSystemLoopException) {
				fsfail(e, CustomError(e.toString()));
				return;
			} catch (e:NotDirectoryException) {
				fsfail(e, NotDirectory);
				return;
			} catch (e:FileSystemException) {// this covers AtomicMoveNotSupportedException, FileSystemLoopException, NotLinkException
				fsfail(e, CustomError(switch e.getReason() {
					case null: e.toString();
					case v: v;
				}));
				return;
			} catch (e:ClosedChannelException) {
				iofail(e, BadFile);// TODO: check that's the right error
				return;
			} catch (e:java.io.FileNotFoundException) {
				iofail(e, FileNotFound);
				return;
			} catch (e:java.lang.Throwable) {
				fail(new IoException(CustomError(e.toString()), null, e));
				return;
			}
			events.runPromised(() -> callback.success(result));
		});
	}

	public function read(channel, ?onClose):IReadable {
		return new Readable(channel, this, onClose);
	}

	public function readStream(stream:java.io.InputStream, ?onClose) {
		return read(Channels.newChannel(stream), onClose);
	}

	public function write(channel, ?onClose):IWritable {
		return new Writable(channel, this, onClose);
	}

	public function writeStream(stream:java.io.OutputStream, ?onClose) {
		return write(Channels.newChannel(stream), onClose);
	}

	static public inline function slice(target:Bytes, offset:Int, length:Int) {
		var realLength = length > target.length - offset ? target.length - offset : length;
		return ByteBuffer.wrap(target.getData(), offset, realLength);
	}
}

private class Readable implements IReadable {
	final channel:ReadableByteChannel;
	final worker:IoWorker;
	final onClose:()->Void;

	public function new(channel, worker, ?onClose) {
		this.channel = channel;
		this.worker = worker;
		this.onClose = onClose;
	}

	public function read(buffer:Bytes, offset:Int, length:Int, callback:Callback<Exception, Int>) {
		worker.run(() -> channel.read(IoWorker.slice(buffer, offset, length)), callback);
	}

	public function close(callback:Callback<Exception, NoData>) {
		worker.run(() -> {
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
	final worker:IoWorker;
	final onClose:()->Void;

	public function new(channel, worker, ?onClose) {
		this.channel = channel;
		this.worker = worker;
		this.onClose = onClose;
	}

	public function write(buffer:Bytes, offset:Int, length:Int, callback:Callback<Exception, Int>) {
		worker.run(() -> channel.write(IoWorker.slice(buffer, offset, length)), callback);
	}

	public function close(callback:Callback<Exception, NoData>) {
		worker.run(() -> {
			channel.close();
			switch onClose {
				case null:
				case f: f();// TODO: not sure exceptions from here should propagate, but swalling them silently doesn't seem like a good idea
			}
			NoData;
		}, callback);
	}

	public function flush(callback:Callback<Exception, NoData>) {
		worker.run(() -> NoData, callback);// Seems there's no flushing in NIO https://stackoverflow.com/questions/7440514/how-to-flush-a-socketchannel-in-java-nio
	}
}