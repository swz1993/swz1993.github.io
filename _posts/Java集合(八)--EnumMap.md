用于枚举类型键的专用Map实现。 TreeMap映射中的所有键必须来自创建映射时显式或隐式指定的单个枚举类型。 枚举映射在内部表示为数组。 枚举映射按其键的自然顺序（枚举常量的声明顺序）维护。 这反映在集合视图keySet()，entrySet()和values()返回的迭代器中。集合视图返回的迭代器非常一致：它们永远不会抛ConcurrentModificationException，它们可能会也可能不会显示出迭代进行过程中对映射所做的修改的而对其造成的影响。不允许使用空键，尝试插入空键将抛出NullPointerException。但是，测试是否存在空键或删除空键将正常运行，且允许空值。同大多数集合一样，EnumMap不是线程同步的。

## 定义及说明

定义如下：

```
public class EnumMap<K extends Enum<K>, V> extends AbstractMap<K, V>
    implements java.io.Serializable, Cloneable{}
```

1、继承了AbstractMap，即拥有Map基本的操作。

2、实现了java.io.Serializable，即可序列化和反序列化

3、实现了Cloneable，即支持clone

我们再看一下它的构造方法：

```
//此映射的所有键的枚举类型的Class对象
private final Class<K> keyType;

//包含在keyType中的所有枚举常量（用来缓存性能）
private transient K[] keyUniverse

//此映射的数组表示形式。
private transient Object[] vals;

//Map大小
private transient int size = 0;

//创建具有指定键类型的空枚举映射
public EnumMap(Class<K> keyType) {
        //指定此EnumMap的key的枚举类型的Class对象
        this.keyType = keyType;
        //返回包含在keyType中的所有值枚举常量
        keyUniverse = getKeyUniverse(keyType);
        //根据KeyType中的枚举常量的个数初始化vals数组
        vals = new Object[keyUniverse.length];
    }

//创建一个与m相同的Map
public EnumMap(EnumMap<K, ? extends V> m) {
        keyType = m.keyType;
        keyUniverse = m.keyUniverse;
        vals = m.vals.clone();
        size = m.size;
    }

//创建从指定Map初始化的枚举映射。 如果指定的映射是EnumMap实例，则此构造函数的行为与EnumMap（EnumMap）相同。 否则，指定的映射必须至少包含一个映射（以确定新的枚举映射的键类型）
public EnumMap(Map<K, ? extends V> m) {
        //判断是否为EnumMap类型
        if (m instanceof EnumMap) {
            EnumMap<K, ? extends V> em = (EnumMap<K, ? extends V>) m;
            keyType = em.keyType;
            keyUniverse = em.keyUniverse;
            vals = em.vals.clone();
            size = em.size;
        } else {
            //不是Enum类型
            if (m.isEmpty())
                throw new IllegalArgumentException("Specified map is empty");
            keyType = m.keySet().iterator().next().getDeclaringClass();
            keyUniverse = getKeyUniverse(keyType);
            vals = new Object[keyUniverse.length];
            putAll(m);
        }
    }
```

需要注意：

1、keyUniverse数组中包含的元素，是keyType枚举类型中所有的枚举常量。且vals数组长度与keyUniverse数组长度相同。

2、使用第三个构造函数创建EnumMap的时候，如果指定的映射是EnumMap实例，则此构造函数的行为与第二个构造函数相同。 否则，指定的Map中必须至少包含一个映射，用来确定新的枚举映射的键类型。

## 源码简析

老规矩，看put()方法：

```
public V put(K key, V value) {
		//检查key是不是正确类型
        typeCheck(key);
        //获取key在枚举常量的声明顺序(第几个声明的)
        int index = key.ordinal();
        //获取在当前index位置的值
        Object oldValue = vals[index];
        //判断value是否为空，并赋值
        vals[index] = maskNull(value);
        //判断oldValue是否为空，已确定是添加了元素，还是修改了值
        if (oldValue == null)
            //如果是添加了元素，则数组长度加1
            size++;
        //根据value的值判断value是否为空，并返回
        return unmaskNull(oldValue);
    }

//如果key不是此枚举集的正确类型，则引发异常
private void typeCheck(K key) {
        Class<?> keyClass = key.getClass();
        if (keyClass != keyType && keyClass.getSuperclass() != keyType)
            throw new ClassCastException(keyClass + " != " + keyType);
    }

//根据value是否为空给其赋值
private Object maskNull(Object value) {
        return (value == null ? NULL : value);
    }

//根据value的值判断其是否为空
@SuppressWarnings("unchecked")
    private V unmaskNull(Object value) {
        return (V)(value == NULL ? null : value);
    }
```

由上面的分析我们得出，假如i为数组keyUniverse的某个角标，则keyUniverse[i]在数组EnumMap中所对应的值为vals[i]。而且，EnumMap的键值对的映射是keyUniverse数组与vals数组中相同位置的元素的映射。

好了，本篇文章到此结束。