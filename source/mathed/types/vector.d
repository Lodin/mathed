// Written in the D programming language
/**
 * Implementation of vector as a list of values.
 * Features:
 * $(OL
 *      $(LI All vector actions is checked at compile time)
 *      $(LI Vector contains only it's data, and nothing additional)
 *      $(LI Almost all vector actions is `pure` and `nothrow`)
 *      $(LI Vector can have one- and multiletter accessors)
 * )
 * 
 * Usage:
 * Create vector as in documentation below and treat it like a simple array (if
 * you want to take some data from vector or put it in) or number (if you need
 * to do some mathematical actions with vector).
 * 
 * Vector can have accessor - a named property method returning one of vector
 * element. Accessor can be two types:
 * $(OL
 *      $(LI One-letter accessor. To create vector with this type you should
 *           create vector like that:
 * 
 *           auto vec = Vector!(int, 2, "xy")(10, 20);
 * 
 *           Then you can call vector accessor:
 * 
 *           assert (vec.x == 10);
 *      )
 *      $(LI Multiletter accessor. To create vector with this type you should
 *           create vector like that:
 *           
 *           auto vec = Vector!(int, 2, "col,row")(10, 20);
 *           
 *           Accessor delimiter in the accessors string should be ",".
 *           Then you can call vector accessor:
 * 
 *           assert (vec.col == 10);
 *      )
 * )
 * 
 * Vector also has Orientation - a string that defines vector orientation:
 * `horizontal` or `vertical`. It is needed only when vector is converted to
 * matrix and by default is `horizontal`.
 * 
 * Copyright:
 *      Copyright Vlad Rindevich, 2014.
 * 
 * License:
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * 
 * Authors:
 *      Vlad Rindevich (rindevich.vs@gmail.com).
 */
module mathed.types.vector;

private 
{
    import mathed.types.matrix : Matrix, DefaultInit, isMatrix, Matrix1i, Matrix3i;
    import std.traits : isNumeric;
    import std.array : appender, split;
    import std.conv : to;
    import std.string : format;
}

alias Vector!2 Vector2f;
alias Vector!3 Vector3f;
alias Vector!4 Vector4f;

alias Vector!(2, int) Vector2i;
alias Vector!(3, int) Vector3i;
alias Vector!(4, int) Vector4i;

alias Vector!(2, float, "xy")  Planef;
alias Vector!(3, float, "xyz") Stereof;

alias Vector!(2, int, "xy")  Planei;
alias Vector!(3, int, "xyz") Stereoi;

deprecated alias Vector (Type, size_t Size, string Accessors = "",
                         string Orientation = "horizontal") = 
    Vector!(Size, Type, Accessors, Orientation);

/**
 * Main vector interface.
 */
struct Vector (size_t Size, Type = float, string Accessors = "", 
                        string Orientation = "horizontal")
    if (Size > 0)
{
    static assert (isAcceptableSize!(Accessors, Size),
                   format (INACCEPTABLE_SIZE, CountAccessors (Accessors)));

    static assert (isAcceptableType!Orientation,
                   format (INACCEPTABLE_TYPE, Orientation));

    private
    {
        alias Vector!(Size, Type, Accessors, Orientation) Self;
        
        /*
         * Vector core array.
         */
        static if (isNumeric!Type)
            Type[Size] data = mixin (DefaultInit (Size));
        else
            Type[Size] data;

        // Gets the `Accessors` string
        alias Accessors accessors;

        // Gets vector orientation
        alias Orientation orientation;
    }

    /// Gets vector size (quantity of it's elements).
    alias Size size;

    /// Gets type of vector data
    alias Type type;

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        assert (v.size == 3);
    }

@trusted:

    /**
     * Vector default constructor. 
     */
    this (Type[Size] values...) pure nothrow
    {
        set (values);
    }

    static if (Accessors != "")
        mixin (AttrAccessor (Accessors, Size));

    ///
    unittest
    {
        // Creating a vector with accessors
        auto v = Vector!(3, int, "xyz")(1, 2, 3);

        // Testing accessor methods.
        assert (v.x == 1);
        assert (v.y == 2);
        assert (v.z == 3);
    }

    /**
     * Sets all vector values in one action.
     */
    void set (Type[Size] values...) pure nothrow
    {
        foreach (size_t index, ref element; data)
            element = values[index];
    }

    ///
    unittest
    {
        // Creating vector
        auto v = Vector3i (1, 2, 3);

        // Change data in one action
        v.set (3, 2, 1);
        assert (v[0] == 3 && v[1] == 2 && v[2] == 1);
    }

    /**
     * Stringifies vector.
     */
    string toString () { return data.to!string (); } 

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        auto str = v.to!string ();
        assert (str == "[1, 2, 3]");
    }

    /**
     * Gets vector element.
     */
    ref auto opIndex (size_t element) pure nothrow
    {
        return data[element];
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        assert (v[1] == 2);
    }

    /**
     * Iterates vector.
     */
    int opApply (int delegate (ref Type) foreach_)
    {
        int result;
        
        foreach (size_t index, ref element; data)
        {
            result = foreach_ (element);
            if (result) break;
        }
        
        return result;
    }

    /// ditto
    int opApply (int delegate (ref size_t, ref Type) foreach_)
    {
        int result;
        
        foreach (size_t index, ref element; data)
        {
            result = foreach_ (index, element);
            if (result) break;
        }
        
        return result;
    }

    /**
     * Assigns vector to a new variable.
     */
    auto opAssign (NewVector)(in NewVector newVector) pure nothrow
        if (isConvertibleVectors!(NewVector, Self))
    { 
        foreach (size_t index, ref value; data)
            value = cast(Type) newVector.data[index];
    }

    unittest
    {
        auto a = Vector4i (0, 0, 0, 0);
        a = Vector4f (1, 2, 3, 4);
        
        assert (a[1] == 2);
        assert (is (typeof (a[0]) == int));
    }

    /**
     * Inverses vector sign.
     */
    auto opUnary(string op)() pure nothrow
        if( op == "-" )
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        return opBinary!"*" (-1);
    }

    /**
     * Processes vector addition and subtraction.
     */ 
    Self opBinary (string op, Summand)(in Summand summand) pure nothrow
        if ((op == "+" || op == "-") && isSimilarVectors!(Summand, Self))
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        Self newVector;
        foreach (size_t index, ref element; newVector.data)
            mixin ("element = data[index] " ~ op ~ " summand.data[index];");
        return newVector;
    }

    /// ditto
    void opOpAssign (string op, Summand)(in Summand summand) pure nothrow
        if ((op == "+" || op == "-") && isSimilarVectors!(Summand, Self))
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        this = opBinary!op (summand);
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        auto w = Vector3i (3, 2, 1);
        assert (v + w == Vector3i (4, 4, 4));
    }

    /**
     * Processes vector multiplication and division with number.
     */
    Self opBinary (string op, Number)(in Number num) pure nothrow
        if ((op == "*" || op == "/") && isNumeric!Number)
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        Self newVector;
        foreach (size_t index, ref element; newVector.data)
            mixin ("element = data[index] " ~ op ~ " num;");
        return newVector;
    }

    /// ditto
    Self opBinaryRight (string op, Number)(in Number num) pure nothrow
        if ((op == "*" || op == "/") && isNumeric!Number)
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        return opBinary!op (num);
    }

    /// ditto
    void opOpAssign (string op, Number)(in Number num) pure nothrow
        if ((op == "*" || op == "/") && isNumeric!Number)
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        this = opBinary!op (num);
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        assert (v * 2 == Vector3i (2, 4, 6));
        v *= 2;
        assert (v == Vector3i (2, 4, 6));
    }

    /**
     * Processes vector multiplication with another vector. Due to mathematical
     * restrictions that vector can be multiplied or divided only by
     * perpendicular vector, both vectors will be converted to matrix and
     * then processed.
     */
    auto opBinary (string op, Factor)(Factor factor) pure nothrow
        if (op == "*" && isVector!Factor)
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        return this.toMatrix () * factor.toMatrix ();
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        auto w = Vector!(3, int, "", "vertical") (1, 2, 3);
        assert (v * w == Matrix1i (14));

        auto v2 = Vector!(3, int, "", "vertical") (1, 2, 3);
        auto w2 = Vector3i (1, 2, 3);

        auto equalMatrix = Matrix3i
        (
            1, 2, 3,
            2, 4, 6,
            3, 6, 9
        );

        assert (v2 * w2 == equalMatrix);
    }

    /**
     * Processes casting vector to a new type.
     */
    NewType opCast (NewType)() pure nothrow
        if (isConvertibleVectors!(NewType, Self) && isNumeric!Type)
    {
        NewType newVector;
        
        foreach (size_t index, ref element; newVector.data)
            element = cast(NewType.type) data[index];
        
        return newVector;
    }

    Vector!(Size, NewType, Accessors, Orientation) castTo (NewType)()
        if (isConvertibleVectors!(Vector!(Size, NewType, Accessors, Orientation), Self)
            && isNumeric!Type)
    {
        return cast(Vector!(Size, NewType, Accessors, Orientation)) this;
    }

    unittest
    {
        auto v = Vector!(4, int)(1, 2, 3, 4);
        auto w = cast(Vector!4) v;
        auto x = v.castTo!double ();

        assert (is (w.type == float));
        assert (is (x.type == double));

        assert (is (typeof (w[0]) == float));
        assert (is (typeof (x[0]) == double));

        assert (isVector!w);
        assert (isVector!x);
    }

    /**
     * Casts vector to a string.
     */
    string opCast (NewType)()
        if (is (NewType == string))
    {
        return toString ();
    }

    /**
     * Converts vector to one-lined or one-columned matrix depending on
     * Orientation.
     */
    auto toMatrix () pure nothrow
    {
        static if (Orientation == "vertical")
            return Matrix!(Size, 1, Type)(data);
        else
            return Matrix!(1, Size, Type)(data);
    }

    /**
     * Transposes vector.
     */
    @property auto t () pure nothrow
    {
        static if (Orientation == "vertical")
            return Vector!(Size, Type, Accessors, "horizontal")(data);
        else
            return Vector!(Size, Type, Accessors, "vertical")(data);
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        assert (v.t.toMatrix ().lines == 3);
    }
}

/**
 * Tests type to be a vector.
 */
template isVector (Test)
{
    enum isVector = is (typeof (isVectorImpl!(Test.size, Test.type, Test.accessors, Test.orientation)(Test.init)));

    private void isVectorImpl (size_t Size, Type, string Accessors, string Orientation)
                              (Vector!(Size, Type, Accessors, Orientation)){}
}

/**
 * Tests variable to be a vector.
 */
template isVector (alias Variable)
{
    enum isVector = isVector!(typeof (Variable));
}

///
unittest
{
    auto v = Vector3i (1, 2, 3);
    auto i = 3;
    assert (isVector!v);
    assert (!isVector!i);
}

/**
 * Tests two vectors to have equal size, and similar types. It means that type
 * of testing vector should be implicity convertable to a type of original
 * vector
 */
template isSimilarVectors (Test, Original)
    if (isVector!Test && isVector!Original)
{
    enum isSimilarVectors = is (Test.type : Original.type)
        && Test.size == Original.size;
}

/// ditto
template isSimilarVectors (alias Test, alias Original)
    if (isVector!Test && isVector!Original)
{
    enum isSimilarVectors = isSimilarVectors!(typeof(Test), typeof(Original));
}

unittest
{
    assert (isSimilarVectors!(Vector3i, Vector3f));
    assert (!isSimilarVectors!(Vector3f, Vector3i));
}

/**
 * Tests two vectors to have equal size, and mutually convertable types. It
 * means that type of testing vector should be implicity convertable to a type
 * of original vector, or vice versa.
 */
template isConvertibleVectors (From, To)
    if (isVector!From && isVector!To)
{
    enum isConvertibleVectors = From.size == To.size
        && (is(From.type : To.type) || is(To.type : From.type));
}

/// ditto
template isConvertibleVectors (alias From, alias To)
    if (isVector!From && isVector!To)
{
    enum isConvertibleVectors = isConvertibleVectors (typeof(From), typeof(To));
}

unittest
{
    assert (isConvertibleVectors!(Vector3i, Vector3f));
    assert (isConvertibleVectors!(Vector3f, Vector3i));
}

private:

// Compile-time vector accessors counting.
size_t CountAccessors (string Accessors, size_t Size) pure @trusted
{
    if (Size == 1)
        return Accessors.length == 0 ? 0 : 1;
    else if (!Accessors.hasSymbol (','))
        return Accessors.length;
    else
        return Accessors.split (',').length;
}

// Compile-time test for char existence in the string.
bool hasSymbol (string str, char sym) pure nothrow @trusted
{
    bool has;

    foreach (ref letter; str)
        if (letter == sym)
            has = true;

    return has;
}

// Compile-time generation of accessor methods.
string AttrAccessor (string Accessors, size_t Size) pure @trusted
{
    string result;
    string code = q{
        @property ref Type %1$s () pure nothrow @trusted
        {
            return data[%2$s];
        }
    };

    if (Size == 1 )
        result ~= format (code, Accessors, 0);
    else if (Size > 1 && !Accessors.hasSymbol (','))
        foreach (size_t index, accessor; Accessors)
            result ~= format (code, accessor, index);
    else
    {
        string[] AccessorsList;

        if (Accessors.hasSymbol (','))
            AccessorsList = Accessors.split (',');

        foreach (size_t index, accessor; AccessorsList)
            result ~= format (code, accessor, index);
    }
    
    return result;
}

pure @trusted template isAcceptableSize (string Accessors, size_t Size)
{
    enum isAcceptableSize = CountAccessors (Accessors, Size) == 0 
                            || CountAccessors (Accessors, Size) == Size;
}

pure nothrow @trusted template isAcceptableType (string Type)
{
    enum isAcceptableType = Type == "horizontal" 
                            || Type == "vertical";
}

enum 
{
    NOT_NUMERIC_FORBIDDEN = "Impossible to apply mathematical action to "
                            ~ "not-numeric vector",
    INACCEPTABLE_SIZE = "Attribute accessors should be equal to vector size by "
                        ~ "quantity or be empty string, not %s",
    INACCEPTABLE_TYPE = "Orientation should be `horizontal` or `vertical`, not %s"
}
