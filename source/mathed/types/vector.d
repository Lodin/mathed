// Written in the D programming language
/**
 * Implementation of vector as a list of values.
 * Features:
 * $(OL
 *      $(LI All vector actions is checked at compile time)
 *      $(LI Vector contains only it's data, and nothing additional)
 *      $(LI Almost all vector actions is `nothrow` and `@safe`)
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
 *           make vector like that:
 * 
 *           auto vec = Vector!(int, 2, "xy")(10, 20);
 * 
 *           Then you can call vector accessor:
 * 
 *           assert (vec.x == 10);
 *      )
 *      $(LI Multiletter accessor. To create vector with this type you should
 *           make vector like that:
 *           
 *           auto vec = Vector!(int, 2, "col|row")(10, 20);
 *           
 *           Accessor delimiter in the accessors string should be "|" or ",".
 *           Then you can call vector accessor:
 * 
 *           assert (vec.col == 10);
 *      )
 * )
 * 
 * Vector also has VectorType - a string that defines vector orientation:
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
    import mathed.types.matrix : Matrix, isMatrix, Matrix1i, Matrix3i;
    import std.traits : isNumeric;
    import std.array : appender, split;
    import std.conv : to;
    import std.string : format;
}

alias Vector!(float, 2) Vector2f;
alias Vector!(float, 3) Vector3f;
alias Vector!(float, 4) Vector4f;

alias Vector!(int, 2) Vector2i;
alias Vector!(int, 3) Vector3i;
alias Vector!(int, 4) Vector4i;

alias Vector!(int, 2, "xy")  Planei;
alias Vector!(int, 3, "xyz") Stereoi;

alias Vector!(float, 2, "xy")  Planef;
alias Vector!(float, 3, "xyz") Stereof;

/**
 * Main vector interface.
 */
struct Vector (Type, size_t Size, string Accessors = "", 
               string VectorType = "horizontal")
{
    static assert (CountAccessors (Accessors, Size) == 0 
                   || CountAccessors (Accessors, Size) == Size,
                   "Quantity of attribute accessors should be equal to vector "
                   ~ "size or be empty string, not " 
                   ~ CountAccessors (Accessors).to!string ());

    static assert (VectorType == "horizontal" || VectorType == "vertical",
                   "VectorType should be `horizontal` or `vertical`");

    alias Vector!(Type, Size, Accessors) Self;

    /*
     * Vector core array.
     */
    private Type[Size] _this;

    /**
     * Returns vector size (quantity of it's elements).
     */
    pure nothrow @safe static @property size_t size () { return Size; }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        assert (v.size == 3);
    }

    /**
     * Vector default constructor. 
     */
    nothrow @safe this (Type[Size] values...) { _this = values; }

    static if (Accessors != "")
        mixin (AttrAccessor (Accessors, Size));

    ///
    unittest
    {
        // Creating a vector with accessors
        auto v = Vector!(int, 3, "xyz")(1, 2, 3);

        // Testing accessor methods.
        assert (v.x == 1);
        assert (v.y == 2);
        assert (v.z == 3);
    }

    /**
     * Sets all vector values in one action.
     */
    nothrow @safe void set (Type[Size] values...) { _this = values; }

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
    string toString () { return _this.to!string (); }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        auto str = v.to!string ();
        assert (str == "[1, 2, 3]");
    }

    /**
     * Gives vector element.
     */
    nothrow @safe ref auto opIndex (size_t element)
    {
        return _this[element];
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        assert (v[1] == 2);
    }

    /**
     * Iterates vector.
     */
    int opApply (int delegate (size_t, Type) foreach_)
    {
        int result;
        
        foreach (size_t index, ref element; _this)
        {
            result = foreach_ (index, element);
            if (result) break;
        }
        
        return result;
    }

    /**
     * Processes vector addition and subtraction.
     */ 
    nothrow @safe Self opBinary (string op)(in Self summand) 
        if (op == "+" || op == "-")
    {
        Self result;

        foreach (i, ref element; result._this)
            mixin ("element = _this[i] " ~ op ~ " summand._this[i];");

        return result;
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
    nothrow @safe Self opBinary (string op, T)(in T num) 
        if ((op == "*" || op == "/") && !isVector!T)
    {
        Self result;

        foreach (i, ref element; result._this)
            mixin ("element = _this[i] " ~ op ~ " num;");

        return result;
    }

    nothrow @safe Self opBinaryRight (string op, T)(in T num)
        if ((op == "*" || op == "/") && !isVector!T)
    {
        return opBinary!op (num);
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        auto i = 2;
        assert (v * i == Vector3i (2, 4, 6));
    }

    /**
     * Processes vector multiplication with another vector. Due to mathematical
     * restrictions that vector can be multiplied or divided only by
     * perpendicular vector, both vectors should be converted to matrix and
     * then processed.
     */
    nothrow @safe auto opBinary (string op, T)(T factor)
        if (op == "*" && isVector!T)
    {
        return this.toMatrix () * factor.toMatrix ();
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        auto w = Vector!(int, 3, "", "vertical") (1, 2, 3);
        assert (v * w == Matrix1i(14));

        auto v2 = Vector!(int, 3, "", "vertical") (1, 2, 3);
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
     * Converts vector to one-lined or one-columned matrix depending on
     * VectorType.
     */
    nothrow @safe auto toMatrix ()
    {
        static if (VectorType == "vertical")
        {
            Type[1][Size] data;

            foreach (size_t i, ref element; _this)
                data[i][0] = element;

            auto result = Matrix!(Type, Size, 1)(data);
        }
        else
        {
            Type[Size][1] data;

            foreach (size_t i, ref element; _this)
                data[0][i] = element;

            auto result = Matrix!(Type, 1, Size)(data);
        }

        return result;
    }

    /**
     * Transposes vector.
     */
    @property nothrow @safe auto t ()
    {
        static if (VectorType == "vertical")
            return Vector!(Type, Size, Accessors, "horizontal")(_this);
        else
            return Vector!(Type, Size, Accessors, "vertical")(_this);
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        auto a = v.t * v;
        assert (v.t.toMatrix ().lines == 3);
    }

}

/**
 * Tests type to be a vector.
 */
pure nothrow @safe template isVector (Type)
{
    enum isVector = is (typeof (isVectorImpl (Type.init)));

    private void isVectorImpl (Type, size_t Size, string Accessors, string VectorType)
                              (Vector!(Type, Size, Accessors, VectorType)){}
}

unittest
{
    auto v = Vector3i (1, 2, 3);
    auto i = 3;
    assert (isVector!(typeof (v)));
    assert (!isVector!(typeof (i)));
}

private:

// Compile-time vector accessors counting.
size_t CountAccessors (string Accessors, size_t Size)
{
    if (Size == 1)
        return Accessors.length == 0 ? 0 : 1;
    else if (!Accessors.hasSymbol ('|') && !Accessors.hasSymbol (','))
        return Accessors.length;
    else
    {
        if (Accessors.hasSymbol ('|'))
            return Accessors.split ('|').length;
        else
            return Accessors.split (',').length;
    }
}

// Compile-time test for char existence in the string.
bool hasSymbol (string str, char sym)
{
    bool has;

    foreach (letter; str)
        if (letter == sym)
            has = true;

    return has;
}

// Compile-time generation of accessor methods.
string AttrAccessor (string Accessors, size_t Size)
{
    string result;
    string code = q{
        @property ref Type %1$s () { return _this[%2$s]; }
    };

    if (Size == 1 )
        result ~= format (code, Accessors, 0);
    else if (Size > 1 && !Accessors.hasSymbol ('|') && !Accessors.hasSymbol (','))
        foreach (size_t index, accessor; Accessors)
            result ~= format (code, accessor, index);
    else
    {
        string[] AccessorsList;

        if (Accessors.hasSymbol ('|'))
            AccessorsList = Accessors.split ('|');
        else if (Accessors.hasSymbol (','))
            AccessorsList = Accessors.split (',');

        foreach (size_t index, accessor; AccessorsList)
            result ~= format (code, accessor, index);
    }
    
    return result;
}