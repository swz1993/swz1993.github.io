经过十一篇文章的分析，终于把一些主要的集合类的实现原理分析完了。本文，我们将对之前分析的知识点做一次总结。

集合框架：集合有两个根接口，分别是Collection和Map。其中Collection中又分为List、Set和Queue。

[Java集合(一)--集合框架简析](https://www.jianshu.com/p/ce5983d2de7c)

##List

List是一中有序不唯一的元素集合，有ArrayList和LinkedList等多个实现类。

### ArrayList

ArrayList实现了RandomAccess等接口，支持快速随机访问。它是基于数组实现的，内部维护了一个默认初始容量为10的elementData数组。此数组是一个动态数组，在数组容量不足以容纳当前元素的时候会进行扩容，扩容到原数组的3/2，但是容量最大不超过0x7fffffff(是一个16进制的数，值为：2^31 - 1，是最大的int数值)。ArrayList的get和set方法都是通过操作角标完成对数组的操作，所以相对来说比较快。而add和remove方法，由于涉及到数组的拷贝，所以会比较慢。尤其是在add方法执行的过程中，如果当前数组容量不足以容纳元素，会进行扩容。所以，在知道最大容量的情况下，要给其一个初始容量值。

[Java集合(二)--ArrayList简析](https://www.jianshu.com/p/96aedb58d14c)

###  LinkedList

LinkedList实现了Deque等接口，可以当作双端队列来使用。它是基于私有的内部类Node完成的对数据的操作，而Node是一个双向链表类型的类，所以LinkedList是基于双向链表实现的。在Node中存储着上个节点和下个节点的信息以及当前节点的值。对于LinkedList来说，它的get和set方法执行过程中，会先将要操作的索引与(当前链表长度/2)做比较，以确定是从前往后遍历链表还是从后往前遍历链表，然后再执行相关的操作。而add和remove方法中，则是通过改变链表中节点指针的指向来完成操作。因此它是的特点是增删块，改查慢。LinkedList没有大小限制，可以无限扩容。

[Java集合(四)--LinkedList简析](https://www.jianshu.com/p/647d88f058ad)

>集合中，还有一种集合Vector，它是一个线程同步的集合。不过现在很少用它，现在不做具体分析了。之后，我们还会将线程同步的集合类，到时候，再将它们做比较。

##  Set

Set是一种无序且唯一的元素集合，对两个元素的比较不是使用"=="而是使用"equals"。它包含HashSet、TreeSet即EnumSet等等。

### HashSet

HashSet是基于HashMap实现的，它的构造函数的作用就是初始化一个HashMap对象。对其中元素的操作都是通过调用HashMap对应的方法完成的。HashSet的元素就是底层HashMap的key，而底层HashMap的value是一个Object类型的PRESENT对象。

[Java集合(九)--基于Map实现的Set简析](https://www.jianshu.com/p/ac4ad8eb9e8d)

### LinkedHashSet

LinkedHashSet是HashSet的子类，与其不同的是，LinkedHashSet维护了一个贯穿其所有条目的双向链表，链表中的元素按照其插入顺序排序，
且LinkedHashSet是基于LinkedHashMap实现的。

[Java集合(九)--基于Map实现的Set简析](https://www.jianshu.com/p/ac4ad8eb9e8d)

### TreeSet

TreeSet是基于TreeMap实现的，内部的元素通过其自然顺序或者是构建时传入的Comparator进行排序，它**不支持null元素**。它的构造方法就是实例化一个TreeMap对象，且对元素的操作都是通过调用TreeMap中的相关方法实现的。它的元素就是底层TreeMap的key，而底层TreeMap的value是一个Object类型的PRESENT对象。

[Java集合(九)--基于Map实现的Set简析](https://www.jianshu.com/p/ac4ad8eb9e8d)

### EnumSet

不同于上面的Set类，EnumSet不是基于Map实现的。它继承了Enum类，实现了AbstractSet等接口。EnumSet中的所有元素必须来自单个枚举类型，枚举集在其内部表示为位向量，即使用一个位表示一个元素的状态。它不允许有空值，但可以检测是否有空值。EnumSet元素按照在枚举类中的枚举常量的顺序进行排序，且在迭代过程中，不会出现fail-fast。

EnumSet是一个抽象类，以枚举类中是否包含64个枚举常量为分界线，EnumSet分别会实例化RegularEnumSet(小于等于64)和JumboEnumSet(大于64)两种EnumSet的实现类的对象来进行实际的操作。在RegularEnumSet中使用long类型的elements，通过其二进制表现形式上不同位的状态来表述数据是否存储。而JumboEnumSet则是维护了一个long类型的elements数组，具体操作原理同RegularEnumSet类似。

[Java集合(十一)--EnumSet简析](https://www.jianshu.com/p/3ea356ada37e)

## Map

Map是通过键值对的映射关系来存储数据的，它包含HashMap、TreeMap及EnumMap等多个实现类。

### HashMap

HashMap中是一个基于拉链法实现的散列表，内部由数组和链表实现。其中，数组用来通过索引确定键值对的位置，而链表则用来保存数据，包括key所对应的hash值(进过处理)，key、value和下个节点的地址。HashMap通过容量和加载因子来确定是否对数组扩容。其中，默认初始容量为16(容量的增长必须以2的次方式增长，且小于1<<30)，默认加载因子为0.75。加载因子其实就是控制是时间换空间，还是空间换时间。

HashMap在扩容的时候，会判断链表长度，单链表长度大于等于7的时候，会判断是扩容还是转为红黑树结构(判断依据是数组长度是否大于64)。而当链表长度小于6的时候，又会将红黑树转换为链表。

[Java集合(五)--HashMap简析](https://www.jianshu.com/p/1f16198a6285)

### LinkedHashMap

LinkedHashMap是HashMap的子类，与HashMap的不同的是它维护了一个贯穿其所有条目的双向链表。它通过布尔属性的accessOrder来决定迭代顺序，true为访问顺序，false为插入顺序。他在使用put或get等方法时，会判断如果是按照访问顺序排序，则会将刚刚操作的元素放到链表的尾部，这样就形成了一个简单的LRU。

[Java集合(十)--LinkedHashMap简析](https://www.jianshu.com/p/f7bb30e20af2)

### TreeMap

TreeMap是基于红黑树实现的，它的键根据自然顺序或者是创建时传入的Comparator进行排序，其key应该是实现了Comparable接口的对象。对其中的元素做增删操作后，需要对元素做修正，以保证还是红黑树结构。

[Java集合(六)--TreeMap简析](https://www.jianshu.com/p/30c6eb6d212b)

### WeakHashMap

WeakHashMap是一个带弱键的单链表的Map，与HashMap类似，他也是通过容量和加载因子来控制其扩容。当某个键不再正常使用的时候，对应的键值对就会被移除。这种操作是通过ReferenceQueue和Reference完成的。其原理为，当WeakHashMap的某个键被GC时，该键会被添加到queue中。然后，在执行某个操作的过程中，会先去删除与queue中对应的元素，接着再去执行相应的操作。

[Java集合(七)--WeakHashMap简析](https://www.jianshu.com/p/a9c9efe35097)

### EnumMap

EnumMap是用于枚举类型键的专用Map实现。其映射中的所有键必须来自创建映射时显式或隐式指定的单个枚举类型，枚举映射在内部表示为数组。 EnumMap的键按其键的自然顺序（枚举常量的声明顺序）维护，且在迭代过程中，不会出现fail-fast。EnumMap**不允许使用空键**，但是，可以测试是否存在空键或删除空键，且允许空值。它内部维护了keyUniverse和vals两个数组。其中，keyUniverse数组中包含的元素，是指定的枚举类型中所有的枚举常量。vals数组长度与keyUniverse数组长度相同，且EnumMap的键值对的映射是keyUniverse数组与vals数组中相同位置的元素的映射。

[Java集合(八)--EnumMap简析](https://www.jianshu.com/p/9e52982e8551)

>还有一个HashTable，它继承自Dictionary类，是同步的。

