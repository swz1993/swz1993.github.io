① 界面上任何一个 View 的刷新请求最终都会走到 ViewRootImpl 中的 scheduleTraversals() 里来安排一次遍历绘制 View 树的任务。

② scheduleTraversals() 会先过滤掉同一帧内的重复调用，确保同一帧内只需要安排一次遍历绘制 View 树的任务，遍历过程中会将所有需要刷新的 View 进行重绘。

③ scheduleTraversals() 会往主线程的消息队列中发送一个同步屏障，拦截这个时刻之后所有的同步消息的执行，但不会拦截异步消息，以此来尽可能的保证当接收到屏幕刷新信号时可以尽可能第一时间处理遍历绘制 View 树的工作。

④ 发完同步屏障后 scheduleTraversals() 将 performTraversals() 封装到 Runnable 里面，然后调用 Choreographer 的 postCallback() 方法。

⑤ postCallback() 方法会先将这个 Runnable 任务以当前时间戳放进一个待执行的队列里，然后如果当前是在主线程就会直接调用一个native 层方法，如果不是在主线程，会发一个最高优先级的 message 到主线程，让主线程第一时间调用这个 native 层的方法。

⑥ native 层的这个方法是用来向底层订阅下一个屏幕刷新信号Vsync，当下一个屏幕刷新信号发出时，底层就会回调 Choreographer 的onVsync() 方法来通知上层 app。

⑦ onVsync() 方法被回调时，会往主线程的消息队列中发送一个执行 doFrame() 方法的异步消息。

⑧ doFrame() 方法会去取出之前放进待执行队列里的任务来执行，取出来的这个任务实际上是 ViewRootImpl 的 doTraversal() 操作。

⑨ doTraversal()中首先移除同步屏障，再会调用performTraversals() 方法根据当前状态判断是否需要执行performMeasure() 测量、perfromLayout() 布局、performDraw() 绘制流程，在这几个流程中都会去遍历 View 树来刷新需要更新的View。

⑩ 等到下一个Vsync信号到达，将上面计算好的数据渲染到屏幕上,同时如果有必要开始下一帧的数据处理。
