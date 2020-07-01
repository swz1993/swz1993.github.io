## 1、Synchronized及其实现原理

#### 1.1、Synchronized 修饰对象

synchronized所覆盖的代码块的首尾部分分别加上了monitorenter和monitorexit。
JVM中对于上述两条指令的解释如下：

+ monitorenter：每一个对象有一个相关联的监视器(monitor)，当monitor被占用时便被锁
定住。当执行monitorenter执行时，当前线程尝试获取monitor：

 + 如果当前monitor的进入数为0，则说明monitor未被占用，则当前线程占有该monitor，
 同时monitor的进入数变为1
 + 如果当前monitor进入数不为0，且monitor的占用者是当前线程，则可以重复占用该
 monitor，同时进入数加1
 + 如果其他线程占有了该monitor，则线程进入阻塞状态，直到monitor的进入数重新变为0，
 再重新尝试获取所有权

+ monitorexit:执行monitorexit的线程必须是objectref所对应的monitor的所有者
  + 指令执行时，monitor的进入数减1，如果减1后进入数为0，那线程退出monitor，不再是
  这个monitor的所有者。其他被这个monitor阻塞的线程可以尝试去获取这个 monitor 的
  所有权

#### 1.2、Synchronized 修饰方法

方法的同步并没有通过指令monitorenter和monitorexit来完成（理论上其实也可以通过这两
条指令来实现），不过相对于普通方法，其常量池中多了 **ACC_SYNCHRONIZED** 标示符。
JVM就是根据该标示符来实现方法的同步的：当方法调用时，调用指令将会检查方法的
 ACC_SYNCHRONIZED 访问标志是否被设置，如果设置了，执行线程将先获取monitor，
 获取成功之后才能执行方法体，方法执行完后再释放monitor。在方法执行期间，其他任何
 线程都无法再获得同一个monitor对象。

 通过上述解释，相信大家已经知道Synchronized是如何保证互斥性的，那么其是怎么实现可
 见性和顺序性的呢？其实也跟monitor相关：

 + 可见性：执行到monitorenter时，线程会重新从主内存中将数据同步到本地工作内存，从
 而保证其可以看到其他线程的修改。同时执行monitorexit时，线程也会将本地工作内存的数
 据同步到主内存中
 + 有序性：monitorenter、monitorexit修饰的代码将禁止进行重排序


## 2、volatile的原理

#### 2.1、可见性

 对volatile变量的写操作与普通变量的主要区别有两点：

 + 修改volatile变量时会强制将修改后的值刷新的主内存中
 + 修改volatile变量后会导致其他线程工作内存中对应的变量值失效。因此，再读取该变量值的时候就需要重新从读取主内存中的值。

 通过这两个操作，就可以解决volatile变量的可见性问题。

#### 2.2、原子性

 volatile只能保证对单次读/写的原子性。因为long和double两种数据类型的操作可分为高32位和低32位两部分，因此普通的long或double类型读/写可能不是原子的。因此，鼓励大家将共享的long和double变量设置为volatile类型，这样能保证任何情况下对long和double的单次读/写操作都具有原子性。

#### 2.3、顺序性

 在解释这个问题前，我们先来了解一下Java中的happen-before规则：如果a happen-before b，则a所做的任何操作对b是可见的。

 JSR 133中定义的happen-before规则有：

 + 同一个线程中的，前面的操作 happen-before 后续的操作。（即单线程内按代码顺序执行。但是，在不影响在单线程环境执行结果的前提下，编译器和处理器可以进行重排序，这是合法的。换句话说，这一是规则无法保证编译重排和指令重排）
 + 监视器上的解锁操作 happen-before 其后续的加锁操作。（Synchronized 规则）
 + 对volatile变量的写操作 happen-before 后续的读操作。（volatile 规则）
 + 线程的start() 方法 happen-before 该线程所有的后续操作。（线程启动规则）
 + 线程所有的操作 happen-before 其他线程在该线程上调用 join 返回成功后的操作
 + 如果 a happen-before b，b happen-before c，则a happen-before c（传递性）

#### 2.4 内存屏障

 为了实现volatile可见性和happen-befor的语义。JVM底层是通过一个叫做“内存屏障”的东西来完成。内存屏障，也叫做内存栅栏，是一组处理器指令，用于实现对内存操作的顺序限制，其中包括：

 + LoadLoad 屏障

> 执行顺序：Load1—>Loadload—>Load2

确保Load2及后续Load指令加载数据之前能访问到Load1加载的数据。

 + StoreStore 屏障

> 执行顺序：Store1—>StoreStore—>Store2

确保Store2以及后续Store指令执行前，Store1操作的数据对其它处理器可见。

+ LoadStore 屏障

> 执行顺序： Load1—>LoadStore—>Store2

确保Store2和后续Store指令执行前，可以访问到Load1加载的数据。

+ StoreLoad 屏障

执行顺序: Store1—> StoreLoad—>Load2

确保Load2和后续的Load指令读取之前，Store1的数据对其他处理器是可见的。
