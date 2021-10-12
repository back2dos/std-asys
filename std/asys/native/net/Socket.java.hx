package asys.native.net;

import asys.native.java.IoWorker;
import java.net.InetSocketAddress;
import java.nio.channels.SocketChannel;
import haxe.exceptions.NotSupportedException;
import asys.native.net.SocketOptions.SocketOptionKind;
import haxe.NoData;
import haxe.io.Bytes;
import haxe.exceptions.NotImplementedException;

class Socket implements IDuplex {
	/**
		Local address of this socket.
	**/
	public var localAddress(get,never):SocketAddress;
	function get_localAddress():SocketAddress throw new NotImplementedException();

	/**
		Remote address of this socket if it is bound.
	**/
	public var remoteAddress(get,never):Null<SocketAddress>;
	function get_remoteAddress():Null<SocketAddress> throw new NotImplementedException();

	final channel:SocketChannel;
	final worker:IoWorker;

	function new(channel, worker) {
		this.channel = channel;
		this.worker = worker;
	}
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
					new Socket(sock, worker);
				}, callback);
			case Ipc(path):
				callback.fail(new NotSupportedException('Ipc sockets not supported on Java'));
		}
	}

	/**
		Read up to `length` bytes and write them into `buffer` starting from `offset`
		position in `buffer`, then invoke `callback` with the amount of bytes read.
	**/
	public function read(buffer:Bytes, offset:Int, length:Int, callback:Callback<Int>) {
		worker.readFrom(channel, buffer, offset, length, callback);
	}

	/**
		Write up to `length` bytes from `buffer` (starting from buffer `offset`),
		then invoke `callback` with the amount of bytes written.
	**/
	public function write(buffer:Bytes, offset:Int, length:Int, callback:Callback<Int>) {
		worker.writeTo(channel, buffer, offset, length, callback);
	}

	/**
		Force all buffered data to be committed.
	**/
	public function flush(callback:Callback<NoData>):Void {
		callback.success(NoData);// Seems there's no flushing in NIO https://stackoverflow.com/questions/7440514/how-to-flush-a-socketchannel-in-java-nio
	}

	/**
		Get the value of a specified socket option.
	**/
	public function getOption<T>(option:SocketOptionKind<T>, callback:Callback<T>) {
		throw new NotImplementedException();
	}

	/**
		Set socket option.
	**/
	public function setOption<T>(option:SocketOptionKind<T>, value:T, callback:Callback<NoData>) {
		throw new NotImplementedException();
	}

	/**
		Close the connection.
	**/
	public function close(callback:Callback<NoData>) {
		throw new NotImplementedException();
	}
}