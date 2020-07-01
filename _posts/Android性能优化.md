## 1、布局优化

+ 减少布局文件的层级，使用性能较低的层级。
+ 采用<include>标签、<merger>标签（与<include>标签配合使用，减少层级）和ViewStub(使用 layout指定布局，并在setVisibility或者inflate后将其加载出来)。

## 2、绘制优化

+ onDraw 中不要创建新的局部对象，避免频繁调用时产生大量的临时对象
+ onDraw 中不要做耗时操作

## 内存泄漏优化

+ 静态变量导致的内存泄漏
+ 单例模式导致的内存泄漏
+ 属性动画导致的内存泄漏(有一类无限循环的动画，需要主动调用cancel才能停止)

## 响应速度优化

+ 避免在主线程中做耗时的操作

## ListView 和 Bitmap 优化

+ ListView：采用 ViewHolder 并且避免在 getView 中执行耗时操作；根据列表的滑动状态来控制任务的执行频率；尝试开启硬件加速
+ Bitmap：BitmapFactory.Options 来根据图片进行采样

## 线程优化

+ 采用线程池，避免程序中有大量的线程
