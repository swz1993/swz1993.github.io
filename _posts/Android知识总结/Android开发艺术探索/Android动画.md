Android的动画分为3种：View动画（补间动画）、帧动画和属性动画。

## 一、View动画

View动画的作用对象是**View**，它支持四种动画效果：平移动画（TranslateAnimation）、缩放动画（ScaleAnimation）、旋转动画（RotateAnimation）、和透明度动画（AlphaAnimation）。他可以使用代码实现，也可以使用xml文件实现。**fillAfter**可以指定View动画结束后，View是停留在结束位置（true）还是返回原始位置（false）。

## 二、帧动画

帧动画是顺序播放一组已经定义好的图片。系统使用**AninationDrawable**类来使用帧动画。
使用帧动画只需要在xml种定义一个“**animation-list**”，然后将其设置为View的背景并通过AnimationDrawable来播放动画即可。

## 三、属性动画

属性动画可以对**任意对象**做动画，甚至可以没有对象。动画默认时间间隔为300ms，默认帧率是10ms/帧。其可以达到的效果是：在一个时间间隔内完成对象从一个属性值到另一个属性值的改变。但是属性动画在API 11 才有，可以使用开源库nineoldandroids来兼容之前的版本。

比较常见的几个动画类是：**ValueAnimation**、**ObjectAnimation** 以及**AnimatorSet**。其中ObjectAnimation继承自ValueAnimation，AnimatorSet是动画集合，可以定义一组动画。属性动画可以通过代码实现，也可以通过 XML 来定义。属性动画需要定义在res/animator/目录下。

### 插值器和估值器

**TimeInterpolator** 中文翻译为时间插值器，它的作用是随着时间流逝的百分比来计算当前属性值改变的百分比，系统预置的有 LinearInterpolator（线性插值器：匀速动画）、AccelerateDecelerateInterpolator（加速减速插值器：两头忙中间块）和DecelerateInterpolator（减速插值器：动画越来越慢）等。 **TypeEvaluator** 中文翻译为类型估值算法，也叫估值器，它的作用是分局当前属性值改变的百分比来计算改变后的属性值。系统内置的有IntEvaleator（针对整型）、FloatEvaluator（针对浮点型）和ArgbEvaluator（针对Color）。

自定义插值器需要实现Interpolator或者TimeInterpolator，自定义估值算法需要实现TypeEvaluator。另外就是如果要对其他类型（非int、float和color）做动画，就必须自定义类型估值算法。

### 属性动画的监听器

监听器主要有如下两个接口： **AnimatorUpdateListener** 和 **AnimatorListener** 。其中AnimatorUpdateListener可以监听动画的开始、结束、取消和重复播放。AnimatorListener会监听动画的全过程，每播放一帧，其内部的onAnimationUpdate()方法就会调用一次。

### 对任意属性做动画

属性动画的原理：属性动画要求动画作用的对象提供该属性的set和get方法，属性动画每次根据外界传递的该属性的初始值和最终值，以动画的效果多次去调用set方法。即我们对object的属性abc做动画，要想使动画生效，要同时满足两个条件：

+ object必须提供setAbc方法，如果动画没有传递初始值，那么还要提供getAbc方法以获取初始值（这条不满足，程序直接crash）。
+ object的setAbc对属性abc的改变必须通过某种方法反映出来，否则动画无效。

对于做好属性动画，官方文档上告诉我们3种解决办法：

+ 给对象尽可能的加上get和set方法
+ 用一个类来包装原始对象，间接为其提供get和set方法
+ 采用ValueAnimator，监听动画过程，自己实现动画属性的改变

## 使用动画的注意事项

+ OOM问题
+ 内存泄漏
+ 兼容性问题
+ View动画问题
+ 不要使用px
+ 动画元素的交互（动画结束后动画的位置不一定是View的位置）
+ 硬件加速
