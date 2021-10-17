package asys.native.net;

import haxe.exceptions.NotSupportedException;
import java.javax.net.ssl.*;
import asys.native.java.IsolatedRunner;
import haxe.io.Bytes;
import haxe.NoData;
import asys.native.net.SocketOptions.SocketOptionKind;
import haxe.exceptions.NotImplementedException;

using asys.native.java.Nio;
using asys.native.java.Streams;

typedef SecureSocketOptions = SocketOptions & {
	//TODO
}

/**
	Secure TCP socket.
**/
class SecureSocket extends Socket {
	/**
		Establish a secure connection to specified address.
	**/
	static public function connect(address:SocketAddress, options:SecureSocketOptions, callback:Callback<SecureSocket>) {
		var runner = IsolatedRunner.create();
		switch address {
			case Net(host, port):
				runner.run(() -> {
					//TODO: this should be using SSLEngine, but my attempts so far have exploded my brain
					var socket = SSLSocketFactory.getDefault().createSocket(host, port);
					new SecureSocket(socket, runner);
				}, callback);
			case Ipc(path): Socket.connect(address, options, (e, _) -> callback.fail(e));// for consistent errors
		}
	}

	function get_localAddress():SocketAddress {
		throw new NotImplementedException();
	}

	function get_remoteAddress():SocketAddress {
		throw new NotImplementedException();
	}

	final socket:java.net.Socket = null;
	final runner:IsolatedRunner;
	final snd:IWritable;
	final rcv:IReadable;

	function new(socket, runner) {
		this.socket = socket;
		this.runner = runner;
		rcv = runner.fork().readStream(socket.getInputStream());
		snd = runner.fork().writeStream(socket.getOutputStream());
	}

	public function read(buffer:Bytes, offset:Int, length:Int, callback:Callback<Int>) {
		rcv.read(buffer, offset, length, callback);
	}

	public function write(buffer:Bytes, offset:Int, length:Int, callback:Callback<Int>) {
		snd.write(buffer, offset, length, callback);
	}

	public function flush(callback:Callback<NoData>) {}

	public function getOption<T>(option:SocketOptionKind<T>, callback:Callback<T>) {}

	public function setOption<T>(option:SocketOptionKind<T>, value:T, callback:Callback<NoData>) {}

	public function close(callback:Callback<NoData>) {}
}