<map>
		<node ID="root" TEXT="2、JVM内存区域及内存溢出异常">		<node TEXT="1、运行时数据区" ID="30c169d9130e1a0e2" STYLE="bubble" POSITION="right">
		<node TEXT="Java虚拟机在执行Java的过程中，会把它所管理的内存划分为若干个不同的数据区域。" ID="27b169d9138cad0d3" STYLE="fork">
		<node TEXT="线程私有" ID="1f7169d917434207d" STYLE="fork">
		<node TEXT="程序计数器" ID="31169d913c2521" STYLE="fork">
		<node TEXT="程序计数器是一块较小的内存空间，它可以看作是当前线程所执行的字节码的行号指示器，字节码解释器工作时就是通过改变这个计数器的值来选取下一条要执行的字节码指令，分支、循环、跳转、异常处理及线程恢复等功能都需要依赖这个计数器来完成。" ID="204169d9143fc50c2" STYLE="fork">
		</node>
		<node TEXT="由于Java虚拟机是痛过线程轮流切换并分配持利器执行时间的方式来实现的，因此，为了线程切换后能恢复到正确的位置，每条线程都需要一个独立的程序计数器，各条线程之间计数器互不影响，独立存储，我们将这类内存区域称为线程私有的内存。" ID="d2169d9145c2b1181" STYLE="fork">
		</node>
		<node TEXT="如果线程正在执行的是一个Java方法，这个计数器记录的是正在执行的虚拟机字节码指令；如果正在执行的是Native方法，这个计数器值为空。此内存区域是唯一一个在Java虚拟机规范中没有规定任何OutOfMemoryError情况的区域" ID="2c4169d914fb050d4" STYLE="fork">
		</node>
		</node>
		<node TEXT="Java虚拟机栈" ID="45169d916f3e8137" STYLE="fork">
		<node TEXT="生命周期与线程相同，它描述的是Java方法执行的内存模型：每个方法在执行的同时都会创建一个栈帧用于存储局部变量表、操作数栈、动态链接、方法出口等信息。每个方法从调用到执行完毕就对应一个栈帧在虚拟机中入栈到出栈的过程" ID="26d169d917213e" STYLE="fork">
		</node>
		<node TEXT="我们常说的堆栈中的栈就是虚拟机栈" ID="7c169d91b03d310a" STYLE="fork">
		</node>
		<node TEXT="局部变量表存放了编译器可知的各种基本数据类型、对象引用和returnAddress(指向了一条字节码指令的地址)。其中64位长度的long和double类型的数据会占用2个局部变量空间，其余的数据类型占用1位局部变量表所需的内存空间在编译时期完成分配，方法运行期间不会改变局部变量表的大小" ID="253169d91b54b217" STYLE="fork">
		</node>
		<node TEXT="Java虚拟机规范中，对这个区域规定了两种异常状况：如果线程请求的栈深度大于虚拟机所允许的深度，将抛出StackOverflowError异常；如果虚拟机可以动态扩展，但扩展时无法申请到足够的内存，就会抛出OutOfMemoryError异常" ID="7169d91f8146054" STYLE="fork">
		</node>
		</node>
		<node TEXT="本地方法栈" ID="1d2169d923cdea14f" STYLE="fork">
		<node TEXT="与虚拟机栈发挥的作用相似，不同的是虚拟机栈为虚拟机执行Java方法(也就是字节码)服务，而本地方法栈则为虚拟机使用到的Netive方法服务。与虚拟机栈一样，本地方法栈也会抛出StackOverflowError和OutOfMemoryError异常" ID="3b2169d923f1c311f" STYLE="fork">
		</node>
		</node>
		</node>
		<node TEXT="线程共享" ID="2ad169d9265d97002" STYLE="fork">
		<node TEXT="Java堆" ID="26b169d926a6bb17d" STYLE="fork">
		<node TEXT="对于大多数应用来说，Java堆(Java Heap)是Java虚拟机所管理的内存中最大的一块。" ID="1aa169d926dadb072" STYLE="fork">
		</node>
		<node TEXT="在Java虚拟机启动的时候创建，此内存唯一的目的是存放对象的实例。在Java虚拟机规范中的描述是：所有对象的实例及数组都要在堆上分配。但随着JIT编译器的发展与逃逸分析技术的逐渐成熟，就不是那么绝对了" ID="180169d927d28c065" STYLE="fork">
		</node>
		<node TEXT="Java堆是垃圾收集器管理的主要区域，因此很多时候也被称为“GC堆”。从内存回收的角度上看，由于现在的收集器基本都是采用分代算法，所有Java堆还可以分为：新生代和老年代。再细致点有Eden空间、From Survivor空间和To Survivor空间等。" ID="338169d92b504c011" STYLE="fork">
		</node>
		<node TEXT="从内存分配的角度上看，线程共享的Java堆中可以划分出很多线程私有的分配缓冲区。Java堆可以处于物理上不连续的内存空间中，只要逻辑上是连续的即可" ID="249169d92eac1309c" STYLE="fork">
		</node>
		</node>
		<node TEXT="方法区" ID="205169d9309cbd085" STYLE="fork">
		<node TEXT="存储已被虚拟机加载的类信息、常量、静态变量和即时编译器编译后的代码等数据。" ID="3b6169d930cb1e071" STYLE="fork">
		</node>
		<node TEXT="此空间除了和Java堆一样不需要连续的内存和可以选择固定大小或者可扩展外，还可以选择不实现垃圾收集。但并不是数据进了方法去就永久存在了，这个区域的内存回收目标主要是针对常量池的回收和对类型的卸载。" ID="2ab169d932616c121" STYLE="fork">
		</node>
		<node TEXT="当方法区无法满足内存分配的需要时，将抛出OutOfMemoryError异常" ID="216169d935aa69066" STYLE="fork">
		</node>
		</node>
		<node TEXT="运行时常量池" ID="22f169d9362730052" STYLE="fork">
		<node TEXT="方法区的一部分，Class文件中除了有类的版本、字段、方法和接口等描述信息外，还有一项信息是常量池，用于存放编译期生成的各种字面量和符号引用，这部分内容将在类加载后进入方法区的运行时常量池中存放。" ID="33f169d9364321111" STYLE="fork">
		</node>
		<node TEXT="一般来说，除了保存Class文件中描述的符号引用外，还会把翻译出来的直接引用也存储在运行时常量池中" ID="18f169d93930ee137" STYLE="fork">
		</node>
		<node TEXT="运行时常量池对于Class常量池的另外一个重要特征是具备动态性，运行期间也可能将新的常量放入池中，比如String类的intern()方法" ID="12f169d93a265b093" STYLE="fork">
		</node>
		<node TEXT="会抛出OutOfMemoryError异常" ID="3cf169d93bd015164" STYLE="fork">
		</node>
		</node>
		</node>
		<node TEXT="直接内存" ID="11b169d93bf987124" STYLE="fork">
		<node TEXT="不是Java虚拟机规范中定义的部分，但是使用频繁且也可能抛出OutOfMemoryError异常" ID="347169d93c0a900d6" STYLE="fork">
		</node>
		<node TEXT="在JDK1.4中新加入了NIO(New Input/Output)类，引入了一种基于通道与缓冲区的I/O方式，它可以使用Native函数库直接分配堆外内存，然后通过一个存储在Java堆中的DirectByteBuffer对象那个作为这块内存的引用进行操作。" ID="b0169d93dcb3207e" STYLE="fork">
		</node>
		<node TEXT="本地直接内存不受Java堆大小饿限制，但是受到本机总内存大小及处理器寻址空间的限制" ID="2f7169d940be7515c" STYLE="fork">
		</node>
		</node>
		</node>
		</node>
		<node TEXT="2、HotSpot虚拟机对象探秘" ID="63169de28e2f907f" STYLE="bubble" POSITION="right">
		<node TEXT="HotSpot虚拟机是Sun JDK和OpenJDK中所带的虚拟机，也是目前使用范围最广的Java虚拟机" ID="3d7169de298463126" STYLE="fork">
		<node TEXT="对象的创建" ID="7169de2cae5c0fc" STYLE="fork">
		<node TEXT="划分可用空间" ID="68169de3d72790b7" STYLE="fork">
		<node TEXT="虚拟机遇到一条new指令时，首先去检查这个指令参数是否能在常量池中定位到一个类的符号引用，并检查这个符号引用代表的类是否已被加载、解析和初始化过。如果没有，则必须先执行相应的类加载过程。" ID="2cf169de2cd23209d" STYLE="fork">
		</node>
		<node TEXT="在类加载检查通过后，接下来虚拟机为新生的对象分配内存。对象那个所需的内存在类加载完成后就可以完全确定。为对象分配内存就是从Java堆中划出一块确定大小的内存" ID="d5169de2fbe6e025" STYLE="fork">
		<node TEXT="假设Java堆内存是绝对规整的，用到的和空闲的内存各占一边，中间放着一个指针作为分界点的指示器。那么分配内存仅仅是把指针往空闲的那边挪动与对象大小相等的距离，这种分配方式叫做指针碰撞" ID="124169de32205c044" STYLE="fork">
		</node>
		<node TEXT="如果Java内存堆不是规整的，那么虚拟机就必须维护一个列表，记录可以使用的内存，在分配的时候从列表中找到一块足够大的空间划分给对象实例，并更新表上的记录，这种分配方式叫做空闲列表" ID="2a7169de3736ec16e" STYLE="fork">
		</node>
		<node TEXT="Java堆是否规则取决于所采用的垃圾收集器是否有压缩整理的功能。例如，在使用Serial、ParNew等带Compact过程的垃圾收集器时，采用的是指针碰撞；而使用CMS这种基于Mark-Sweep算法的收集器时，采用的是空闲列表" ID="191169de3ae1e70fc" STYLE="fork">
		</node>
		<node TEXT="分配内存时的线程安全问题" ID="198169de3de9f4168" STYLE="fork">
		<node TEXT="Java创建对象在并发的情况下并不是线程安全的，可能出现给A分配内存后指针还没来得及修改就又给B使用原来的指针分配内存的情况。解决这个问题有两个方案" ID="13169de3eb2d807a" STYLE="fork">
		<node TEXT="对分配内存空间的动作进行同步处理：实际上虚拟机采用CAS配上失败重试的方式保证更新操作的原子性" ID="149169de409da1102" STYLE="fork">
		</node>
		<node TEXT="把内存分配的动作按照线程划分在不同的空间进行，即每个线程在Java堆中预先分配一小块内存，称为本地线程分配缓冲(TLAB)。那个线程要分配内存，就在那个TLAB上进行。只有在TLAB用完并分配新的TLAB时才同步锁定" ID="2cf169de4217000a1" STYLE="fork">
		</node>
		</node>
		</node>
		</node>
		<node TEXT="内存分配完成后，虚拟机将分配到的内存空间初始化为零值(不包括对象头)，如果使用TLAB，这一工作可以提前到TLAB分配时进行。此操作保证了对象的实例字段在Java代码中不赋初值就可以使用，程序可以访问到这些对象的零值" ID="342169de45845402a" STYLE="fork">
		</node>
		<node TEXT="接下来，虚拟机对对象进行必要的设置，例如这个对象是哪个类的实例、如何才能找到类的元数据信息、对象的哈希码及对象的GC分代年龄等信息。这些信息存放在对象头中" ID="30b169de4903ee074" STYLE="fork">
		</node>
		<node TEXT="至此，从虚拟机的角度上，一个新的对象产生了。但对于Java程序的视角来说，还需要执行init方法，一般来说，执行new之后会执行init方法，把对象按照程序员的意愿做初始化" ID="1e5169de4b0619118" STYLE="fork">
		</node>
		</node>
		</node>
		<node TEXT="对象的内存布局" ID="1b2169de4e509b0ad" STYLE="fork">
		<node TEXT="在HotSpot虚拟机中，对象在内存中存储的布局分为三块区域：" ID="a8169de4edc4b0a1" STYLE="fork">
		<node TEXT="对象头" ID="241169de4f99e20b6" STYLE="fork">
		<node TEXT="Mark Word" ID="154169de50529d05f" STYLE="fork">
		<node TEXT="用于存储对象自身的运行时数据，如哈希码、GC分代年龄、锁状态标志、对象持有的锁、偏向锁id及偏向时间戳等。考虑到虚拟机的空间效率，Mark Word被设计成一个非固定的数据结构以便在极小的空间存储更多的信息，他会根据对象的状态复用自己的存储空间" ID="1f1169de5096d0145" STYLE="fork">
		</node>
		</node>
		<node TEXT="类型指针" ID="52169de543b4c009" STYLE="fork">
		<node TEXT="对象指向它类元数据的指针，虚拟机通过这个指针来确定对象是那个类的实例，但是，查找对象的元数据信息并不一定要经过对象本身。如果对象是一个Java数组，那么对象头中还必须有一块记录数组长度的数据，因为虚拟机无法从数组的元数据中确定数组的大小" ID="2db169de548910067" STYLE="fork">
		</node>
		</node>
		</node>
		<node TEXT="实例数据" ID="1d169de4fb4ae174" STYLE="fork">
		<node TEXT="对象真正存储的有效信息，即在程序代码中定义的各种类型的字段内容。存储顺序受虚拟机分配策略参数和字段在Java源码中定义的顺序有关。HopSpot中的分配策略为long/double、ints、short/chars、bytes/booleans、oops，可以看出，相同宽度的字段被分配到一起，满足这个条件的前提下，父类定义的变量会出现在子类的前面。如果CompactFields为true(默认为true)，那么子类较窄的变量也可能会插入到父类变量的空隙中。" ID="a7169de57331c154" STYLE="fork">
		</node>
		</node>
		<node TEXT="对其填充" ID="348169de4fca3811a" STYLE="fork">
		<node TEXT="并不是必须要存在的，也没有什么含义，只是起占位符的作用。由于HotSpot要求对象起始地址必须是8字节的整数倍，即对象大小必须是8字节的整数倍。而对象头正好是8字节的倍数(1或2倍)，因此，实例部分的数据没有对其时，就需要对其填充补全" ID="27e169de5ce2d217a" STYLE="fork">
		</node>
		</node>
		</node>
		</node>
		<node TEXT="对象的访问定位" ID="39616a0251961309d" STYLE="fork">
		<node TEXT="Java程序需要通过栈上的reference数据来操作堆上的具体对象。对象的访问方式是取决于虚拟机实现的，目前主流的访问方式有使用具柄和直接访问两种" ID="a416a025271030b4" STYLE="fork">
		<node TEXT="使用具柄" ID="21116a02548ad0092" STYLE="fork">
		<node TEXT="Java堆会分出一块作为句柄池，reference中存储的就是对象的句柄地址，而具柄中包含对象的实例数据和类型数据的具体地址信息" ID="20816a0254b34001e" STYLE="fork">
		</node>
		</node>
		<node TEXT="直接指针" ID="df16a025671df01f" STYLE="fork">
		<node TEXT="Java堆的布局中必须考虑如何放置访问类型数据的相关信息，而reference中存放的直接就是对象地址" ID="24a16a02569e8a0c3" STYLE="fork">
		</node>
		</node>
		<node TEXT="使用句柄访问的好处是：reference中存储的是稳定的句柄地址，在对象被移动(垃圾收集时对象被移动)时只会改变句柄中的实例数据指针，而reference本身不做修改" ID="33b16a0257c37707e" STYLE="fork">
		</node>
		<node TEXT="使用直接指针访问的好处：速度快，节省了一次指针定位的时间开销，在HotSopt中就是使用这种方式" ID="30116a025944b6136" STYLE="fork">
		</node>
		</node>
		</node>
		</node>
		</node>
		<node TEXT="3、实战：OutOfMemoryError异常" ID="39516a025b398c0b7" STYLE="bubble" POSITION="left">
		<node TEXT="除了程序计数器之外，虚拟机内存的其他几个运行时区域都会发生次异常" ID="21916a025bbfb105a" STYLE="fork">
		<node TEXT="Java堆溢出" ID="11916a025c92fa149" STYLE="fork">
		<node TEXT="当Java堆内存出现溢出时，异常堆栈信息&quot;java.lang.OutOfMemaryError&quot;会跟着进一步的提示&quot;Java heap space&quot;" ID="b16a025ca8ed0c9" STYLE="fork">
		</node>
		<node TEXT="要处理此处的异常，一般是通过内存印象分析工具，对Dump出的堆转储快照进行分析，分清楚是出现了内存泄漏还是内存溢出。如果是内存泄漏，可进一步通过工具查看泄漏对象到GC Roots的引用链，这样就能找到泄漏对象的内存信息及其引用链，进而找到内存泄漏的代码位置。如果不存在泄漏，那就检查虚拟机的堆参数与计算机物理内存对比是否可以调大，从代码上检查是否存在某些对象是否生命周期过长、持有状态时间过长，尝试减少程序运行时期的内存消耗" ID="35d16a025e9db102e" STYLE="fork">
		</node>
		</node>
		<node TEXT="虚拟机栈和本地方法栈溢出" ID="1a216a026531aa0ff" STYLE="fork">
		<node TEXT="Java虚拟机中描述了两种异常：1、如果线程请求的栈深度大于虚拟机所允许的最大深度，抛出StackOverflowError；2、如果虚拟机在扩展栈时无法申请到足够的内存空间，抛出OutOfMemaryError异常。在单线程下，无论是栈帧太大还是虚拟机容量太小，当内存无法分配时，虚拟机抛出的都是StackOverflowError。如果是建立过多的线程导致内存溢出，在不能减少线程数或者更换64位虚拟机的情况下，就只能通过减少最大堆和减少栈容量来换取更多的线程。" ID="1f416a026580330ab" STYLE="fork">
		</node>
		</node>
		<node TEXT="方法区和运行时常量池溢出" ID="31216a026c4d2608b" STYLE="fork">
		<node TEXT="运行时常量池溢出，在OutOfMemaryError后面会跟随的提示信息是&quot;PermGen space&quot;，说明运行时常量池属于方法区的一部分。" ID="1b516a026c8ee617" STYLE="fork">
		</node>
		</node>
		<node TEXT="本地直接内存溢出" ID="34716a02732b8d171" STYLE="fork">
		<node TEXT="特征是在Heap Dump文件中不会看到明显的异常。" ID="14916a02735115072" STYLE="fork">
		</node>
		</node>
		</node>
		</node>
</node>
</map>