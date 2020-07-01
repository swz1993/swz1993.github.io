# 3.1 View的基础知识

主要介绍的内容有：View的位置参数、MontionEvent和TouchSlop对象、VelocityTracker、GestureDetector和Scroller对象。

## 什么是View

View是Android中所有控件的基类。除了View，还有ViewGroup，它里面含有一组View，ViewGroup也继承View。

## 3.1.2 View 的位置参数

View的位置主要由它的四个顶点来决定，分别对应于View的四个属性：top、left、right和bottom，它们是相较于父视图的坐标。其中，top是左上横坐标，right是右下横坐标，bottom是右下纵坐标，left是左上纵坐标。在Android中，x轴和y的正方向分别是右和下。View的宽高和坐标的关系为：

```java
width = right - left
height = bottom - top
```

这四个参数在源码中它们对应于mLeft、mRight、mTop和mBottom这四个成员变量，获取的方式如下：

```java
left = getLeft();
right = getRight();
top = getTop();
bottom = getBottom();
```

从Android3.0开始，View加入了几个其他的位置参数，其中x和y是左上角的坐标(相较于屏幕)，而translationX和translationY是View左上角相对于父容器的偏移量，默认值是0。这几个参数的换算关系如下：

```java
x = left + translationX
y = top + translationY
```

需要注意的是，View在平移的过程中，top和left表示的是原始左上角的位置信息，值不会改变，此时发生改变的是x、y、translationX和translationY。

## 3.1.3 MontionEvent和TouchSlop

### 1. MontionEvent

在手指接触屏幕后所产生的一系列事件中，典型的事件类型有如下几种：

- ACTION_DOWN -- 手指刚接触屏幕
- ACTION_MOVE -- 手指在屏幕上移动
- ACTION_UP -- 手指从屏幕上松开的瞬间

正常情况下，一次手指触摸屏幕的行为会触发一系列点击事件，如下面的两种：

- 点击屏幕后松开，事件序列为DOWN --> UP
- 点击屏幕滑动一会再松开，事件序列为DOWN --> MOVE -->...-->MOVE -- > UP

通过MotionEvent对象我们可以得到点击事件发生的x和y坐标。为此系统提供了两组方法：

```java
getX/getY：返回的是相对于当前 View 左上角的x和y坐标
getRawX/getRawY：返回的是相对于手机屏幕左上角的x和y的坐标
```

### 2. TouchSlop

TouchSlop是系统所能识别的被认为是滑动的最小距离，即手机在屏幕上滑动时，如果滑动的距离小于这个常量，那么系统就不认为你是在做滑动操作。这是一个常量，和系统有关，获取方式为：
```java
ViewConfiguration.get(getContext()).getScaledTouchSlop();
```

## 3.1.4 VelocityTracker、GestureDetector和Scroller对象

### 1. VelocityTracker

速度追踪，用于追踪手指在滑动过程中在水平和竖直方向的速度。使用过程为

1、在View的onTouchEvent方法中追踪当前点击事件的速度：

```java
VelocityTracker velocityTracker = VelocityTracker.obtain();
velocityTracker.addMovement(event);
```

2、在我们知道当前的滑动速度时，我们可以采用如下的方式来获得当前的速度：

```java
velocityTracker.computeCurrentVelocity(1000);
float xVelocity =  velocityTracker.getXVelocity();
float yVelcity = velocityTracker.getYVelocity();
```

在这一步中有两点要注意：

* 1.获取速度前必须先计算速度，即getXVelocity和getYVelocity前必须先调用computeCurrentVelocity。
* 2.这里的速度是指一段时间内手指所滑过的像素值，比如将时间间隔设置为1000ms时，在1s内手指在水平方向上从左向右划过100像素，那么水平速度就是100。另外，如果手指逆着坐标系的正方向滑动，所产生的速度就是负值。

3、当不需要它的时候，需要回收内存

```java
velocityTracker.clear();
velocityTracker.recycle();
```

### 2、GesTureDetector

手势检测，用于辅助检测用户的单击、滑动、长按和双击等行为。使用方法如下：

* 1、创建一个GestureDetector对象并实现OnGestureListener接口，根据需要我们还可以实现onDoubleTapListener从而监听双击行为：

```java
GestureDetector gestureDetector = new GestureDetector(context, new GestureDetector.OnGestureListener() {

            /**
             *手指轻轻触摸屏幕的一瞬间，由一个 ACTION_DOWN 触发
             * 在所有其他事件之前
             * */
            @Override
            public boolean onDown(MotionEvent e) {
                return false;
            }

            /**
             *手指轻轻触摸屏幕的一瞬间，手指尚未松开或拖动，由一个 ACTION_DOWN 触发
             * 此事件通常用于向用户提供视觉反馈，让用户知道其操作已被识别，即突出显示某个元素。
             * */
            @Override
            public void onShowPress(MotionEvent e) {
            }
            /**
             *手指轻轻触摸屏幕后松开，由一个 ACTION_UP 触发，这是单击行为
             * */
            @Override
            public boolean onSingleTapUp(MotionEvent e) {
                return false;
            }
            /**
             *手指按下并拖动，由一个 ACTION_UP 和多个 ACTION_MOVE 触发，这是拖动行为。为了方便起见，还提供了x和y的距离。
             * */
            @Override
            public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY) {
                return false;
            }
            /**
             *用户长按时触发
             * */
            @Override
            public void onLongPress(MotionEvent e) {
            }
            /**
             *用户按下触摸屏并快速滑动后松开，由一个 ACTION_DOWN、多个 ACTION_MOVE 和一个 ACTION_UP 触发，这是快速滑动的行为
             * */
            @Override
            public boolean onFling(MotionEvent e1, MotionEvent e2, float velocityX, float velocityY) {
                return false;
            }
        });
//解决长按屏幕无法拖动的情况
gestureDetector.setIsLongpressEnabled(false);
```

我们也可以通过 GestureDetector 对象的 setOnDoubleTapListener 方法监听双击事件

```java
gestureDetector.setOnDoubleTapListener(new GestureDetector.OnDoubleTapListener() {

            /**
             * 当一次点击发生时通知。
             *
             * 与{@link OnGestureListener#onSingleTapUp（MotionEvent）}不同，
             * 只有在检测器确信用户的第一次点击后没有第二次点击导致双击手势后，才会调用此函数
             * */
            @Override
            public boolean onSingleTapConfirmed(MotionEvent e) {
                return false;
            }

            /**
             * 当双击发生时通知，不能与 onSingleTapConfirmed 共存
             * */
            @Override
            public boolean onDoubleTap(MotionEvent e) {
                return false;
            }

            /**
             * 表示发生了双击行为，在双击期间，ACTION_DOWN、 ACTION_MOVE和 ACTION_UP 都会触发此回调
             * */
            @Override
            public boolean onDoubleTapEvent(MotionEvent e) {
                return false;
            }
        });
```

* 2. 接管目标得到onTouchEvent方法，在待监听View的onTouchEvent方法中添加如下实现：

```java
boolean custon = gestureDetector.onTouchEvent(event);
return custon;
```

### 3、Scroller

弹性滑动对象，用于实现View的弹性滑动。使用View的scrollTo/scrollBy方式来进行滑动，其过程是瞬间完成的。在某些需要的场景下我们可以使用Scroller来实现有过渡效果的滑动。Scroller本身无法让View弹性滑动，它需要和 View#computeScroll 方法配合使用才能完成这个功能。使用方式如下：

```java
Scroller scroller = new Scroller(context);

    @Override
    public void computeScroll() {
        super.computeScroll();
        if (scroller.computeScrollOffset()) {
           scrollTo(scroller.getCurrX(),scroller.getCurrY());
           postInvalidate();
        }
    }

    //缓慢滚动到指定位置
    private void smoothScrollTo(int destX, int destY) {
        int scrollX = getScrollX();
        int delta = destX - scrollX;
        //1000ms内滑向destX，效果是慢慢滑动
        scroller.startScroll(scrollX, 0, delta, 0, 1000);
        invalidate();
    }
```

# 3.2 View 的滑动

通过三种方式可以实现View的滑动：

· 通过View本身的scrollTo/scrollBy方法实现滑动

· 通过动画给View施加平移效果实现滑动

· 通过改变View的LayoutParams使得View重新布局从而实现滑动

## 3.2.1 使用scrollTo/scrollBy

scrollTo/scrollBy的实现

```java
/**
     * Set the scrolled position of your view. This will cause a call to
     * {@link #onScrollChanged(int, int, int, int)} and the view will be
     * invalidated.
     * @param x the x position to scroll to
     * @param y the y position to scroll to
     */
    public void scrollTo(int x, int y) {
        if (mScrollX != x || mScrollY != y) {
            int oldX = mScrollX;
            int oldY = mScrollY;
            mScrollX = x;
            mScrollY = y;
            invalidateParentCaches();
            onScrollChanged(mScrollX, mScrollY, oldX, oldY);
            if (!awakenScrollBars()) {
                postInvalidateOnAnimation();
            }
        }
    }

    /**
     * Move the scrolled position of your view. This will cause a call to
     * {@link #onScrollChanged(int, int, int, int)} and the view will be
     * invalidated.
     * @param x the amount of pixels to scroll by horizontally
     * @param y the amount of pixels to scroll by vertically
     */
    public void scrollBy(int x, int y) {
        scrollTo(mScrollX + x, mScrollY + y);
```

可以看出，scrollBy实际上也是调用了sctollTo的方法。
