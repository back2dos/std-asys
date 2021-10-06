package asys.native;

import asys.native.IoErrorType;
import haxe.Exception;

class IoException extends Exception {
	/**
		Error type
	**/
	public final type:IoErrorType;

	public function new(type:IoErrorType, ?previous:Exception, ?native:Any) {
		super(type.toString(), previous, native);
		this.type = type;
	}
}