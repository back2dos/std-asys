package asys.native.java;


@:forward(run)
abstract IsolatedRunner(TaskList) {
	inline function new(pool)
		this = new TaskList(pool);

	static public function create()
		return POOL.createRunner();

	static public final POOL:IsolatedRunnerPool = createPool();

	static public function createPool(size = 16):IsolatedRunnerPool {
		var pool = new Pool();

		for (i in 0...size)
			new Runner(pool);

		return () -> new IsolatedRunner(pool);
	}

	public function fork()
		return new IsolatedRunner(@:privateAccess this.pool);
}

abstract IsolatedRunnerPool(Null<()->IsolatedRunner>) from ()->IsolatedRunner {

	function create()
		return this();

	public function createRunner()
		return switch this {
			case null: IsolatedRunner.POOL.create();
			case v: v();
		}
}

private typedef Pool = java.util.concurrent.LinkedBlockingDeque.LinkedBlockingDeque<TaskList>;

private class Runner implements java.lang.Runnable {
	final pool:Pool;

	public function new(pool) {
		this.pool = pool;
		var t = new java.lang.Thread(this);
		t.setDaemon(true);
		t.start();
	}

	public function run() {
		while (true)
			pool.take().progress();
	}
}

private class TaskList {
	var alive = false;

	final tasks = [];
	final pool:Pool;

	public function new(pool) {
		this.pool = pool;
	}

	var counter = 0;
	public function run<X>(task:()->X, cb:haxe.Callback<haxe.Exception, X>) {
		final events = sys.thread.Thread.current().events;
		events.promise();
		java.Lib.lock(this, {
			var id = counter++;
			tasks.push(() ->
				try {
					var result = task();
					events.runPromised(() -> cb.success(result));
				}
				catch (e:java.lang.Throwable) {
					events.runPromised(() -> cb.fail(Errors.translate(e)));
				}
			);
			if (!alive) {
				alive = true;
				pool.add(this);
			}
		});
	}

	static function noop() {}

	public function progress() {
		var task = noop;
		java.Lib.lock(this, task = tasks.pop());
		task();
		java.Lib.lock(this, switch tasks.length {
			case 0:
				alive = false;
			default:
				pool.add(this);
		});
	}
}