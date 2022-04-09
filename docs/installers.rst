==================
安装脚本手册
==================

* 翻译：张兴旺、老虎会游泳
* 校对：老虎会游泳

导航
=================

* `基础`_
* `变量替换`_
* `游戏配置指令`_
* `运行环境配置指令`_
* `系统配置指令`_
* `获取所需文件`_
* `安装脚本元数据`_
* `编写安装步骤`_
* `脚本示例`_



基础
======


Wine游戏助手使用的“Lutris游戏安装脚本”（简称“安装脚本”）采用YAML格式编写，脚本提供了游戏文件获取方式、游戏安装步骤、运行环境配置等信息。

写脚本前你要先熟悉YAML格式，阮一峰博客有一篇很好的教程：https://www.ruanyifeng.com/blog/2016/07/yaml.html

安装脚本至少要有一个``game``部分。如果安装脚本需要下载文件或者需要用户提供文件，那就加上`files`部分。

具体的安装步骤放在``installer``部分。这个部分会读取`files`部分提供的文件进行实际安装，最终得到可以运行的游戏。

安装脚本中的其他信息用于创建游戏配置文件，步骤如下：删除`files`和`installer`部分，替换`$GAMEDIR`这样的变量，然后保存到以下位置:
`~/.config/lutris/games/<game>-<timestamp>.yml`

已经发布的安装脚本可以使用前缀``winegame:``加安装脚本标识符进行调用。比如，执行``/opt/apps/net.winegame.client/files/bin/winegame winegame:blizzard-battlenet-1``会启动暴雪战网客户端的“1. 国服”安装脚本。编辑安装脚本时可以从地址栏看到它的标识符。

**重要提示**：在Wine游戏助手网站上编写的安装脚本并不能直接保存成文件用于游戏安装，需要把它嵌入另一个包含元信息的文件才行。网站上编写的安装脚本会位于最终文件的``script``部分，除此之外还需要以下部分：

* ``name``：游戏名称。如果包含特殊符号，需要加引号。
* ``game_slug``：Wine游戏助手网站上的游戏标识符，仅限字母数字和连字符。
* ``version``：安装脚本名称。如果包含特殊符号，需要加引号。
* ``slug``：安装脚本标识符，仅限字母数字和连字符。
* ``runner``：游戏的运行环境，通常是“wine”。

如果你打算写个本地安装脚本，不打算放在网页上，你应该在YAML的根级别提供上述指令，其他部分则缩进到``script``部分。本地安装脚本可以通过以下命令调用：``/opt/apps/net.winegame.client/files/bin/winegame -i /path/to/file.yaml``

变量替换
=====================

可以在脚本中使用变量来代替不确定的部分，变量在安装过程中会被替换成实际值。

可用变量列表：

* ``$GAMEDIR``：游戏安装位置的绝对路径。
* ``$CACHE``：用于保存游戏文件（`files`部分）的临时目录，安装完成后会自动删除。
* ``$RESOLUTION``：用户主显示器的分辨率（例如``1920x1080``）
* ``$RESOLUTION_WIDTH``：用户主显示器的分辨率宽度（例如``1920``）
* ``$RESOLUTION_HEIGHT``：用户主显示器的分辨率高度（例如``1080``）
* ``$WINEBIN``：Wine二进制的绝对路径。

你还可以通过文件标识符引用``files``部分下载的文件，安装时会转换为下载好的文件的绝对路径。引用时通常不需要加`$`前缀，但是如果在`command`命令中引用，或者要进行字符串拼接，则需要加`$`前缀。


安装脚本元数据
===================

元数据指令需要放在YAML根级别。

主程序
-------------------------

旧版安装脚本把主程序指令放在根级别，但是现在移到了``game``部分。
如果你在安装脚本的根级别看到``exe``、``main_file``等指定主程序的指令，请把它们挪到``game``部分。

自定义游戏名称
---------------------------

使用 ``custom-name`` 指令指定游戏安装后的显示名称，用于区分游戏的不同版本。

例子: ``custom-name: 暴雪战网国服``

需要的二进制文件
-----------------------------

如果安装脚本需要一些系统命令才能运行，可以在``require-binaries``指令中指定，值为逗号分隔的文件名列表。如果某个命令可以有多个选择，用`|`隔开。

例子::

    # 需要安装cmake，以及gcc或clang（二选一）
    require-binaries: cmake, gcc | clang

模组和插件
----------------

安装模组和插件前需要先安装基础游戏。可以通过``requires``指令指定基础游戏，让Wine游戏助手知道你想安装的是插件。``requires``的值必须是基础游戏的标准标识符（出现在网址中的那部分），而非别名。例如，给`OSU!`安装插件，需要添加``requires: osu``。

如果插件可以在多个游戏中安装，或者需要多个基础游戏同时安装，则可以使用类似``require-binaries``的逗号竖线分隔语法进行指定。

扩展/补丁
--------------------

在Wine游戏助手里，你可以写一个不创建游戏实体的安装脚本，用它来修改已经存在的游戏的配置。你可以使用``extends``指令来使用这个功能，它和``requires``指令工作方式相同，会检查基础游戏是否已安装。

例子::

    # 通过安装脚本修复Mesa库问题
    extends: unreal-gold

定制安装结束文本信息
-----------------------------------

使用``install_complete_text``指令可以在安装完成时显示自定义信息。




游戏配置指令
=============================

游戏配置指令包含三部分：`game`、`system`，以及以游戏的运行环境命名的部分（通常是`wine`）。

`game`部分可以包含对其他商店的引用，比如Steam或GOG。有些引用ID用来启动游戏（如Steam、ScummVM），有些引用ID用于从第三方平台下载游戏文件和安装脚本（如Humble Bundle、GOG）。

Wine游戏助手支持以下游戏标识符：

`appid`：用于Steam游戏，值为商店页面URL路径里的数字ID。
例如 https://store.steampowered.com/app/238960/Path_of_Exile/ 这个路径里的`appid`是 `238960`。
该ID用于调用Steam安装和启动游戏。

`game_id`：ScummVM / ResidualVM 的游戏标识符。在 https://www.scummvm.org/compatibility/ 和 https://www.residualvm.org/compatibility/ 页面可以查找游戏兼容列表。

`gogid`：GOG的游戏标识符. 查看 https://www.gogdb.org/products ，确保引用的是基础游戏而非它的数据包或可下载内容（DLC）。
例子：《Darksiders III》的`gogid`是`1246703238`。

`humbleid`：Humble Bundle ID。目前只能通过HB API获取订单详情来查看该ID。以后可能会提供更简单的方法来找出ID。

`main_file`：对于MAME游戏，`main_file`可以引用MAME ID来代替文件路径。

game部分包含的公共指令
---------------------------

``exe``：可执行主程序，用于Linux和Wine游戏。
例子：``exe: exult``

``main_file``：用于模拟器运行环境里引用ROM或磁盘文件。
例子: ``main_file: game.rom``
对于网页运行环境，`main_file`用于指定网址：``main_file: http://www...``

``args``：传递给主程序的命令行参数。
用于`linux`、`wine`、`dosbox`、`scummvm`、`pico8`和`zdoom`运行环境。
例子：``args: -c $GAMEDIR/exult.cfg``

``working_dir``：设置主程序启动时的工作目录（相当于启动游戏前执行`cd 目录`命令）。
如果游戏运行的当前目录与主程序所在目录不同，可以使用该指令，可用于Linux、Wine和Dosbox安装脚本。
例子：``$GAMEDIR/path/to/game``

``launch_configs``: 如果你的游戏有多个可执行文件（比如游戏附带地图编辑器，或者游戏需要通过多种参数启动等），可以包含该指令。
该指令的值为包含以下属性的对象数组： ``exe``， ``args``， ``working_dir`` 以及显示名称 ``name``。
例子:

  game:
    exe: main.exe
    launch_configs:
    - exe: map_editor.exe
      name: 地图编辑器
    - exe: main.exe
      args: -missionpack
      name: 任务包

Wine和其他基于Wine的运行环境
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``arch``：设置Wine前缀的架构，默认值为``win64``，安装32位游戏时，可设为``win32``。

``prefix``：Wine前缀的路径。对于Wine游戏，它应该设置为``$GAMEDIR``。


无DRM限制的Steam游戏
^^^^^^^^^^^^^^

Wine游戏助手可以在不启动Steam客户端的情况下启动Steam游戏，仅能启动不使用Steam数字版权管理（Steam DRM）的游戏。

``run_without_steam``：启用无DRM模式，启动游戏时不启动Steam，值为`true`或`false`。

``steamless_binary``：与``run_without_steam``结合使用，指定游戏的启动文件。只有不使用Steam DRM的游戏能顺利使用该功能。

例子：``steamless_binary: $GAMEDIR/System/GMDX.exe``


ScummVM
^^^^^^^

``path``：游戏文件的位置，应该设为``$GAMEDIR``。



运行环境配置指令
===============================

运行环境配置以其标识符命名（标识符可在 https://winegame.net/api/runners 查看，位于``slug``字段）。
请确保运行环境的定制最小化，只添加正常运行游戏所需的内容。很多运行环境选项未在Lutris安装脚本中提供，被保留用于用户偏好。

以下部分描述通常用于安装脚本的运行环境配置指令。

wine
----

``version``：选择特定的Wine版本，值的格式为`版本名称-架构名称`。
注意有些wine的版本名称里本身就有架构，但是依然需要再把架构写出来，否则安装时会遇到问题。
ARM架构之所以写成`arm64-armv7`，是因为网站程序里没有ARM64这个架构选项，只能选择`armv7`。
例子: 
* ``version: winehq-stable-7.0-x86_64``
* ``version: winehq-stable-7.0-x86only-i386``
* ``version: winehq-stable-7.0-x64only-x86_64``
* ``version: winehq-stable-7.0-exagear32-i386``
* ``version: winehq-stable-7.0-exagear64-x86_64``
* ``version: winehq-devel-7.0-arm64-armv7``

``Desktop``：在Wine虚拟桌面运行游戏。当游戏和Linux窗口管理器冲突，比如按Alt+Tab会崩溃时，可用此选项。
例子：``Desktop: true``

``WineDesktop``：设置Wine虚拟桌面的分辨率，配合``Desktop``选项使用。如果未设置，则虚拟桌面会占满全屏。在安装脚本中指定该选项可让游戏以指定的分辨率运行。
例子：``WineDesktop: 1024x768``

``dxvk``：如果需要，用来禁用DXVK（默认启用）。（``dxvk: false``）

``esync``：用于启用esync。（``esync: true``）

``overrides``：DLL函数库顶替，值为键值对映射，其中键为要覆盖的dll，值为以下条目：

* ``native,builtin`` = 原装先于内建
* ``builtin,native`` = 内建先于原装
* ``builtin`` = 内建
* ``native`` = 原装
* ``disabled`` = 停用

例子::

      overrides:
        ddraw.dll: native
        d3d9: disabled
        winegstreamer: builtin

系统配置指令
===============================

这些指令定义在``system``部分，用于在游戏启动时调整操作系统选项。请小心使用系统指令，仅在运行游戏绝对需要时才添加它们。

``restore_gamma``：如果游戏退出时没有恢复伽马，可以使用该选项，唤起xgamma并重置为默认值。该选项在Wayland上无效。
例子：``restore_gamma: true``

``terminal``：设为`true`可在终端运行基于命令行的文字游戏。不要使用该选项获取图形界面游戏的控制台输出，肯定无法得到预期结果。**该选项仅用于运行需要终端的命令行程序**。

``env``: 在游戏启动前和安装前设置环境变量。不要使用该指令设置Wine的函数库顶替（不会生效，应该改用`wine`的`overrides`指令）。值中可以使用变量。
例子::

     env:
       __GL_SHADER_DISK_CACHE: 1
       __GL_THREADED_OPTIMIZATIONS: '1'
       __GL_SHADER_DISK_CACHE_PATH: $GAMEDIR
       mesa_glthread: 'true'

``single_cpu``：用单核运行游戏。用于那些对多核CPU支持较差的老游戏。（``single_cpu: true``）

``disable_runtime``：如果所选Wine版本或所在平台与Lutris运行时不兼容（比如龙芯架构），可禁用Lutris运行时。（``disable_runtime: true``）

``pulse_latency``：将PulseAudio延迟设置为60毫秒，可减少声音中断。（``pulse_latency: true``）

``use_us_layout``:启动游戏时将键盘布局改为标准美国键盘布局。用于兼容那些键盘布局支持较差且没有按键映射功能的游戏。简体中文用户通常用不上该选项，因为我们默认使用标准美国键盘布局。（``use_us_layou: true``）

``xephyr``: 在Xephyr中运行游戏，用于支持256色模式的游戏，值为传递给Xephyr的色彩模式。（``xephyr: 8bpp``）

``xephyr_resolution``: 与``xephyr`` 选项配合使用，用来设置Xephyr窗口的分辨率。（``xephyr_resolution: 1024x768``）


获取所需文件
=======================

安装脚本的``files``部分列出了游戏安装所需的全部文件。本部分的键作为文件标识符，可在``installer``部分引用，值可以是一个文件下载地址，也可以是一个包含``filename``和``url``键值的字典。``url``为下载地址，``filename``为保存在本地的临时文件名（对于Windows可执行文件，如果下载地址结尾不具有正确的`.exe`扩展名，则应该使用这种方式指定文件名）。如果你想设置`Referer`头信息来绕过防盗链，可添加``referer``键。

如果你想让用户手动选择文件，那么下载地址应该以``N/A``打头。当安装脚本遇到这个值，它会提示用户手动选择文件。为了提示用户选择哪个文件，可在冒号后附加提示信息：``N/A:选择战网客户端安装程序（Battle.net-Setup.exe）``

例子::

    files:
    - file1: https://example.com/gamesetup.exe
    - file2: "N/A:选择战网客户端安装程序（Battle.net-Setup.exe）"
    - file3:
        url: https://example.com/url-that-doesnt-resolve-to-a-proper-filename
        filename: actual_local_filename.zip
        referer: www.mywebsite.com
    - setup:
        url: https://www.battlenet.com.cn/download/getInstaller?os=win&installer=Battle.net-Setup-CN.exe
        filename: Battle.net-Setup-CN.exe

上面的例子中，`file1`、`file2`、`file3`和`setup`都是文件标识符，可以在后续的`installer`部分引用。

如果游戏使用了Steam数据，键值应该是``$STEAM:appid:path/to/data``。它会检查文件是否存在，没有就安装。


编写安装步骤
===============================

在得到了游戏所需的每一个文件后，真正的安装就开始了。一系列的指令会告诉安装脚本如何正确安装游戏。以``installer:``开启安装脚本部分，按照执行顺序（从上到下）堆叠指令。

显示“插入光盘”对话框
----------------------------------

``insert-disc``命令会显示一个消息框，请求用户插入游戏光盘到光驱中。

通过``requires``参数，来检测光盘上的文件或文件夹，以确保插入了正确的光盘。

`$DISC`变量将包含光驱路径，用于后续安装任务。

如果检测本机有gCDEmu，则会有一个按钮来打开gCDEmu，否则会显示CDEmu的主页和PPA。你可以使用``message``参数来覆盖默认的提示信息。

例子::

    - insert-disc:
        requires: diablosetup.exe

移动文件和目录
----------------------------

用``move``命令移动文件或目录。``move``需要两个参数：``src``（源文件或文件夹）和``dst``（目标文件或文件夹）。

``src``可以是文件标识符（不需要加`$`前缀），或者绝对路径。如果想从缓存目录或游戏安装目录移动文件，需要加``$CACHE/``或``$GAMEDIR/``形成绝对路径。

``dst``参数只能是绝对路径。如果要移动到游戏安装目录或用户主目录，需要加``$GAMEDIR/``或``$HOME/``形成绝对路径。

如果`src`是一个文件标识符，对它使用该指令后，该标识符指向的位置也会更新，在后续命令中可以访问到移动后的文件。

``move``命令不能覆盖文件。如果目标目录不存在，它会创建。移动文件时，确保给出完整的目标路径（包含文件名），不要只给出目标文件夹，否则文件名可能不是你想要的。


例子::

    - move:
        src: setup
        dst: $GAMEDIR/my.exe

拷贝和合并目录
-------------------------------

合并和拷贝行为可以通过``merge``或``copy``指令完成。用哪个指令完成并不重要，因为``copy``就是``merge``的别名。是执行合并还是拷贝行为，取决于目标目录是否存在。当合并到一个已存在目录时，源文件和目标文件同名时，则自动覆盖。写脚本的时候要考虑到这一点，并给操作行为安排好顺序。

如果`src`是一个文件标识符，对它使用该指令后，该标识符指向的位置也会更新，在后续命令中可以访问到移动后的文件。

例子::

    - merge:
        src: setup
        dst: $GAMEDIR/my.exe

解压文件
-------------------

使用``extract``指令解压文件，``file``参数可以是文件标识符或文件路径，提供文件路径时可以使用通配符。如果文件要解压到``$GAMEDIR``以外的其他目录，可以指定``dst``参数。

可以选择提供``format``参数来指定压缩文件的类型。
如果文件扩展名和压缩格式不匹配，需要提供该参数。
``format``参数的值可以是：tgz、tar、zip、7z、rar、txz、bz2、gzip、deb、exe、gog（innoextract），以及其他 7zip 支持的格式。

例子::

    - extract:
        file: file3
        dst: $GAMEDIR/datadir/

给文件添加执行权限
------------------------

使用``chmodx`` 指令给文件添加执行权限。对于以无法保留权限的zip文件形式发行的游戏来说，它通常是必需的。

例子: ``- chmodx: $GAMEDIR/game_binary``

执行一个文件
----------------

使用``execute``指令来执行文件。使用``file``参数引用文件标识符或提供可执行程序路径，用``args``参数传递命令行参数。``terminal``参数设为`true`可以使程序在终端窗口中执行，``working_dir``设置程序执行的目录（如果不设置，默认是`$GAMEDIR`）。
命令运行在Lutris运行时中（解决了绝大多数的共享库依赖问题），且会自动添加执行权限（无需提前执行chmodx）。你还可以使用`env``（环境变量）、``exclude_processes``（不受监控的程序，空格分隔的进程列表，如果除了列表中的程序之外没有其他程序还在运行，则认为`execute`指令已运行完毕）、``include_processes``（``exclude_processes``的反向操作，用来覆盖Wine游戏助手内建的排除列表）、``disable_runtime``（禁用Lutris运行时，执行系统二进制文件时有用）。

例子::

    - execute:
        args: --argh
        file: great_id
        terminal: true
        exclude_processes: process_not_to_monitor "Process Not To Monitor"
        include_processes: excluded_process_from_the_list
        disable_runtime: true
        env:
          key: value

你可以用``command``参数来代替``file``和``args``，这让运行bash/shell命令更容易：``bash``将被调用，并被添加到内部的``include_processes``里。

例子::

    - execute:
        command: 'echo Hello World! | cat'

写入文件
-------------


写入文本文件
^^^^^^^^^^^^^^^^^^

用``write_file``指令创建或覆盖一个文件。使用``file``（文件标识符或绝对路径）和``content``参数。

还可以添加可选参数``mode``来选择写入方式，有效值包括``w``（默认, 覆盖写入文件，原内容被清除）、``a``（在文件末尾追加写入）。

关于如何包括多行文本，请参考YAML文档。

例子:

::

    - write_file:
        file: $GAMEDIR/myfile.txt
        content: 'This is the contents of the file.'

写入INI配置文件
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

使用``write_config``指令创建或写入一个INI配置文件。配置文件是由`key=value`（或`key: value`）组成的文本文件，这些行按`[section]`分组。该指令使用以下参数：``file``（文件标识符或绝对路径）；``section``；``key``、``value``或``data``。设置``merge: false``会首先清空这个文件。提示：这个文件会被完全重写，注释会被省略。一定要比较原始文件和处理后的结果文件，以避免潜在的解析问题。

例子:

::

    - write_config:
        file: $GAMEDIR/myfile.ini
        section: Engine
        key: Renderer
        value: OpenGL

::

    - write_config:
        file: $GAMEDIR/myfile.ini
        data:
          General:
            iNumHWThreads: 2
            bUseThreadedAI: 1


写入JSON文件
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``write_json``指令用来创建或写入一个JSON文件，使用``file``（文件标识符或绝对路径）和``data``参数。提示：文件会被完全重写，一定要比较原始文件和处理后的结果文件，以避免潜在的解析问题。如果你想覆盖JSON文件而非更新它，你可以设置可选参数``merge``为``false``。

例子:

::

    - write_json:
        file: $GAMEDIR/myfile.json
        data:
          Sound:
            Enabled: 'false'

它会写入（或更新）文件，内容如下:

::

    {
      "Sound": {
        "Enabled": "false"
      }
    }

执行运行环境提供的任务
-----------------------------------

有的运行环境有一些特定的行为，你可以用``task``指令来调用。你至少要提供一个函数名做为``name``参数用来调用。其他参数则依赖于被调用的任务。通过在任务名称前加上运行环境的名称，可以从其他运行环境调用函数（例如，在dosbox安装脚本上，你可以用``wine.wineexec``作为任务的``name``来调用wineexec任务）。
如果你的任务在正常情况下也会以非0状态码退出，你还可以用 ``return_code`` 属性指明该状态码，比如： ``return_code: 256``

目前Wine游戏助手实现了以下任务:

*   wine： ``create_prefix`` 在指定路径上创建一个空的Wine容器。以下其他的wine指令都包含了自动创建容器的功能，因此通常不需要手动调用create_prefix指令。该指令的参数是：

    * ``prefix``: 路径

    * ``arch``: 可选的容器架构，默认是win64，除非在运行环境选项里指定了32位。

    * ``overrides``: 可选DLL覆盖，参数格式稍后详述。

    * ``install_gecko``: 可选参数（true|false），用来阻止安装gecko。

    * ``install_mono``: 可选参数（true|false），用来阻止安装mono。

    例子:

    ::

        - task:
            name: create_prefix
            arch: win64

*   wine： ``wineexec`` 运行windows可执行程序，参数是：
    * ``executable``（文件标识符或绝对路径）；
    * ``args``（传递给可执行文件的可选参数）；
    * ``prefix``（可选，Wine容器）；
    * ``arch``（可选，WINEARCH, 值为``win32``或``win64``）；
    * ``blocking``（当为true时，直接在Wine游戏助手运行的线程启动wine，不开启新线程）；
    * ``description``（在安装时显示给用户看的描述信息）；
    * ``working_dir``（可选，工作目录）；
    * ``exclude_processes``（可选，，空格分割的一组进程，这些进程不会被监控）；
    * ``include_processes`` （可选，空格分隔的一组进程，这些进程会被监控）；
    * ``env``（可选，环境变量）；
    * ``overrides``（可选，DLL函数库顶替）。

    例子::

        - task:
            arch: win64
            blocking: true
            description: Doing something...
            name: wineexec
            executable: drive_c/Program Files/Game/Game.exe
            exclude_processes: process_not_to_monitor.exe "Process Not To Monitor.exe"
            include_processes: process_from_the_excluded_list.exe
            working_dir: /absolute/path/
            args: --windowed

*   wine： ``winetricks`` 运行winetricks，包含以下参数：
    * ``app``：要安装的组件，可指定多个，用空格分隔；
    * ``prefix``：可选，Wine容器路径。
    * ``silent``：Winetricks默认是静默模式，但有的时候会和一些组件冲突，例如XNA。这时可以设置``silent: false``。

    例子::

        - task:
            name: winetricks
            app: nt40
            silent: true

    查看完整的``winetricks``可用清单，请点击: https://github.com/Winetricks/winetricks/tree/master/files/verbs

*   wine： ``eject_disk`` 在你的``prefix``参数指定的容器里运行eject_disk，参数是
    ``prefix``（可选，wine容器路径）。

    例子:

    ::

        - task:
            name: eject_disc

*   wine： ``set_regedit`` 修改Windows注册表。参数是：
    * ``path``：注册表路径，使用反斜杠；
    * ``key``：键名；
    * ``value``：键值；
    * ``type``：可选，值类型，默认值为REG_SZ（字符串）；
    * ``prefix``：可选，wine容器路径；
    * ``arch``：可选，容器的架构，win32或win64。

    例子:

    ::

        - task:
            name: set_regedit
            path: HKEY_CURRENT_USER\Software\Valve\Steam
            key: SuppressAutoRun
            value: '00000000'
            type: REG_DWORD

*   wine: ``delete_registry_key`` 删除Windows注册表键值。参数是：
    * ``path``：注册表路径，使用反斜杠；
    * ``key``：键名；
    * ``type``：可选，值类型，默认值为REG_SZ（字符串）；
    * ``prefix``：可选，wine容器路径；
    * ``arch``：可选，容器的架构，win32或win64。

    例子:

    ::

        - task:
            name: set_regedit
            path: HKEY_CURRENT_USER\Software\Valve\Steam
            key: SuppressAutoRun
            value: '00000000'
            type: REG_DWORD

* wine: ``set_regedit_file`` 导入注册表文件。参数是：
    * ``filename``：注册表文件名；
    * ``arch``：可选，容器的架构，win32或win64。


  例子::

    - task:
        name: set_regedit_file
        filename: myregfile

* wine: ``winekill`` 停止Wine容器的全部进程。参数是：
    * ``prefix``：可选，wine容器路径；
    * ``arch``：可选，容器的架构，win32或win64。

  例子

  ::

    - task:
        name: winekill

*   dosbox: ``dosexec`` 运行dosbox。参数有：
    * ``executable``：可选，可执行文件，文件标识符或绝对路径；
    * ``config_file``：可选，.conf配置文件，文件标识符或绝对路径；
    * ``args``：可选，命令参数；
    * ``working_dir``：可选，工作目录，默认是``executable``所在目录或``config_file``所在目录；
    ``exit``：设为``false``可以阻止DOSBox在``executable``执行结束后自动退出。

    例子:

    ::

        - task:
            name: dosexec
            executable: file_id
            config: $GAMEDIR/game_install.conf
            args: -scaler normal3x -conf more_conf.conf

显示下拉菜单
----------------------------------------

使用``input_menu``指令可以显示下拉菜单来获取用户的选择，参数如下：
   * ``description``：提示信息；
   * ``options``：选项列表，键值对，键为选项值，值为显示给用户看的选项名称；
   * ``preselect``：可选，指定默认选项。
   * ``id``：可选，变量标识符后缀，只能包含字母、数字、下划线。


用户选择的选项值可以通过``$input``变量获得。如果指定了id参数，还可以通过``$INPUT_<id>``获得。

例子:

::

    - input_menu:
        description: "选择游戏语言："
        id: LANG
        options:
        - en: 英语
        - fr: 法语
        - "选项值": "显示给用户看的选项名称"
        preselect: en

这个例子中，英语是默认选项（`$INPUT`和`$INPUT_LANG`变量均为`en`）。如果用户选择了法语，则`$INPUT`和`$INPUT_LANG`变量均为`fr`。如果有多个选单，`$INPUT`在执行下个选单时会被覆盖，而`$INPUT_LANG`则可以一直保留。

脚本示例
===============

这些脚本示例是完整的本地安装文件，可用于通过`/opt/apps/net.winegame.client/files/bin/winegame -i xxx.yaml`命令本地安装。
在Wine游戏助手网站添加安装脚本时，只需要包含``script``部分，其他部分会根据游戏信息自动生成，所以不需要包含在网站安装脚本中。

示例Linux游戏::

    name: My Game
    game_slug: my-game
    version: Installer
    slug: my-game-installer
    runner: linux

    script:
      game:
        exe: $GAMEDIR/mygame
        args: --some-arg
        working_dir: $GAMEDIR

      files:
      - myfile: https://example.com/mygame.zip

      installer:
      - chmodx: $GAMEDIR/mygame
      system:
        env:
          SOMEENV: true

示例Wine游戏::

    name: My Game
    game_slug: my-game
    version: Installer
    slug: my-game-installer
    runner: wine

    script:
      game:
        exe: $GAMEDIR/mygame
        args: --some-args
        prefix: $GAMEDIR/prefix
        arch: win32
        working_dir: $GAMEDIR/prefix
      files:
      - installer: "N/A:Select the game's setup file"
      installer:
      - task:
          executable: installer
          name: wineexec
          prefix: $GAMEDIR/prefix
      wine:
        Desktop: true
        overrides:
          ddraw.dll: n
      system:
        env:
          SOMEENV: true

示例GOG Wine游戏

注意某些游戏安装程序用``/SILENT``或``/VERYSILENT``选项时会崩溃，比如《Cuphead》和《Star Wars: Battlefront II》。

GOG安装程序的绝大多数命令行选项都记录在此：http://www.jrsoftware.org/ishelp/index.php?topic=setupcmdline

还有一个文档里没有记录的选项：``/NOGUI``，在使用``/SILENT``和``/SUPPRESSMSGBOXES``参数时要加上它。

::

    name: My Game
    game_slug: my-game
    version: Installer
    slug: my-game-installer
    runner: wine

    script:
      game:
        exe: $GAMEDIR/drive_c/game/bin/Game.exe
        args: --some-arg
        prefix: $GAMEDIR
        working_dir: $GAMEDIR/drive_c/game
      files:
      - installer: "N/A:Select the game's setup file"
      installer:
      - task:
          args: /SILENT /LANG=en /SP- /NOCANCEL /SUPPRESSMSGBOXES /NOGUI /DIR="C:/game"
          executable: installer
          name: wineexec

示例GOG Wine游戏，使用innoextract直接解压::

    name: My Game
    game_slug: my-game
    version: Installer
    slug: my-game-installer
    runner: wine

    script:
      game:
        exe: $GAMEDIR/drive_c/Games/YourGame/game.exe
        args: --some-arg
        prefix: $GAMEDIR/prefix
      files:
      - installer: "N/A:Select the game's setup file"
      installer:
      - execute:
          args: --gog -d "$CACHE" setup
          description: Extracting game data
          file: innoextract
      - move:
          description: Extracting game data
          dst: $GAMEDIR/drive_c/Games/YourGame
          src: $CACHE/app


示例GOG Linux游戏（mojosetup的命令行选项在此记录：https://www.reddit.com/r/linux_gaming/comments/42l258/fully_automated_gog_games_install_howto/）::

    name: My Game
    game_slug: my-game
    version: Installer
    slug: my-game-installer
    runner: linux

    script:
      game:
        exe: $GAMEDIR/game.sh
        args: --some-arg
        working_dir: $GAMEDIR
      files:
      - installer: "N/A:Select the game's setup file"
      installer:
      - chmodx: installer
      - execute:
          file: installer
          description: Installing game, it will take a while...
          args: -- --i-agree-to-all-licenses --noreadme --nooptions --noprompt --destination=$GAMEDIR


另一个示例GOG Linux游戏::

    name: My Game
    game_slug: my-game
    version: Installer
    slug: my-game-installer
    runner: linux

    script:
      files:
      - goginstaller: N/A:Please select the GOG.com Linux installer
      game:
        args: --some-arg
        exe: start.sh
      installer:
      - extract:
          dst: $CACHE/GOG
          file: goginstaller
          format: zip
      - merge:
          dst: $GAMEDIR
          src: $CACHE/GOG/data/noarch/


示例Steam Linux游戏::

    name: My Game
    game_slug: my-game
    version: Installer
    slug: my-game-installer
    runner: steam

    script:
      game:
        appid: 227300
        args: --some-args

