
## HashSet

此类由一个哈希表(实际上是一个HashMap实例)支持。 不保证元素的顺序，特别是，它不保证顺序随着时间的推移保持不变。该集合没有重复的元素并且允许使用null元素。该类为基本操作（add()、remove()、contains()和size()）提供恒定的时间性能，假设散列函数在桶之间正确地分散元素。 迭代此集合需要的时间与HashSet实例的大小（元素数量）加上后备HashMap实例的“容量”（桶数）之和成比例。 因此，如果迭代性能很重要，则不要将初始容量设置得太高（或负载因子太低）。另外，跟之前分析的其他集合类一样，它是非同步的。

### 定义及说明

定义如下：

```
public class HashSet<E> extends AbstractSet<E> 
       implements Set<E>, Cloneable, java.io.Serializable{}
```

1、继承了AbstractSet并实现了Set接口，即拥有Set基本的方法和属性

2、实现了Cloneable，即支持clone

3、实现了java.io.Serializable，即支持序列化和反序列化

构造函数如下：

```
private transient HashMap<E,Object> map;

//构造一个新的空HashSet，底层HashMap实例的具有默认初始容量(16)和加载因子(0.75)
public HashSet() {
        map = new HashMap<>();
    }

//构造一个包含指定集合中元素的新HashSet。 使用默认加载因子(0.75)创建HashMap，初始容量要求足以包含指定集合中的元素
public HashSet(Collection<? extends E> c) {
        map = new HashMap<>(Math.max((int) (c.size()/.75f) + 1, 16));
        addAll(c);
    }

//构造一个空的新HashSet，底层HashMap具有指定的初始容量和加载因子
public HashSet(int initialCapacity, float loadFactor) {
        map = new HashMap<>(initialCapacity, loadFactor);
    }

//构造一个新的空HashSet，底层HashMap实例具有指定的初始容量和默认加载因子(0.75)
public HashSet(int initialCapacity) {
        map = new HashMap<>(initialCapacity);
    }

//构造一个新的空HashSet。(此包私有构造函数仅由LinkedHashSet使用)。底层HashMap实例是具有指定初始容量和指定加载因子的LinkedHashMap。
HashSet(int initialCapacity, float loadFactor, boolean dummy) {
        map = new LinkedHashMap<>(initialCapacity, loadFactor);
    }
```

我们发现，其实实例化一个HashSet的本质就是实例化一个HashMap，所以说，HashSet是由HashMap支持的。这里第二个构造函数中，有一个计算"Math.max((int) (c.size()/.75f) + 1, 16)"，这是因为HashMap的大小必须是2的指数倍，通过"c.size()/.75f"计算出来的实际大小跟16相比，如果小于16，就直接使用16作为初始大小，避免一些重复的计算。

### 源码简析

我们看一下它的一些基本方法：

```
//与底层Map中的Object关联的虚拟值
private static final Object PRESENT = new Object();

//返回此set中元素的迭代器
public Iterator<E> iterator() {
        return map.keySet().iterator();
    }

//获取大小
public int size() {
        return map.size();
    }

//判空
public boolean isEmpty() {
        return map.isEmpty();
    }

//判断是否包含指定元素
public boolean contains(Object o) {
        return map.containsKey(o);
    }

//添加元素
public boolean add(E e) {
        return map.put(e, PRESENT)==null;
    }

//删除元素
public boolean remove(Object o) {
        return map.remove(o)==PRESENT;
    }

//清空集合
public void clear() {
        map.clear();
    }
```

我们可以看到，他所有的基本方法都是通过调用HashMap对应的方法来实现的，它的元素就是底层HashMap的key，而底层HashMap的值都是一个Object类型的PRESENT对象。

## LinkedHashSet

Set接口的哈希表和链表实现，具有可预测的迭代顺序。此实现与HashSet的不同之处在于它维护了一个贯穿其所有条目的双向链表。此链接列表定义迭代排序，即元素插入集合(插入顺序)的顺序。请注意，如果将元素重新插入到集合中，则不会影响插入顺序。（如果s.contains(e)在调用之前立即返回true，则在调用s.add(e)时，将元素e重新插入到集合中）。该集合允许使用null元素，且该集合是非同步的。

### 定义及说明

定义如下:

```
public class LinkedHashSet<E>
    extends HashSet<E>
    implements Set<E>, Cloneable, java.io.Serializable {}
```

1、它是继承了HashSet并实现了Set接口，所以具有Set基本的方法和属性

2、实现了Cloneable，即支持clone

3、实现了java.io.Serializable，即支持序列化和反序列化

构造方法有：

```
//使用指定的初始容量和加载因子构造一个新的空LinkedHashSet
public LinkedHashSet(int initialCapacity, float loadFactor) {
        super(initialCapacity, loadFactor, true);
    }

//使用指定的初始容量和默认加载因子（0.75）构造一个新的空链式哈希集LinkedHashSet
public LinkedHashSet(int initialCapacity) {
        super(initialCapacity, .75f, true);
    }

//使用默认初始容量（16）和加载因子（0.75）构造一个新的空LinkedHashSet
public LinkedHashSet() {
        super(16, .75f, true);
    }

//构造一个新的LinkedHashSet，其具有与指定集合相同的元素。 创建链接的哈希集的初始容量足以容纳指定集合中的元素，具有默认加载因子（0.75）
public LinkedHashSet(Collection<? extends E> c) {
        super(Math.max(2*c.size(), 11), .75f, true);
        addAll(c);
    }
```

我们可以发现，它其实就是通过调用HashSet的构造方法来进行实例化。它和HashSet的区别就在于LinkedHashSet的元素是按照放入顺序进行排列。并且LinkedHashSet内部使用LinkedHashMap实现。

其他方法：

```
@Override
    public Spliterator<E> spliterator() {
        return Spliterators.spliterator(this, Spliterator.DISTINCT | Spliterator.ORDERED);
    }
```

它只重写了HashSet的spliterator()方法(这个方法后期分析)。

## TreeSet

基于TreeMap的NavigableSet实现。元素使用其可比较的自然顺序或在创建时创建时提供的Comparator进行排序，具体取决于使用的构造函数。它的基本操作(add、remove、和contains)的时间复杂度为log(n)。当然，它也是非同步的，不过**不支持null元素**。

### 定义及说明

定义如下：

```
public class TreeSet<E> extends AbstractSet<E>
    implements NavigableSet<E>, Cloneable, java.io.Serializable{}
```

1、继承与AbstractSet，实现了NavigableSet接口，即拥有Set的基本的方法和属性。其元素使用其可比较的自然顺序，或者通过在创建时提供的Comparator进行排序。

2、实现了Cloneable，即支持clone

3、实现了java.io.Serializable，即支持序列化和反序列化

构造函数：

```
//底层映射
private transient NavigableMap<E,Object> m;

//构造由指定的可导航映射支持的TreeSet
 TreeSet(NavigableMap<E,Object> m) {
        this.m = m;
    }

//构造一个新的空TreeSet，根据其元素的自然顺序进行排序。 插入集合中的所有元素都必须实现Comparable接口。 此外，所有这些元素必须是可相互比较的
public TreeSet() {
        this(new TreeMap<E,Object>());
    }

//构造一个新的空TreeSet，根据指定的比较器进行排序。 插入到集合中的所有元素必须通过指定的比较器相互比较
public TreeSet(Comparator<? super E> comparator) {
        this(new TreeMap<>(comparator));
    }

//构造一个新的TreeSet，其中包含指定集合中的元素，并根据其元素的自然顺序进行排序。 插入集合中的所有元素都必须实现Comparable接口
public TreeSet(Collection<? extends E> c) {
        this();
        addAll(c);
    }

//构造一个包含相同元素并使用与指定有序集相同排序的新TreeSet
public TreeSet(SortedSet<E> s) {
        this(s.comparator());
        addAll(s);
    }

```
可以看出，TreeSet是基于TreeMap实现的。在addAll()方法中，其实也是调用了TreeMap进行元素的添加。

### 源码简析

再看一下一些基本的方法：

```
private static final Object PRESENT = new Object();

public boolean isEmpty() {
        return m.isEmpty();
    }

public boolean contains(Object o) {
        return m.containsKey(o);
    }


public boolean add(E e) {
        return m.put(e, PRESENT)==null;
    }

public boolean remove(Object o) {
        return m.remove(o)==PRESENT;
    }

public void clear() {
        m.clear();
    }
```

它也是通过调用Map的相关的方法，来实现功能。它的元素就是底层Map的key，而底层Map的值都是一个Object类型的PRESENT对象。

## 小结

好了，到这就分析完了，总结一下：

Set集合中，不允许有重复的元素。且Set对两个元素的比较不是使用"=="而是使用"equals"。HashSet和TreeSet是根据元素的自然顺序或者构建时传入的Comparator比较器对元素进行排序，而LinkedHashSet是根据元素的插入顺序进行排序。HashSet和LinkedHashSet允许有null元素，但是TreeSet不允许。