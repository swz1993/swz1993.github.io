---
layout: post
title:  "Java集合(一) -- ArrayList"
date:   2018-05-24 21:03:36 +0530
description: ArrayList
categories: Java
---

通过上一章的内容，我们简单了解了集合的框架。从本章开始，我们将开始分析集合的具体的实现类。我们先从简单的开始，比如ArrayList(这么说，ArrayList会不会不高兴？)。

## ArrayList的定义

先看一下ArrayList的定义：

```java
public class ArrayList<E> extends AbstractList<E>
        implements List<E>, RandomAccess, Cloneable, java.io.Serializable
{}
```

具体分析一下：

1、继承了AbstractList，实现了List接口，即拥有List基本的添加、删除及修改等等。并且部分方法因为继承了AbstractList，所以也无需重写。

2、实现了RandomAccess接口，RandomAccess支持快速（通常是恒定时间）随机访问。所以，ArrayList也支持快速的随机访问。

3、实现了Cloneable接口，即支持clone。

4、实现了Serializable接口，即可以序列化，可以通过序列化去传输数据。

注意，ArrayList是有大小的，随着列表中元素的增加，它会自动扩容。ArrayList不是线程安全的，如果多个线程同时访问ArrayList的实例，并且至少有一个线程在结构上修改了列表，则必须在外部同步。

接下来，我们就通过源码，一步步分析一下ArrayList。

### ArrayList的源码简析

首先，是ArrayList的创建。它提供了三个构造函数：

```java
//构造具有指定初始容量的空列表,初始容量可以理解为initialCapacity。
public ArrayList(int initialCapacity) {}

//构造一个初始容量为10的空列表
public ArrayList() {}

//构造一个包含指定集合元素的列表
public ArrayList(Collection<? extends E> c) {}
```

在这里，我们从无参的构造函数入手分析。在调用了无参构造函数后，会执行以下代码：

```java
this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
```

嗯？this.elementData是个啥？DEFAULTCAPACITY_EMPTY_ELEMENTDATA又是什么鬼？赶紧去属性声明的地方看一下。

```java
transient Object[] elementData;

private static final Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = {};
```

哦，就是初始化了一个空的数组。

>注意：elementData是存储ArrayList元素的**数组缓冲区**。 ArrayList的容量是此数组缓冲区的长度。

>size属性是动态数组的实际大小（接下来要用）。

欸？空的数组？那初始容量10是怎么来的？嗯。。。我们想一下，每次我们实例化完一个ArrayList之后，一般会干什么？是添加元素对吧。那我们去add()方法里找找看

```java
public boolean add(E e) {
        //确定数组大小
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        //将新元素加入数组，并且数组的实际长度加1
        elementData[size++] = e;
        return true;
    }
```
我们看到他调用了一个ensureCapacityInternal()方法，并且，传递了一个参数"size + 1"。那这个方法是干嘛用的，又做了些什么事，我们去看看：

```java
private static final int DEFAULT_CAPACITY = 10;

private void ensureCapacityInternal(int minCapacity) {
        //判断当前数组是否为默认数组
        if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
            //取10和minCapacity的最大值作为新的数组的长度，调用无参构造函数生成ArrayList的话，添加第一个元素时minCapacity是1
            minCapacity = Math.max(DEFAULT_CAPACITY, minCapacity);
        }
        //根据minCapacity判断是否要对数组扩容
        ensureExplicitCapacity(minCapacity);
    }

private void ensureExplicitCapacity(int minCapacity) {
        //将修改记录加1
        modCount++
        //判断数组当前容量是否可以容纳当前元素的个数
        if (minCapacity - elementData.length > 0)
            //当前容量无法容纳当前元素的个数，对数组扩容
            grow(minCapacity);
    }

private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;

private void grow(int minCapacity) {
        //接下来的操作，就是通过一系列判断，对数组扩容
        int oldCapacity = elementData.length;
        //右移一位可以理解为除以2，所以newCapacity扩容了oldCapacity的3/2
        int newCapacity = oldCapacity + (oldCapacity >> 1);
        //如果minCapacity(新的元素个数)比newCapacity还大，则取minCapacity
        if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        //对数组扩容，拷贝原数组中的元素，将其放到一个新的容量为newCapacity的数组中，并返回新数组
        elementData = Arrays.copyOf(elementData, newCapacity);
    }

private static int hugeCapacity(int minCapacity) {
        //如果要创建的新的数组的长度小于0，抛出异常
        if (minCapacity < 0) // overflow
            throw new OutOfMemoryError();
        //确定新建数组的长度
        return (minCapacity > MAX_ARRAY_SIZE) ?
            Integer.MAX_VALUE :
            MAX_ARRAY_SIZE;
    }

```
通过分析上面的源码，相信大家已经知道为什么默认长度是10了。也知道了ArrayList每次扩容都是原基础的3/2。

>添加第一个元素时，任何带有elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA的空ArrayList都将扩展为DEFAULT_CAPACITY（DEFAULT_CAPACITY = 10）。

接下来的get()和set()方法就相对容易了，请看：

```java
public E get(int index) {
        //判断是否数组越界，数组越界就抛出异常
        if (index >= size)
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
        //返回指定位置的元素
        return (E) elementData[index];
    }

//
public E set(int index, E element) {
        //判断是否数组越界，数组越界就抛出异常
        if (index >= size)
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
        //先用一个局部变量接收此位置的旧的元素
        E oldValue = (E) elementData[index];
        //在指定的位置添加新的元素，替换旧值
        elementData[index] = element;
        //返回旧的元素
        return oldValue;
    }

```

我们再看一下上面说的ArrayList的clone：

```java
public Object clone() {
        try {
            ArrayList<?> v = (ArrayList<?>) super.clone();
            //复制数据
            v.elementData = Arrays.copyOf(elementData, size);
            //将操作数置为0
            v.modCount = 0;
            //返回克隆好的数组
            return v;
        } catch (CloneNotSupportedException e) {
            // this shouldn't happen, since we are Cloneable
            throw new InternalError(e);
        }
    }
```

以及序列化的读写：

```java
//将ArrayList实例的状态保存到流中（即序列化它）。
private void writeObject(java.io.ObjectOutputStream s)
        throws java.io.IOException{
        // 写出数组中数据改变的次数等
        int expectedModCount = modCount;
        s.defaultWriteObject();

        //写出数组的容量
        s.writeInt(size);

        // 按正确的顺序写出所有元素。
        for (int i=0; i<size; i++) {
            s.writeObject(elementData[i]);
        }

        if (modCount != expectedModCount) {
            throw new ConcurrentModificationException();
        }
    }


//从流中重构ArrayList实例（即反序列化它）。
private void readObject(java.io.ObjectInputStream s)
        throws java.io.IOException, ClassNotFoundException {
        elementData = EMPTY_ELEMENTDATA;

        //读入数组大小等
        s.defaultReadObject();

        // 读入容量
        s.readInt();

        if (size > 0) {
            //根据大小而不是容量来分配数组
            ensureCapacityInternal(size);

            Object[] a = elementData;
            // 按正确的顺序读入所有元素
            for (int i=0; i<size; i++) {
                a[i] = s.readObject();
            }
        }
    }

```

好了，ArrayList暂时就分析到这。其他的如果需要，后续再写。现在来总结一下：

1、ArrayList是通过elementData数组(Object类型)去操作数据的。这就是我们所说的，ArrayList的底层是数组，而且是一个动态数组。

2、使用无参的构造函数创建的ArrayList默认长度为10。当ArrayList的容量不足以容纳全部的元素，ArrayList会自己扩容：**新的容量=3/2旧的容量**。当然，容量最大不超过0x7fffffff(是一个16进制的数，值为：2^31 - 1，是最大的int数值)。

3、克隆，就是将以有的元素复制到一个新的数组

4、序列化的时候会先写入数组改变的次数以及数组的容量，然后再写入元素；反序列化的时候，会将数组大小即数组容量等全部读取出来，然后根据数组的大小来分配数组，最后读入所有的元素。

5、 ArrayList非线程安全、非线程安全、非线程安全！！！线程安全的List后续会讲到。

6、每次调用add()、addAll()方法时，如果元素个数超过了数组的当前容量，ArrayList都会去扩容，扩容需要将旧的元素拷贝到一个新的数组。所以，在可以知道最大容量的情况下，最好给ArrayList一个初始的容量值。
