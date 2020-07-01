上一篇文章我们分析了一些ArrayList的简单的源码，在分析的过程中，我们发现在调用add()、remove()和clear()及其同类方法时，ArrayList的modCount属性都要加1，调用clone()方法时，新的数组的modCount属性要置为0。这里就很奇怪了，这个modCount是什么？他参与了哪些与ArrayList有关的操作？把他加1的意义是什么？带着这些问题，我们开始本篇文章的内容。

## 从ArrayList中的modCount入手

要知道一个属性的作用，就要找到它是在哪里被声明的。点击ArrayList的modCout，我们会进入到AbstractList中。这里，就是modCount属性被声明的地方。所以，ArrayList中的modCount是其继承的AbstractList的一个属性。

在AbstractList中对modCount的解释为：modCount表示此列表结构已被修改的次数。 结构修改是指一些改变列表大小或以其他方式扰乱它的方式，会导致**正在进行的迭代**可能产生不正确的结果。

正在进行的迭代？通过集合的第一篇文章，我们知道ArrayList向上追溯是实现了Collection接口的，而Collection接口又继承了Iterable接口来实现对集合中元素的遍历。在Iterable接口中，获取迭代器的方法是iterator()方法。那我们看一下ArrayList所实现的iterator()方法方法做了些什么

```
public Iterator<E> iterator() {
        return new Itr();
    }
```

我们看到它返回了一个Itr的实例。这个Itr又是什么，我们继续看下去：

```
//此处将ArrayList的modCount也放进来方便分析
protected transient int modCount = 0;

//Itr是Iterator接口的一个实现类
private class Itr implements Iterator<E> {

    //获取ArrayList的数组大小
    protected int limit = ArrayList.this.size;

        //下一个元素的索引
         int cursor; 
        //上一次遍历过的元素的索引; 如果没有的话返回-1   
         int lastRet = -1; 
        //将初始值置为modCount(此属性很重要，记住它，往下看)
         int expectedModCount = modCount; 

        //判断是否有下一个元素
        public boolean hasNext() {
            return cursor < limit;
        }

        //获取下一个元素
        @SuppressWarnings("unchecked")
        public E next() {
            //在获取下一个元素之前，判断当前的modCount与expectedModCount是否相等，不等则抛出异常
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            int i = cursor;
            if (i >= limit)
                throw new NoSuchElementException();
            Object[] elementData = ArrayList.this.elementData;
            if (i >= elementData.length)
                throw new ConcurrentModificationException();
            cursor = i + 1;
            return (E) elementData[lastRet = i];
        }

        public void remove() {
            if (lastRet < 0)
                throw new IllegalStateException();
            //在删除元素之前，判断当前的modCount与expectedModCount是否相等，不等则抛出异常
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();

            try {
                ArrayList.this.remove(lastRet);
                cursor = lastRet;
                lastRet = -1;
                expectedModCount = modCount;
                limit--;
            } catch (IndexOutOfBoundsException ex) {
                throw new ConcurrentModificationException();
            }
        }

        @Override
        @SuppressWarnings("unchecked")
        public void forEachRemaining(Consumer<? super E> consumer) {
            Objects.requireNonNull(consumer);
            final int size = ArrayList.this.size;
            int i = cursor;
            if (i >= size) {
                return;
            }
            final Object[] elementData = ArrayList.this.elementData;
            //判断下一个元素的索引是否大于数组的长度，是则抛出异常
            if (i >= elementData.length) {
                throw new ConcurrentModificationException();
            }
            while (i != size && modCount == expectedModCount) {
                consumer.accept((E) elementData[i++]);
            }
            // update once at end of iteration to reduce heap write traffic
            cursor = i;
            lastRet = i - 1;

            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
        }

}
```

在上面的源码中，我们注意Itr有三个属性：cursor、lastRet和expectedModCount。其中，expectedModCount就是我们分析问题的关键。我们发现expectedModCount在创建Itr实例的时候就会赋初值，值为创建Itr实例时的modCount，在Itr创建完成后expectedModCount的值就不再变化了，而modCount呢？每当ArrayList调用add()、remove()和clear()及其相关方法的时候都会加1。所以，当我们创建了一个Itr实例itr，然后修改了ArrayList结构，则使用itr遍历这个List就会报错。因为此时expectedModCount ！= modCount。现在想想，为什么要有这个判断呢？它预防或者解决了什么问题？

来来来，进入本篇文章的主题(终于来了！！！)。

## fail-fast机制

fail-fast机制是Java集合中的一个错误机制。在创建迭代器之后的任何时候，除了通过迭代器自己的remove()或add()方法之外，其他导致列表在结构上被修改的行为，都会导致则此类的iterator()和listIterator()方法返回的迭代器fail-fast(快速失败)。迭代器将抛出ConcurrentModificationException异常。比如，我们看一个简单的例子:

```
List<String> list = new ArrayList<>();
        list.add("213");
        list.add("213");
        list.add("213");
        Iterator<String> iterator = list.iterator();
        list.add("asd");
        iterator.next();
```

本例运行到iterator.next()就会抛出一个ConcurrentModificationException异常，因为我们创建了list的迭代器之后，又对list的结构做了修改。通过上面的分析，我们知道此时expectedModCount ！= modCount，所以抛出了异常。同样的情况还有多线程操作同一个ArrayList。

现在，我们知道了fail-fast出现的原因和原理，也就知道了该怎么预防这种情况，比如：在多线程的情况下，使用线程安全的集合类来保证线程安全；创建了一个List的Iterator实例后，在其完成遍历之前，不要使用List的add()、remove()和clear()及其相关方法等等。

好了，本文就分析到这，ending...

(马上元旦了，祝大家(如果有人看的话)也祝自己新的一年有更大的进步！！！生而有崖，学无止境)