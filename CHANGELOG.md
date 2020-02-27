### 1.5.0

* OptionCollection no longer yields duplicate keys as an array, but instead yields each key in turn.

  For example, given an INI file:

    [test]
    a = 1
    a = 2
    b = 3

  IniParse would previously yield a single "a" key: an array containing two `Line`s:

    doc['test'].map { |line| line }
    # => [[<a = 1>, <a = 2>], <b = 3>]

  Instead, each key/value pair will be yielded in turn:

    doc['test'].map { |line| line }
    # => [<a = 1>, <a = 2>, <b = 3>]

  Directly accessing values via `[]` will still return an array of values as before:

    doc['test']['a']
    # => [1, 2]

* LineCollection#each may be called without a block, returning an Enumerator.

    doc = IniParse.parse(<<~EOF)
      [test]
      a = x
      b = y
    EOF

    doc[test].each
    # => #<Enumerator: ...>

  This allows for chaining as in the standard library:

    doc['test'].map.with_index { |a, i| { index: i, value: a.value } }
    # => [{ index: 0, value: 'x' }, { index: 1, value: 'y' }]
