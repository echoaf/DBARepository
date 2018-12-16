https://alvinzhu.xyz/2017/10/07/python-pep-8/
https://zh-google-styleguide.readthedocs.io/en/latest/google-python-styleguide/python_style_rules/

====
## good
try:
    import psyco1
    # Psyco classes may be very useful
    from psyco.classes import __metaclass__
    psyco.bind(myfun1)
except ImportError: pass


====
## bad
words = 'me do bye taz foo bar'.split()

## good
words = ['me', 'do', 'bye', 'taz', 'foo', 'bar'] 



====
## bad
import sys
sys.exit()

## good
# To stop a console program:
raise SystemExit

#Or just:
exit()


====
foo = long_function_name(
    var_one, var_two,
    var_three, var_four)


====
来自非英语国家的Python程序员们，请使用英文来写注释，除非你120%确定你的代码永远不会被不懂你所用语言的人阅读到。


====
驼峰命名
CapitalizedWords (也叫做CapWords或者CamelCase – 因为单词首字母大写看起来很像驼峰)。也被称作StudlyCaps。
注意：当CapWords里包含缩写时，将缩写部分的字母都大写。HTTPServerError比HttpServerError要好。

mixedCase (注意：和CapitalizedWords不同在于其首字母小写！)
Capitalized_Words_With_Underscores (这种风格超丑！)

