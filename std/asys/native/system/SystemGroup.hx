package asys.native.system;

private typedef NativeGroup = Int;

/**
	Represents an OS group account.
**/

abstract SystemGroup(NativeGroup) from NativeGroup to NativeGroup {

	public inline function toString():String {
		return '$this';
	}
}