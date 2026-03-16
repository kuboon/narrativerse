---
name: ruby-rails
description: Guidelines and instructions for practicing Ruby code.
---

# keyword params

```ruby
# before
call_method(user: user)
# after
call_method(user:)
```

# 宣言より規約
可能な限り Rails の規約に従う。
既存コードで規約に反する箇所があり、宣言を省略できる場合は宣言を省略しても動作するように実装を変更する。
