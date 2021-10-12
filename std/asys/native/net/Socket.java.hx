package asys.native.net;

import asys.native.java.IoWorker;
import java.net.InetSocketAddress;
import java.nio.channels.SocketChannel;
import haxe.exceptions.NotSupportedException;
import asys.native.net.SocketOptions.SocketOptionKind;
import haxe.NoData;
import haxe.io.Bytes;
import haxe.exceptions.NotImplementedException;

abstract class Socket implements IDuplex {
	/**
		Local address of this socket.
	**/
	public var localAddress(get,never):SocketAddress;
	abstract function get_localAddress():SocketAddress;

	/**
		Remote address of this socket.
	**/
	public var remoteAddress(get,never):SocketAddress;
	abstract function get_remoteAddress():SocketAddress;

	/**
		Establish a connection to `address`.
	**/
	static public function connect(address:SocketAddress, ?options:SocketOptions, callback:Callback<Socket>) {
		switch address {
			case Net(host, port):
				var worker = IoWorker.DEFAULT;
				worker.run(() -> {
					var sock = SocketChannel.open(new InetSocketAddress(host, port));
					sock.configureBlocking(false);// right?
					(new TcpSocket(sock, worker):Socket);
				}, callback);
			case Ipc(_):
				callback.fail(new NotSupportedException('Ipc sockets not supported on Java'));
		}
	}

	/**
		Read up to `length` bytes and write them into `buffer` starting from `offset`
		position in `buffer`, then invoke `callback` with the amount of bytes read.
	**/
	abstract public function read(buffer:Bytes, offset:Int, length:Int, callback:Callback<Int>):Void;

	/**
		Write up to `length` bytes from `buffer` (starting from buffer `offset`),
		then invoke `callback` with the amount of bytes written.
	**/
	abstract public function write(buffer:Bytes, offset:Int, length:Int, callback:Callback<Int>):Void;

	/**
		Force all buffered data to be committed.
	**/
	abstract public function flush(callback:Callback<NoData>):Void;

	/**
		Get the value of a specified socket option.
	**/
	abstract public function getOption<T>(option:SocketOptionKind<T>, callback:Callback<T>):Void;

	/**
		Set socket option.
	**/
	abstract public function setOption<T>(option:SocketOptionKind<T>, value:T, callback:Callback<NoData>):Void;

	/**
		Close the connection.
	**/
	abstract public function close(callback:Callback<NoData>):Void;
}

private class TcpSocket extends Socket {
	function get_localAddress():SocketAddress throw new NotImplementedException();
	function get_remoteAddress():Null<SocketAddress> throw new NotImplementedException();

	final channel:SocketChannel;
	final worker:IoWorker;

	public function new(channel, worker) {
		this.channel = channel;
		this.worker = worker;
	}

	public function read(buffer:Bytes, offset:Int, length:Int, callback:Callback<Int>) {
		worker.readFrom(channel, buffer, offset, length, callback);
	}

	public function write(buffer:Bytes, offset:Int, length:Int, callback:Callback<Int>) {
		worker.writeTo(channel, buffer, offset, length, callback);
	}

	public function flush(callback:Callback<NoData>):Void {
		callback.success(NoData);// Seems there's no flushing in NIO https://stackoverflow.com/questions/7440514/how-to-flush-a-socketchannel-in-java-nio
	}

	public function close(callback:Callback<NoData>) {
		worker.run(() -> { channel.close(); NoData; }, callback);
	}

	public function getOption<T>(option:SocketOptionKind<T>, callback:Callback<T>) {
		callback.fail(new NotImplementedException());
	}

	public function setOption<T>(option:SocketOptionKind<T>, value:T, callback:Callback<NoData>) {
		callback.fail(new NotImplementedException());
	}
}