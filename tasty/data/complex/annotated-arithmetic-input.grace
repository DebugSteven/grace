# This verifies that you can add and multiply numbers other than `Natural`
# numbers if you provide a type annotation
{ example0: (2 + -3) : Integer
, example1: (2 + -3.1) : Double
, example2: (2 * -3) : Integer
, example3: (2 * -3.1) : Double
}
