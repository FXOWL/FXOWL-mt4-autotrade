# VsCodeの設定について

## 推奨する拡張機能

* [compilemql4](https://github.com/KeisukeIwabuchi/compilemql4)  
mt4の実行ファイルのパスを設定することで、VSCode上からコンパイルする事が出来ます。  
mql5でも使用可能。

* [doxdocgen](https://github.com/cschlosser/doxdocgen)  
関数やクラスの直前にコメントを作成する際に使用しています。

* MQL Extension Pack  
    以下の拡張機能が含まれています。
    1. [MQL4 Syntax Highlight](https://marketplace.visualstudio.com/items?itemName=nervtech.mq4)  
        MQL4のコードに色付けして強調表示してくれます。
    1. [MQL Snippets](https://github.com/nicholishen/mql-snippets-for-VScode)  
        MQLの組み込み関数、ENUMS、定義済み変数、キーワードのスニペット(全てではなく80%程カバーとのこと)  
    1. [MQL-syntax-over-cpp](https://marketplace.visualstudio.com/items?itemName=nicholishen.mql-over-cpp)  
    c++ 上で実行されるMQL シンタックス ハイライト。
    C++ コンパイラが必要。  
    1. [C/C++ Intellisence](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools)  
    MQL-syntax-over-cppを使用することでc++のインテリセンスが使用できる。  
    C++ コンパイラが必要。  

## その他

* formatter  
私はメタエディターの標準のフォーマットが見にくかったので、「clang-format」を使用しています。標準が良いという方は「.clang-format」を修正するか、削除してください。
