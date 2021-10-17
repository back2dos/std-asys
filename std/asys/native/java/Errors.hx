package asys.native.java;

import java.lang.Throwable;
import java.io.IOException;
import java.nio.file.*;
import asys.native.filesystem.FsException;
import java.nio.channels.*;

class Errors {
  static public function translate(t:Throwable) {

		inline function iofail(e:IOException, reason)
			return new IoException(reason, null, e);

		inline function fsfail(e:FileSystemException, reason)
			return new FsException(reason, e.getFile(), null, e);

		return
			try throw t
			catch (e:NoSuchFileException) fsfail(e, FileNotFound)
			catch (e:AccessDeniedException) fsfail(e, AccessDenied)
			catch (e:DirectoryNotEmptyException) fsfail(e, NotEmpty)
			catch (e:FileAlreadyExistsException) fsfail(e, FileExists)
			catch (e:FileSystemLoopException) fsfail(e, CustomError(e.toString()))
			catch (e:NotDirectoryException) fsfail(e, NotDirectory)
			catch (e:FileSystemException) {// this covers AtomicMoveNotSupportedException, FileSystemLoopException, NotLinkExcepti
				fsfail(e, CustomError(switch e.getReason() {
					case null: e.toString();
					case v: v;
				}));
      }
			catch (e:ClosedChannelException) iofail(e, BadFile)// TODO: check that's the right error
			catch (e:java.io.FileNotFoundException) iofail(e, FileNotFound)
			catch (e:java.lang.Throwable) new IoException(CustomError(e.toString()), null, e);// this also covers UnresolvedAddressException which probably should get a corresponding error type
  }
}