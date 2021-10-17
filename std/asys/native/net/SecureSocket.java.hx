package asys.native.net;

import java.javax.net.ssl.*;
import asys.native.java.IsolatedRunner;
import haxe.io.Bytes;
import haxe.NoData;
import asys.native.net.SocketOptions.SocketOptionKind;

using asys.native.java.Nio;
using asys.native.java.Sockets;
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

	function get_localAddress():SocketAddress
		return socket.localAddress();

	function get_remoteAddress():SocketAddress
		return socket.remoteAddress();

	final socket:java.net.Socket;
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

	public function flush(callback:Callback<NoData>) {
		snd.flush(callback);
	}

	public function getOption<T>(option:SocketOptionKind<T>, callback:Callback<T>) {
		runner.run(() -> socket.getOption(option), callback);
	}

	public function setOption<T>(option:SocketOptionKind<T>, value:T, callback:Callback<NoData>) {
		runner.run(() -> { socket.setOption(option, value); NoData; }, callback);
	}

	public function close(callback:Callback<NoData>) {
		// This triple shutdown is perhaps a little "too thorough"
		var todos = 2;
		function done(error, v)
			switch error {
				case null:
					if (--todos == 0)
						runner.run(() -> { socket.close(); NoData; }, callback);
				default:
					callback.fail(error);
			}
		snd.close(done);
		rcv.close(done);
	}
}