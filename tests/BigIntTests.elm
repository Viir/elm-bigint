module BigIntTests exposing (absTests, addTests, compareTests, divmodTests, fromTests, integer, isEvenTests, isOddTests, maxTests, minTests, minusOne, mulTests, negateTests, nonZeroInteger, one, powTests, roundRobinTests, singleNonZeroInteger, smallInt, smallPositiveIntegers, stringTests, subTests, tinyInt, tinyPositiveInt, zero)

import BigInt exposing (..)
import Constants exposing (maxDigitValue)
import Expect
import Fuzz exposing (Fuzzer, int, intRange, pair)
import Hex
import Random
import String
import Test exposing (..)


integer : Fuzzer BigInt
integer =
    Fuzz.map fromInt int


maxIntRange : Fuzzer Int
maxIntRange =
    intRange Random.minInt Random.maxInt


trickyIntRange : Fuzzer Int
trickyIntRange =
    intRange 1234567811345670 1234567812345678


smallPositiveIntegers : Fuzzer Int
smallPositiveIntegers =
    intRange 0 Random.maxInt


singleNonZeroInteger : Fuzzer BigInt
singleNonZeroInteger =
    integer
        |> Fuzz.map
            (\i ->
                if i == zero then
                    one

                else
                    i
            )


nonZeroInteger : Fuzzer BigInt
nonZeroInteger =
    Fuzz.map2 mul singleNonZeroInteger singleNonZeroInteger


zero : BigInt
zero =
    fromInt 0


one : BigInt
one =
    fromInt 1


minusOne : BigInt
minusOne =
    fromInt -1


smallInt : Fuzzer Int
smallInt =
    intRange (Basics.negate maxDigitValue) maxDigitValue


tinyInt : Fuzzer Int
tinyInt =
    intRange -5 5


tinyPositiveInt : Fuzzer Int
tinyPositiveInt =
    intRange 0 11


fromTests : Test
fromTests =
    describe "from"
        [ test "fromString 9999999 = fromInt 9999999" <|
            \_ ->
                let
                    fromString =
                        BigInt.fromIntString "9999999"

                    fromInt =
                        BigInt.fromInt 9999999
                in
                Expect.equal fromString (Just fromInt)
        , test "fromString 10000000 = fromInt 10000000" <|
            \_ ->
                let
                    fromString =
                        BigInt.fromIntString "10000000"

                    fromInt =
                        BigInt.fromInt 10000000
                in
                Expect.equal fromString (Just fromInt)
        , test "fromString 10000001 = fromInt 10000001" <|
            \_ ->
                let
                    fromString =
                        BigInt.fromIntString "10000001"

                    fromInt =
                        BigInt.fromInt 10000001
                in
                Expect.equal fromString (Just fromInt)
        , test "fromHexString 0x2386f26fc10000 = mul (fromInt 100000000) (fromInt 100000000)" <|
            \_ ->
                let
                    fromString =
                        BigInt.fromHexString "0x2386f26fc10000"

                    midLargeInt =
                        BigInt.fromInt 100000000

                    fromInt =
                        BigInt.mul midLargeInt midLargeInt
                in
                Expect.equal fromString (Just fromInt)
        , test "fromHexString 2386f26fc10000 = mul (fromInt 100000000) (fromInt 100000000)" <|
            \_ ->
                let
                    fromString =
                        BigInt.fromHexString "2386f26fc10000"

                    midLargeInt =
                        BigInt.fromInt 100000000

                    fromInt =
                        BigInt.mul midLargeInt midLargeInt
                in
                Expect.equal fromString (Just fromInt)
        , test "fromString 0 = fromInt 0" <|
            \_ -> Expect.equal (BigInt.fromIntString "0") (Just <| BigInt.fromInt 0)
        , test "fromString \"\" = Nothing" <|
            \_ -> Expect.equal (BigInt.fromIntString "") Nothing
        , test "fromString + = Nothing" <|
            \_ -> Expect.equal (BigInt.fromIntString "+") Nothing
        , test "fromString - = Nothing" <|
            \_ -> Expect.equal (BigInt.fromIntString "-") Nothing
        , test "fromHexString 0x0 = fromInt 0" <|
            \_ -> Expect.equal (BigInt.fromHexString "0x0") (Just <| BigInt.fromInt 0)
        , test "fromHexString -0x0 = fromInt 0" <|
            \_ -> Expect.equal (BigInt.fromHexString "-0x0") (Just <| BigInt.fromInt 0)
        , test "fromHexString \"\" = Nothing" <|
            \_ -> Expect.equal (BigInt.fromHexString "") Nothing
        , test "fromHexString + = Nothing" <|
            \_ -> Expect.equal (BigInt.fromHexString "+") Nothing
        , test "fromHexString - = Nothing" <|
            \_ -> Expect.equal (BigInt.fromHexString "-") Nothing
        , test "fromHexString 0x = Nothing" <|
            \_ -> Expect.equal (BigInt.fromHexString "0x") Nothing
        , test "fromHexString --0x0 = Nothing" <|
            \_ -> Expect.equal (BigInt.fromHexString "--0x0") Nothing
        , test "fromIntString --23 = Nothing" <|
            \_ -> Expect.equal (BigInt.fromIntString "--23") Nothing
        ]


roundRobinTests : Test
roundRobinTests =
    let
        complexRoundRobin int_ =
            fromInt int_
                |> toHexString
                |> fromHexString
                |> Maybe.andThen (toString >> fromIntString)
    in
    describe "complex round robin: fromInt -> toHexString -> fromHexString -> toString -> fromString"
        [ fuzz maxIntRange "large int range" <|
            \x ->
                complexRoundRobin x
                    |> Expect.equal (Just <| fromInt x)
        , fuzz trickyIntRange "tricky int range" <|
            \x ->
                complexRoundRobin x
                    |> Expect.equal (Just <| fromInt <| x)
        ]


addTests : Test
addTests =
    describe "addition"
        [ fuzz (pair smallInt smallInt) "add x y = x + y for small numbers" <|
            \( x, y ) ->
                add (fromInt x) (fromInt y)
                    |> Expect.equal (fromInt (x + y))
        , fuzz (pair integer integer) "x + y + (-y) = x" <|
            \( x, y ) ->
                add x y
                    |> add (BigInt.negate y)
                    |> Expect.equal x
        , fuzz (pair integer integer) "a + b = b + a" <|
            \( a, b ) -> Expect.equal (add a b) (add b a)
        ]


negateTests : Test
negateTests =
    describe "negate"
        [ fuzz int "negate x = -x; x >= 0" <|
            \x ->
                let
                    y =
                        Basics.abs x
                in
                fromInt y
                    |> BigInt.negate
                    |> Expect.equal (fromInt (-1 * y))
        , fuzz int "negate (-x) = x; x >= 0" <|
            \x ->
                let
                    y =
                        Basics.abs x * -1
                in
                fromInt y
                    |> BigInt.negate
                    |> Expect.equal (fromInt (-1 * y))
        , fuzz integer "negate (negate x) = x" <|
            \a ->
                a
                    |> BigInt.negate
                    |> BigInt.negate
                    |> Expect.equal a
        ]


subTests : Test
subTests =
    describe "subtraction"
        [ fuzz (pair integer integer) "x - y = x + -y" <|
            \( x, y ) ->
                Expect.equal (sub x y) (add x (BigInt.negate y))
        , fuzz (pair integer integer) "a - b = -(b - a)" <|
            \( a, b ) -> Expect.equal (sub a b) (BigInt.negate (sub b a))
        ]


mulTests : Test
mulTests =
    describe "Mul testsuite"
        [ fuzz (pair smallInt smallInt) "mult x y = x * y for small numbers" <|
            \( x, y ) ->
                mul (fromInt x) (fromInt y)
                    |> Expect.equal (fromInt (x * y))
        , fuzz (pair integer nonZeroInteger) "(x * y) / y = x" <|
            \( x, y ) ->
                mul x y
                    |> (\n -> divmod n y)
                    |> Expect.equal (Just ( x, zero ))
        , fuzz (pair integer integer) "x * y = y * x" <|
            \( x, y ) ->
                Expect.equal (mul x y) (mul y x)
        ]


divmodTests : Test
divmodTests =
    describe "divmod"
        [ fuzz (pair integer nonZeroInteger) "definition" <|
            \( x, y ) ->
                case divmod x y of
                    Nothing ->
                        Expect.equal y (fromInt 0)

                    Just ( c, r ) ->
                        mul c y
                            |> add r
                            |> Expect.equal x
        ]


absTests : Test
absTests =
    describe "abs"
        [ fuzz integer "|x| = x; x >= 0 and |x| = -x; x < 0" <|
            \x ->
                if gte x zero then
                    Expect.equal (BigInt.abs x) x

                else
                    Expect.equal (BigInt.abs x) (BigInt.negate x)
        ]


stringTests : Test
stringTests =
    describe "toString and fromString"
        [ fuzz integer "fromString (toString x) = Just x" <|
            \x ->
                fromIntString (BigInt.toString x)
                    |> Expect.equal (Just x)
        , fuzz smallInt "match string formatting from core" <|
            \x ->
                BigInt.toString (fromInt x)
                    |> Expect.equal (String.fromInt x)
        , fuzz integer "accept '+' at the beginning of the string" <|
            \x ->
                let
                    y =
                        x
                            |> BigInt.abs
                            |> BigInt.toString
                in
                String.cons '+' y
                    |> fromIntString
                    |> Expect.equal (fromIntString y)
        , test "Basic toHexString" <|
            \_ ->
                let
                    fromBase16String =
                        BigInt.fromHexString "2386f26fc10000"

                    midLargeInt =
                        BigInt.fromInt 100000000

                    fromInt =
                        mul midLargeInt midLargeInt
                in
                Expect.equal
                    (Maybe.map BigInt.toHexString fromBase16String)
                    (Just "2386f26fc10000")
        , fuzz smallPositiveIntegers "Same results as rtfeldman/elm-hex" <|
            \x ->
                BigInt.toHexString (fromInt x)
                    |> Expect.equal (Hex.toString x)
        ]


minTests : Test
minTests =
    describe "min"
        [ fuzz (pair integer integer) "min x y = x; x <= y and min x y = y; x > y" <|
            \( x, y ) ->
                case BigInt.compare x y of
                    GT ->
                        Expect.equal (BigInt.min x y) y

                    _ ->
                        Expect.equal (BigInt.min x y) x
        ]


maxTests : Test
maxTests =
    describe "max"
        [ fuzz (pair integer integer) "min x y = y; x <= y and min x y = x; x > y" <|
            \( x, y ) ->
                case BigInt.compare x y of
                    LT ->
                        Expect.equal (BigInt.max x y) y

                    _ ->
                        Expect.equal (BigInt.max x y) x
        ]


compareTests : Test
compareTests =
    describe "compare"
        [ fuzz integer "x = x" <|
            \x ->
                Expect.equal True (x == x)
                    |> Expect.onFail "apparently x /= x"
        , fuzz (pair integer integer) "x <= x + y; y >= 0" <|
            \( x, y ) ->
                Expect.equal True (lte x (add x (BigInt.abs y)))
                    |> Expect.onFail "apparently !(x <= x + y); y >= 0"
        , fuzz (pair integer integer) "x >= x + y; y <= 0" <|
            \( x, y ) ->
                Expect.equal True
                    (gte x (add x (BigInt.abs y |> BigInt.negate)))
                    |> Expect.onFail "apparently !(x >= x + y); y <= 0"
        , fuzz (pair integer nonZeroInteger) "x < x + y; y > 0" <|
            \( x, y ) ->
                Expect.equal True
                    (lt x (add x (BigInt.abs y)))
                    |> Expect.onFail "apparently !(x < x + y); y > 0"
        , fuzz (pair integer nonZeroInteger) "x > x + y; y < 0" <|
            \( x, y ) ->
                Expect.equal True
                    (gt x (add x (BigInt.abs y |> BigInt.negate)))
                    |> Expect.onFail "apparently !(x > x + y); y < 0"
        ]


isEvenTests : Test
isEvenTests =
    describe "isEven"
        [ fuzz int "the `mod 2` of a number should be 0 if it is even" <|
            \x -> Expect.equal (isEven (fromInt x)) (Basics.modBy 2 x == 0)
        ]


isOddTests : Test
isOddTests =
    describe "isOdd"
        [ fuzz int "the `mod 2` of a number should be 1 if it is odd" <|
            \x -> Expect.equal (isOdd (fromInt x)) (Basics.modBy 2 x == 1)
        ]


powTests : Test
powTests =
    describe "exponentiation (pow)"
        [ fuzz (pair tinyInt tinyPositiveInt) "pow x y = y ^ x for small numbers" <|
            \( base, exp ) ->
                BigInt.toString (pow (fromInt base) (fromInt exp))
                    |> Expect.equal (BigInt.toString (fromInt (base ^ exp)))
        ]
