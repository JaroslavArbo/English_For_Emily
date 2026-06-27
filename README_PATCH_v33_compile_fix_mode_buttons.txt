EnglishForEmily complete project – v33 compile fix for mode buttons

Oprava:
- Nahrazeno .buttonStyle(.borderless) za kompatibilnější .buttonStyle(PlainButtonStyle()).
- Hit testing dlaždic režimů používá jednoduchý Rectangle().
- Build Number: 33
- Marketing Version: 2.0

Důvod:
Některé kombinace Xcode/iOS deployment targetu nemusí přijmout zkrácenou syntaxi .borderless.
