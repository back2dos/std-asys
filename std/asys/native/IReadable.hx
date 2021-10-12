package asys.native;

import haxe.NoData;
import haxe.io.*;
import haxe.Exception;
import haxe.Callback;

/**
	An interface to read bytes from a source of bytes.
**/
@:using(asys.native.IReadable.ReadableTools)
interface IReadable {
	/**
		Read up to `length` bytes and write them into `buffer` starting from `offset`
		position in `buffer`, then invoke `callback` with the amount of bytes read.
	**/
	function read(buffer:Bytes, offset:Int, length:Int, callback:Callback<Exception,Int>):Void;

	/**
		Close this stream.
	**/
	function close(callback:Callback<Exception,NoData>):Void;
}

class ReadableTools {

	static public function readAllIntoVia(from:IReadable, via:Bytes, release:Bytes->Void, to:BytesBuffer, callback:Callback<Exception, BytesBuffer>) {
		function step() {
			from.read(via, 0, via.length, (error, read) -> switch [error, read] {
				case [null, -1]:
					release(via);
					callback.success(to);
				case [null, _]:
					to.addBytes(via, 0, read);
					step();
				case [err, _]:
					release(via);
					callback.fail(err);
			});
		}
		step();
	}

	static public function readAllInto(from:IReadable, to:BytesBuffer, callback:Callback<Exception, BytesBuffer>) {
		readAllIntoVia(from, Bytes.alloc(0x10000), _ -> {}, to, callback);// TODO: use a pool here
	}

}