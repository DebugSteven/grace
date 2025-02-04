# `grace`

Grace is a ready-to-fork implementation of a JSON-compatible functional
programming language with type inference.  You will most likely be interested in
Grace for one of two reasons:

* You need to implement a domain-specific language and you would like to begin
  from a quality existing implementation instead of building some half-baked
  language using JSON/YAML as a syntax tree

* You're interested in learning more about state-of-the-art algorithms for
  programming language theory by studying a clear and realistic reference
  implementation

If you're interested in code samples, then jump down to the
[Quick tour](#quick-tour) section.

## Features

Grace implements the following features so that you don't have to:

* Fast and maintainable parsing

  Grace uses a high-performance lexer in conjunction with an LR parsing package
  in order to guarantee efficient and predictable parsing performance.  This
  means that you can easily extend or amend Grace's grammar without taking
  special precautions to avoid performance pitfalls.

* JSON-compatible syntax

  Grace uses the same syntax as JSON for records, lists, and scalar values,
  which means that many JSON expression are already valid Grace expressions:

  ```dhall
  # This is valid Grace source code
  {
    "clients": [
      {
        "isActive": true,
        "age": 36,
        "name": "Dunlap Hubbard",
        "email": "dunlaphubbard@cedward.com",
        "phone": "+1 (890) 543-2508",
      },
      {
        "isActive": true,
        "age": 24,
        "name": "Kirsten Sellers",
        "email": "kirstensellers@emergent.com",
        "phone": "+1 (831) 564-2190",
      }
    ]
  }
  ```

  Don't like JSON syntax?  No problem, the grammar is easy to change.

* Bidirectional type-inference and type-checking

  Grace's type system is based on the
  [Complete and Easy Bidirectional Typechecking for Higher-Rank Polymorphism](https://www.cl.cam.ac.uk/~nk480/bidir.pdf)
  paper.  This algorithm permits most types to be inferred without type
  annotations and the remaining types can be inferred with a single top-level
  type annotation.

* JSON-compatible type system

  JSON permits all sorts of nonsense that would normally be rejected by typed
  languages, but Grace's type system is sufficiently advanced that most JSON
  expressions can be made valid with a type signature, like this:

  ```dhall
  [ 1, [] ] : List (exists (a : Type) . a)
  ```

  … and this doesn't compromise the soundness of the type system.

* [Dhall](https://dhall-lang.org/)-style file-path imports

  You can import subexpressions by referencing their relative or absolute paths.
  You can also import JSON in the way same way since Grace is a superset of
  JSON.

  For example, you can import JSON with a type annotation so that you don't
  need to amend the original JSON:

  ```dhall
  ./input.json : List (exists (a : Type) . a)
  ```

* Fast evaluation

  Grace implements [normalization by evaluation](https://en.wikipedia.org/wiki/Normalisation_by_evaluation)
  to efficiently interpret code.  Combined with parsing and type-checking
  optimizations this means that the interpreter will tear through any code you
  throw at it.

  The interpreter also doesn't need to warm up and has a low startup overhead of
  tens of milliseconds, so Grace is suitable for short-lived command-line
  tools.

* Fixes to several JSON design mistakes

  The Grace interpreter supports comments, leading/trailing commas, and unquoted
  field names for input code while still emitting valid JSON output.

  This means that you can use Grace as a starting point for an  ergonomic JSON
  preprocessor (similar to [jsonnet](https://jsonnet.org/), but with types).

* Error messages with source locations

  Grace generates accurate and informative source locations in error messages,
  such as this:

  ```
  Not a subtype

  The following type:

     Bool

  (input):1:18: 
    │
  1 │ [ { x: 1 }, { x: true } ]
    │                  ↑

  … cannot be a subtype of:

     Natural

  (input):1:8: 
    │
  1 │ [ { x: 1 }, { x: true } ]
    │        ↑
  ```

* Syntax highlighting and code formatting

  The interpreter highlights and auto-formats code, both for results and error
  messages.  Note that the code formatter does not preserve comments (in order
  to simplify the implementation).

* Open records and open unions

  Grace extends the bidirectional type-checking algorithm with support for
  inferring the types of open records (also known as
  [row polymorphism](https://en.wikipedia.org/wiki/Row_polymorphism)) and
  open unions (also known as [polymorphic variants](https://2ality.com/2018/01/polymorphic-variants-reasonml.html)).  This lets you easily work with records or
  sums where not all fields or alternatives are known in advance.

* Universal quantification and existential quantification

  Universal quantification lets you specify "generic" types (i.e. types
  parameterized on other types).

  Existential quantification lets you specify incomplete / partial types
  (i.e. types with holes that that the interpreter infers).

  Both universal and existential quantification work with types, open records,
  and open unions.

Also, the package and the code is extensively commented and documented to help
you get started making changes.

## Notable omissions

Grace does not support the following language features:

* Input / output ("IO")

  Grace only supports pure computation and doesn't support an effect system for
  managing or sequencing effects

* Type classes

  These require global coherence, which does not play nice with Dhall-style
  path-based imports

* User-defined datatypes

  All data types in Grace are anonymous (e.g. anonymous records and anonymous
  unions), and there is no concept of a data declaration

* Recursion or recursive data types

  This is the feature I'd most like to add, especially if there were some way
  to implement anonymous recursion, but I couldn't find a simple solution.

* String interpolation

  This is possible, but tricky, to lex, so I decided that it would be simpler
  to remove the feature.

Grace also does not support the following tooling:

* A REPL

  I would accept a pull request to add this and might even add this myself.  I
  just haven't gotten around to this.

* A language server

  I will accept pull requests for this, but I don't plan on maintaining a
  language server myself since it's a lot of work and is a large surface area
  to maintain.

* Code formatter that preserves comments

  I will probably reject pull requests to add this because I expect this would
  really clutter up the implementation and the concrete syntax tree.

* Extensive documentation

  Grace is not really meant to be used directly, but is instead intended to be
  forked and used as a starting point for your own language, so any
  documentation written for Grace would need to be substantially rewritten as
  you adjust the language to your needs.

  If you still need an example of a tutorial for a similar language that you can
  adapt, see
  [the Dhall language tour](https://docs.dhall-lang.org/tutorials/Language-Tour.html).

## Development

You can get started on changing the language to your liking by reading the
[CONTRIBUTING](./CONTRIBUTING.md) guide.

If you're interested in upstreaming your changes, then these are the issues and
pull requests I'm most likely to accept:

* Bug fixes

* Improving error messages

* Fixes to build against the latest version of GHC or dependencies

* Adding new built-ins

  … especially if they are likely to be widely used by downstream
  implementations.

* Adding features with a high power-to-weight ratio

  Basically, anything that isn't too complicated and likely to be generally
  useful is fair game, especially if it's easy for forks to delete or disable
  if they don't want it.

* Simpler and clearer ways of implementing existing functionality

  For example, if you think there's a way to simplify the type-checker,
  parser, or evaluator without too much regression in functionality then I'll
  probably accept it.

* Adding more comments or clearer contributing instructions

  … so that people can more easily adapt the language to their own use case.

* Syntactic sugar

  For example, I'd probably accept pull requests to compress the syntax for
  nested `forall`s or nested lambdas.

These are the issues and pull requests that I'm most likely to reject:

* Anything that significantly increases my maintenance burden

  This project is more of an educational resource, like an executable blog
  post, than a production-ready package.  So I commit to maintaining to this
  about as much as I commit to maintaining a blog post (which is to say: not
  much at all, other than to merge or reject pull requests).

* Anything that significantly deteriorates the clarity of the code

  It's far more important to me that this code is pedagogically useful than the
  code being production-ready.  Again, think of this project as an executable
  tutorial that people can learn from.

* Any request to publish binaries or official releases

  This project is made to be forked, not directly used.  If you want to publish
  anything, then fork the project and maintain binaries/releases yourself.

## Acknowledgments

Your fork doesn't need to credit me or this project, beyond what the
[BSD 3-clause license](./LICENSE) requires.  The only thanks I need is for
people to use Grace instead of creating yet another half-baked domain-specific
language using JSON or YAML.

## Quick tour

This section provides a lightning tour that covers all language features as
briefly as possible, directed at people who already have some experience with
typed and functional programming languages.

### Command line

This package builds a `grace` executable with the following command-line API:

```bash
$ grace --help
Usage: grace COMMAND
  Command-line utility for the Grace language

Available options:
  -h,--help                Show this help text

Available commands:
  format                   Format Grace code
  interpret                Interpret a Grace file
  builtins                 List all built-in functions and their types
```

```bash
$ grace interpret --help
Usage: grace interpret [--annotate] FILE [--color | --plain]
  Interpret a Grace file

Available options:
  --annotate               Add a type annotation for the inferred type
  FILE                     File to interpret
  --color                  Enable syntax highlighting
  --plain                  Disable syntax highlighting
  -h,--help                Show this help text
```

```bash
$ grace format --help
Usage: grace format [--color | --plain] [FILE]
  Format Grace code

Available options:
  --color                  Enable syntax highlighting
  --plain                  Disable syntax highlighting
  FILE                     File to format
  -h,--help                Show this help text
```

```bash
Usage: grace builtins [--color | --plain]
  List all built-in functions and their types

Available options:
  --color                  Enable syntax highlighting
  --plain                  Disable syntax highlighting
  -h,--help                Show this help text
```

For example:

```dhall
# ./example.grace
let greet = \name -> "Hello, " ++ name ++ "!"

in  greet "world"
```

```bash
$ grace interpret example.grace
```
```dhall
"Hello, world!"
```

… and you can specify `-` to process standard input instead of a file, like
this:

```bash
$ grace interpret - <<< '2 + 2'
```
```dhall
4
```

### Data

Grace supports the following Scalar types:

* `Bool`s, such as `false` and `true`

* `Natural` numbers, such as `0`, `1`, `2`, …

* `Integer`s, such as `-2`, `-1`, `0`, `1`, `2`, …

  `Natural` numbers are a subtype of `Integer`s

* `Double`s, such as `3.14159265`, `6.0221409e+23`, …

  `Integer`s are a subtype of `Double`s

* `Text`, such as `""`, `"Hello!"`, `"ABC"`, …

  `Text` supports JSON-style escape sequences

… and the following complex data structures:

* `List`s, such as `[]`, `[ 2, 3, 5 ]`, …

* `Optional` types, such as `null`

  There is no special syntax for a present `Optional` value.  Every type `T` is
  a subtype of `Optional T`.  For example:

  ```dhall
  [ 1, null ] : List (Optional Natural)
  ```

* Records, such as `{}`, `{ x: 2.9, y: -1.4 }`

  Record field names usually don't need to be quoted unless they require special
  characters

* Unions, such as `Left 1`, `Right True`

  Any identifer beginning with an uppercase character is a union tag.  You don't
  need to specify the type of the union, since union types are open and
  inferred.

Note that unions are the only data structure that is not JSON-compatible,
since JSON does not support unions.

You can nest complex data structures arbitrarily, such as this example list of
package dependencies:

```dhall
[ GitHub
    { "repository": "https://github.com/Gabriel439/Haskell-Turtle-Library.git"
    , "revision": "ae5edf227b515b34c1cb6c89d9c58ea0eece12d5"
    }
, Local { "path": "~/proj/optparse-applicative" }
, Local { "path": "~/proj/discrimination" }
, Hackage { "package": "lens", "version": "4.15.4" }
, GitHub
    { "repository": "https://github.com/haskell/text.git"
    , "revision": "ccbfabedea1cf5b38ff19f37549feaf01225e537"
    }
, Local { "path": "~/proj/servant-swagger" }
, Hackage { "package": "aeson", "version": "1.2.3.0" }
]
```

### Types and annotations

You can annotate a value with type using the `:` operator.  The left argument
to the operator is a value and the right argument is the expected type:

```dhall
  true : Bool
# ↑      ↑
# Value  Expected type
```

You can also ask to include the inferred type of an interpreted expression as
a type annotation using the `--annotate` flag:

```bash
$ grace interpret --annotate - <<< '[ 2, 3, 5 ]'
```
```dhall
[ 2, 3, 5 ] : List Natural
```

Here are some example values annotated with types::

```dhall
true : Bool

"Hello" : Text

1 : Natural

1 : Integer  # `Natural` numbers also type-check as `Integer`s

1 : Double   # All numbers type-check as `Double`s

1 : Optional Natural  # Everything type-checks as `Optional`, too

[ true, false ] : List Bool

[ ] : forall (a : Type) . List a

{ name: "John", age: 24 } : { name: Text, age: Natural }

Left 1 : forall (a : Alternatives) . < Left: Natural | a >

[ Left 1, Right true ]
  : forall (a : Alternatives) . List < Left: Natural | Right: Bool | a >
```

### Control

Grace supports some operators out-of-the-box, such as:

* Addition: `2 + 3`
* Multiplication: `2 * 3`
* Logical conjunction: `true && false`
* Logical disjunction: `true || false`
* Text concatenation: `"AB" ++ "CD"`

… and you can also consume boolean values using `if` / `then` / `else`
expressions:

```dhall
$ grace interpret - <<< 'if true then 0 else 1'
0
```

You can define immutable and lexically-scoped variables using the `let` and
`in` keywords:

```dhall
let name = "redis"

let version = "6.0.14"

in  name ++ "-" ++ version
```

You can access record fields using `.`:

```dhall
let record = { turn: 1, health: 100 }

in  record.turn
```

You can pattern match on a union using the `merge` keyword by providing a
record of handlers (one per alternative):

```dhall
let render
      : < Left: Double | Right: Bool > -> Text
      = merge
          { "Left": Double/show
          , "Right": \b -> if b then "true" else "false"
          }

in  [ render (Left 2.0), render (Right true) ]
```

There is no way to consume `Optional` values (not even using `merge`).  The
`Optional` type solely exists for compatibility with JSON (so that `null` is
not rejected).  If you actually want a usable `Optional` type then use a
union with constructors named `Some` or `None` (or whatever names you prefer):

```dhall
let values = [ Some 1, None { } ]

let toNumber = merge { Some: \n -> n, None: \_ -> 0 }

in  List/map toNumber values
```

If you don't care about JSON compatibility then you can edit the language to
remove `null` and `Optional`.

Grace supports anonymous functions using `\input -> output` syntax.  For
example:

```dhall
let twice = \x -> [ x, x ]

in  twice 2
```

You can also use the built-in functions, including:

* `Double/show : Double -> Text`

  Render any number as `Text` (including `Natural` numbers and `Integer`s,
  since they are subtypes of `Double`)

* `Integer/even : Integer -> Bool` and `Integer/odd : Integer -> Bool`

  Returns whether a number is `even` or odd respectively.  These are
  mainly included as reference implementations for how to implement a simple
  function.

* `List/fold : forall (a : Type) . forall (b : Type) . List a -> (a -> b -> b) -> b -> b`

  Canonical fold for a `List`, also known as a "right fold" or `foldr` in many
  languages

* `List/length : forall (a : Type) . List a -> Natural`

  Returns the length of a `List`

* `List/map : forall (a : Type) . forall (b : Type) . (a -> b) -> List a -> List b`

  Transform each element of a list using a function

* `Natural/fold : forall (a : Type) . Natural -> (a -> a) -> a -> a`

  Canonical fold for a `Natural` number

For an up-to-date list of builtin functions and their types, run
the `grace builtins` subcommand.

### Type checking and inference

By default, the type-checker will infer a polymorphic type for a function
if you haven't yet used the function:

```bash
$ grace interpret --annotate - <<< '\x -> [ x, x ]'
```
```dhall
(\x -> [ x, x ]) : forall (a : Type) . a -> List a
```

However, if you use the function at least once then the type-checker will
infer a monomorphic type by default, so code like the following:

```dhall
let twice = \x -> [ x, x ]

in  twice (twice 2)
```

… will be rejected with a type error like this:

```
Not a subtype

The following type:

   List Natural

./example.grace:1:19: 
  │
1 │ let twice = \x -> [ x, x ]
  │                   ↑

… cannot be a subtype of:

   Natural

./example.grace:1:14: 
  │
1 │ let twice = \x -> [ x, x ]
  │              ↑
```

… because the inner use of `twice` thinks `x` should be a `Natural` and the
outer use of `twice` thinks `x` shoud be a `List Natural`.

However, you can fix this by adding a type signature to make the universal
quantification explicit:

```dhall
let twice : forall (a : Type) . a -> List a         
          = \x -> [ x, x ]

in  twice (twice 2)
```

… and then the example type-checks.  You can read that type as saying that the
`twice` function works `forall` possible `Type`s that we could assign to `a`
(including both `Natural` and `List Natural`)..

You can also use existential quantification for parts of the type signature
that you wish to omit:

```dhall
let numbers : exists (a : Type) . List a
            = [ 2, 3, 5 ]

in  numbers
```

The type-checker will accept the above example and infer that the type `a`
should be `Natural`.  You can read that type as saying that there `exists` a
`Type` that we could assign to `a` that would make the type work, but we don't
care which one.

You don't need type annotations when the types of values exactly match, but
you do require type annotations to unify types when one type is a proper
subtype of another type.

For example, `Natural` and `Integer` are technically two separate types, so if
you stick both a positive and negative literal in a `List` then type-checking
will fail:

```bash
$ grace interpret - <<< '[ 3, -2 ]'
Not a subtype

The following type:

   Integer

(input):1:7: 
  │
1 │ [ 3, -2 ]
  │       ↑

… cannot be a subtype of:

   Natural

(input):1:3: 
  │
1 │ [ 3, -2 ]
  │   ↑
```

… but if you add an explicit type annotation then type-checking will succeed:

```bash
$ grace interpret - <<< '[ 3, -2 ] : List Integer'
```
```dhall
[ 3, -2 ]
```

There is one type that is a supertype of all types, which is
`exists (a : Type) . a` (sometimes denoted `⊤` in the literature), so you can
always unify two disparate types, no matter how different,  by giving them that
type annotation:

```bash
$ grace interpret - <<< '[ { }, \x -> x ] : List (exists (a : Type) . a)'
```
```dhall
[ { }, \x -> x ]
```

Note that if you existentially quantify a value's type then you can't do
anything meaningful with that value; it is now a black box as far as the
language is concerned.

### Open records and unions

The interpreter can infer polymorphic types for open records, too.  For
example:

```bash
$ grace interpret --annotate - <<< '\x -> x.foo'
```
```dhall
(\x -> x.foo) : forall (a : Type) . forall (b : Fields) . { foo: a, b } -> a
```

You can read that type as saying that `\x -> x.foo` is a function from a record
with a field named `foo` to the value of that field.  The function type also
indicates that the function works no matter what type of value is present within
the `foo` field and also works no matter what other fields might be present
within the record `x`.

You can also use existential quantification to unify records with mismatched
sets of fields.  For example, the following list won't type-check without a
type annotation because the fields don't match:

```bash
$ grace interpret - <<< '[ { x: 1, y: true }, { x: 2, z: "" } ]'
Record type mismatch

The following record type:

   { z: Text }

(input):1:22: 
  │
1 │ [ { x: 1, y: true }, { x: 2, z: "" } ]
  │                      ↑

… is not a subtype of the following record type:

   { y: Bool }

(input):1:3: 
  │
1 │ [ { x: 1, y: true }, { x: 2, z: "" } ]
  │   ↑

The former record has the following extra fields:

• z

… while the latter record has the following extra fields:

• y
```

… but if we're only interested in the field named `x` then we can use a
type annotation to tell the type-checker to ignore all of the other fields by
existentially quantifying them:

```dhall
[ { x: 1, y: true }, { x: 2, z: "" } ]
    : List (exists (a : Fields) . { x: Natural, a })
```

… and we can write a function that consumes this list if the function only
accesses the field named `x`:

```dhall
let values
      : List (exists (a : Fields) . { x: Natural, a })
      =  [ { x: 1, y: true }, { x: 2, z: "" } ]

let handler
      : forall (a : Fields) . { x : Natural, a } -> Natural
      = \record -> record.x

in  List/map handler values
```

The compiler also infers universally quantified types for union alternatives,
too.  For example:

```bash
$ grace interpret --annotate - <<< '[ Left 1, Right true ]'
```
```dhall
[ Left 1, Right true ]
  : forall (a : Alternatives) . List < Left: Natural | Right: Bool | a >
```

The type is universally quantified over the extra union alternatives, meaning
that the union is "open" and we can keep adding new alternatives.  We don't
need to specify the desired type or set of alternatives in advance.

### Imports

You can import a Grace subexpression stored within a separate file by
referencing the file's relative or absolute path.

For example, instead of having one large expression like this:

```dhall
[ { "name": "Cake donut"
  , "batters": [ "Regular", "Chocolate", "Blueberry", "Devil's Food" ]
  , "topping": [ "None"
               , "Glazed"
               , "Sugar"
               , "Powdered Sugar"
               , "Chocolate with Sprinkles"
               , "Chocolate"
               , "Maple"
               ]
  }
, { "name": "Raised donut"
  , "batters": [ "Regular" ]
  , "topping": [ "None", "Glazed", "Sugar", "Chocolate", "Maple" ]
  }
, { "name": "Old Fashioned donut"
  , "batters": [ "Regular", "Chocolate" ]
  , "topping": [ "None", "Glazed", "Chocolate", "Maple" ]
  }
]
```

… you can split the expression into smaller files:

```dhall
# ./cake.grace

{ "name": "Cake donut"
, "batters": [ "Regular", "Chocolate", "Blueberry", "Devil's Food" ]
, "topping": [ "None"
             , "Glazed"
             , "Sugar"
             , "Powdered Sugar"
             , "Chocolate with Sprinkles"
             , "Chocolate"
             , "Maple"
             ]
}
```

```dhall
# ./raised.grace

{ "name": "Raised donut"
, "batters": [ "Regular" ]
, "topping": [ "None", "Glazed", "Sugar", "Chocolate", "Maple" ]
}
```

```dhall
# ./old-fashioned.grace

{ "name": "Old Fashioned donut"
, "batters": [ "Regular", "Chocolate" ]
, "topping": [ "None", "Glazed", "Chocolate", "Maple" ]
}
```

… and then reference them within a larger file, like this:

```dhall
[ ./cake.grace
, ./raised.grace
, ./old-fashioned.grace
]
```

You can also import functions in this way, too.  For example:

```dhall
# ./greet.grace

\name -> "Hello, " ++ name ++ "!"
```

```bash
$ grace interpret - <<< './greet.grace "John"'
```
```dhall
"Hello, John!"
```

Any subexpression can be imported in this way.

## Name

Like all of my programming language projects, Grace is named after a
character from PlaneScape: Torment, specifically
[Fall-from-Grace](https://torment.fandom.com/wiki/Fall-from-Grace), because
Grace is about
[slaking the intellectual lust](https://torment.fandom.com/wiki/Brothel_for_Slaking_Intellectual_Lusts)
of people interested in programming language theory.
