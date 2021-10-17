package asys.native.java;

import haxe.exceptions.NotSupportedException;
import asys.native.net.SocketOptions.SocketOptionKind;
import java.net.*;

class Sockets {
  static function j2hx(address:SocketAddress):asys.native.net.SocketAddress
    return switch Std.downcast(address, InetSocketAddress) {
      case null: throw new NotSupportedException('Unsupported socket address kind');
      case v: Net(v.getHostName(), v.getPort());
    }

  static public function remoteAddress(socket:Socket)
    return j2hx(socket.getRemoteSocketAddress());

  static public function localAddress(socket:Socket)
    return j2hx(socket.getLocalSocketAddress());

  static public function getOption<T>(socket:Socket, option:SocketOptionKind<T>):T
    return switch option {
      case ReuseAddress: socket.getReuseAddress();
      case ReusePort: socket.getReuseAddress();
      case KeepAlive: socket.getKeepAlive();
      case SendBuffer: socket.getSendBufferSize();
      case ReceiveBuffer: socket.getReceiveBufferSize();
      case Broadcast: false;
      case MulticastInterface: null;
      case MulticastLoop: false;
      case MulticastTtl: 0;
    }

  static public function setOption<T>(socket:Socket, option:SocketOptionKind<T>, value:T)
    switch option {
      case ReuseAddress: socket.setReuseAddress(value);
      case ReusePort: socket.setReuseAddress(value);
      case KeepAlive: socket.setKeepAlive(value);
      case SendBuffer: socket.setSendBufferSize(value);
      case ReceiveBuffer: socket.setReceiveBufferSize(value);
      default: throw new NotSupportedException('Invalid option for TCP socket');
    }
}