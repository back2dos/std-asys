package asys.native.java;

import java.nio.channels.*;
import java.io.*;

class Streams {

	static public function readStream(runner, stream:InputStream, ?onClose) {
		return Nio.read(runner, Channels.newChannel(stream), onClose);
	}

	static public function writeStream(runner, stream:OutputStream, ?onClose) {
		return Nio.write(runner, Channels.newChannel(stream), onClose);
	}
}