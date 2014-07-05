// Written in the D programming language
/**
 * Implementation of vector as a matrix with one line or column, and as matrix 
 * it follows the rules of actions with matrix. 
 * 
 * Vector has compile time settings: `Type`, `Elements` - quantity of vector
 * elements, `Accessors` - line of vector accessor methods (by default - empty
 * string), and `VectorType` - horizontal or vertical variant of vector. By
 * default it always is `horizontal` vector.
 * 
 * Examples:
 * --------------------
 * auto v = Vector!(int, 3)(3, -1, 6);
 * --------------------
 * 
 * New structure can be treated as a simple matrix. It can be added to another
 * vector, or multiplied by number or another vector. 
 * 
 * Examples:
 * --------------------
 * auto x = v + v; // x = 6, -2, 12
 * 
 * auto y = v * 5  // y = 15, -5, 30
 * 
 * auto w = Vector!(int, 2)(3, 4);
 * 
 * auto z = v * w  // z = 38,  24,
 *                 //     32,  18,
 *                 //     -8, -12
 * --------------------
 * 
 * Additionally, vector can have accessor methods to access it's elements.
 * Accessors could be two types:
 * 1) One-letter accessor. It can be defined in one string:
 * --------------------
 * auto m = Vector!(int, 2, "xy")(10, 20);
 * assert (m.x == 10);
 * --------------------
 * 
 * 2) Multiletter accessor. It should be defined in one string but splitted by
 * delimiters. Delimiters should be only `|` (vertical bar) or `,` (comma).
 * --------------------
 * auto m = Vector!(int, 2, "col|row")(10, 20);
 * assert (m.col == 10);
 * --------------------
 * 
 * If accessors is not needed, its' string should be empty.
 */

module mathed.types.vector;

private 
{
    import mathed.types.matrix : Matrix, isMatrix, Matrix3i;
    import std.traits : hasMember, isNumeric, isBoolean, isSomeString;
    import std.array : appender, split;
    import std.typetuple : TypeTuple;
    import std.conv : to;
    import std.string : indexOf, strip, format;
}

alias Vector!(float, 2) Vector2f;
alias Vector!(float, 3) Vector3f;
alias Vector!(float, 4) Vector4f;

alias Vector!(int, 2) Vector2i;
alias Vector!(int, 3) Vector3i;
alias Vector!(int, 4) Vector4i;

alias Vector!(int, 2, "xy")  Planei;
alias Vector!(int, 3, "xyz") Coordi;

alias Vector!(float, 2, "xy")   Planef;
alias Vector!(float, 3, "xyz")  Coordf;

/**
 * Main vector interface
 */
struct Vector (Type, size_t Elements, string Accessors = "", 
               string VectorType = "horizontal")
{
    static assert (VectorType == "horizontal" || VectorType == "vertical",
                   "Vector should be `horizontal` or `vertical`");

    static assert (CountAccessors (Accessors, Elements) == 0 
                   || CountAccessors (Accessors, Elements) == Elements,
                   "Quantity of attribute accessors should be equal to vector "
                   ~ "size or be empty string, not " 
                   ~ CountAccessors (Accessors).to!string ());

    static if (VectorType == "vertical")
        alias Matrix!(Type, Elements, 1) InnerMatrix;
    else
        alias Matrix!(Type, 1, Elements) InnerMatrix;

    alias Vector!(Type, Elements, Accessors, VectorType) Self;

    // Vector inner matrix which contains all vector data
    private InnerMatrix _this;

    // Methods return vector column and line quantity
    nothrow @safe static @property
    {
        auto cols () { return _this.cols; }
        auto lines () { return _this.lines; }
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);

        assert (v.cols == 3);
        assert (v.lines == 1);
    }

    /**
     * Vector constructor.
     * 
     * Params:
     *        values  =      array of new vector values.
     */
    nothrow @safe this (Type[Elements] values...) { set (values); }

    // Vector variable accessor methods
    static if (Accessors != "")
        mixin (AttrAccessor (Accessors, Elements, VectorType));

    unittest
    {
        auto v = Vector!(int, 3, "xyz")(1, 2, 3);
        assert (v.x == 1);
        assert (v.y == 2);
        assert (v.z == 3);
    }

    /**
     * Method sets all vector values in one action.
     * 
     * Params:
     *        values  =      array of setting vector values.
     */
    nothrow @safe void set (Type[Elements] values...) { _this = InnerMatrix (values); }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        v.set (3, 2, 1);
        assert (v[0] == 3 && v[1] == 2 && v[2] == 1);
    }

    /**
     * Method stringifies vector data.
     */
    string toString ()
    {
        static if (VectorType == "vertical")
            return _this.to!string ();
        else
            return _this[0].to!string ();
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        auto str = v.to!string ();
        assert (str == "[1, 2, 3]");
    }

    /**
     * Method returns vector value by it's index
     * 
     * Params:
     *        linesIndex  =      value index.
     */
    nothrow @safe ref auto opIndex (size_t linesIndex)
    {
        static if (VectorType == "vertical")
            return _this[linesIndex][0];
        else
            return _this[0][linesIndex];
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        assert (v[1] == 2);
    }

    /**
     * Method implements vector addition. Adding vector should be equal by type
     * and size.
     * 
     * Params:
     *        summand  =      adding vector.
     * 
     * Returns: result vector.
     */
    nothrow @safe auto opBinary (string op)(Self summand) 
        if (op == "+" || op == "-")
    {
        Self result;
        mixin ("result._this = _this " ~ op ~" summand._this;");
        return result;
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        auto w = Vector3i (3, 2, 1);
        assert (v + w == Vector3i (4, 4, 4));
    }

    /**
     * Method implements vector multiplication by number. 
     * 
     * Params:
     *        num  =      multiplication number.
     * 
     * Returns: result vector;
     */
    nothrow @safe auto opBinary (string op, T)(T num) 
        if ((op == "*" || op == "/") && isNumeric!T)
    {
        Self result;
        mixin ("result._this = _this " ~ op ~ " num;");
        return result;
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        auto i = 2;
        assert (v * i == Vector3i (2, 4, 6));
    }

    /**
     * Method implements vector multiplication by another vector. Multiplication
     * vector should be opposite by VectorType (e.g. if current vector is
     * `horizontal`, factor should be `vertical`) and have the same size. In
     * result it will be number with current type (`int`, `float`, etc.) or
     * square matrix.
     * 
     * Params:
     *        factor  =      multiplication vector.
     * 
     * Returns: result number or matrix.
     */
    nothrow @safe auto opBinary (string op, T)(T factor)
        if ((op == "*" || op == "/") && isVector!T)
    in 
    {
        static if (VectorType == "vertical")
            static assert (Elements == T.cols);
        else
            static assert (Elements == T.lines);
    }
    body
    {
        static if (VectorType == "vertical")
            return mixin ("_this " ~ op ~ " factor._this;");
        else
            return mixin ("(_this " ~ op ~ " factor._this)[0][0];");
    }

    unittest
    {
        auto v = Vector3i (1, 2, 3);
        auto w = Vector!(int, 3, "", "vertical") (1, 2, 3);
        assert (v * w == 14);

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
}

/**
 * Template checks type for being a vector.
 * 
 * Params:
 *        Type  =      tesing type.
 */
pure nothrow @safe template isVector (Type)
{
    enum isVector = is (typeof (isVectorImpl (Type.init)));
}

private void isVectorImpl (Type, size_t Elements, string Accessors, string VectorType)
                          (Vector!(Type, Elements, Accessors, VectorType)){}

unittest
{
    auto v = Vector3i (1, 2, 3);
    auto i = 3;
    assert (isVector!(typeof (v)));
    assert (!isVector!(typeof (i)));
}

private:

// Method counts accessors depending on it's content.
size_t CountAccessors (string Accessors, size_t Elements)
{
    if (Elements == 1)
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

// Method checks string for specified symbol.
bool hasSymbol (string str, char sym)
{
    bool has;

    foreach (letter; str)
        if (letter == sym)
            has = true;

    return has;
}

// Method generates accessors to vector elements by letters from a string. 
string AttrAccessor (string Accessors, size_t Elements, string VectorType)
{
    string result;
    string code;

    if (VectorType == "vertical")
    {
        code = q{
            @property ref Type @{funcName} () { return _this[@{number}][0]; }
        };
    }
    else
    {
        code = q{
            @property ref Type @{funcName} () { return _this[0][@{number}]; }
        };
    }

    if (Elements == 1 )
        result ~= render (code, ["funcName": Accessors, "number": "0"]);
    else if (Elements > 1 && !Accessors.hasSymbol ('|') && !Accessors.hasSymbol (','))
        foreach (size_t index, accessor; Accessors)
            result ~= render (code, ["funcName": accessor.to!string, "number": index.to!string]);
    else
    {
        string[] AccessorsList;

        if (Accessors.hasSymbol ('|'))
            AccessorsList = Accessors.split ('|');
        else if (Accessors.hasSymbol (','))
            AccessorsList = Accessors.split (',');

        foreach (size_t index, accessor; AccessorsList)
            result ~= render (code, ["funcName": accessor, "number": index.to!string]);
    }
    
    return result;
}

// Compile-time rendering of code templates.
// Author: Nicolas Sicard, https://github.com/biozic
string render (string templ, string[string] args)
{
    string markupStart = "@{";
    string markupEnd = "}";
    
    string result;
    auto str = templ;
    while (true)
    {
        auto p_start = indexOf(str, markupStart);
        if (p_start < 0)
        {
            result ~= str;
            break;
        }
        else
        {
            result ~= str[0 .. p_start];
            str = str[p_start + markupStart.length .. $];
            
            auto p_end = indexOf(str, markupEnd);
            if (p_end < 0)
                assert(false, "Tag misses ending }");
            auto key = strip(str[0 .. p_end]);
            
            auto value = key in args;
            if (!value)
                assert(false, "Key '" ~ key ~ "' has no associated value");
            result ~= *value;
            
            str = str[p_end + markupEnd.length .. $];
        }
    }
    
    return result;
}