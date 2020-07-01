window是一个抽象类，它的具体实现是PhoneWindow。通过WindowManager来创建Window。WindowManager是外界访问Window的入口，Window的具体实现位于WindowManagerService中，WindowManager和WindowManagerService的交互是一个IPC过程。Android中所有的视图都是通过Window来实现的，Window实际是View的直接管理者。

## Window层级

window有三种类型： **应用Window** 、**子Window** 和 **系统Window** 。应用类Window对应着一个Activity。子Window不能单独存在，它需要附属在特定的父Window之中。系统Window是需要声明权限才能创建的Window，比如Toast和系统状态栏就是系统Window。

Window是分层的，每个Window都有对应的层级，层级大的会覆盖在层级小的Window上面。在三种Window中，应用Window的层级范围是1～99，子Window的层级范围是1000～1999，系统Window的层级范围是2000～2999。这些层级范围对应的是 WindowManager.LayoutParams 的 type 参数。

## Window内部机制

Window是一个抽象概念，每一个Window都对应着一个View和一个ViewRootImpl，Window和View通过ViewRootImpl来建立联系。

WindowManager提供的功能有：添加View、更新View和删除View。这三个方法定义在ViewManager中，而WindowManager继承了ViewManager。WindowManager操作Window的过程更像是操作Window里的View。

Window的添加、删除和更新过程为： **Window** 将操作交给 **WindowManager** ，WindowManager 的实现类是 **WindowManagerImpl** ，WindowManagerImpl 并没有直接实现 Window 的三大操作，而是全部交给 **WindowManagerGlobal** 来处理。WindowManagerImpl 这就是典型的桥接模式，将所有的操作委托给 WindowManagerGlobal 来处理。在 WindowManagerGlobal 中，创建 **ViewRootImpl** 的实例，并将所对应的 View 与其绑定。接着通过 **WindowSession** 最终完成 Window的相关操作。在 WindowSession 的实现类 **Session** 内部，通过 **WindowManagerService** 来实现 Window 的相关操作。WindowManagerService 内部会为每个应用保留一个单独的Session。
