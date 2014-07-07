// Written in the D programming language
/**
 * Implementation of matrix in mathematical definition.
 * Features:
 * $(OL
 *      $(LI All matrix actions is checked at compile time)
 *      $(LI Matrix contains only it's data, and nothing additional)
 *      $(LI Almost all matrix actions is `nothrow` and `@safe`)
 * )
 * 
 * Usage:
 * Just create matrix as in documentation below and treat it like a simple
 * two-dimensional array (if you want to get some data from matrix or put it in)
 * or number (if you need to do some mathematical action with matrix).
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
module mathed.types.matrix;

private
{
    import std.traits : isNumeric, isUnsigned, isFloatingPoint;
    import std.conv : to;   
}

alias Matrix!(float, 1, 1) Matrix1f;
alias Matrix!(float, 2, 2) Matrix2f;
alias Matrix!(float, 3, 3) Matrix3f;
alias Matrix!(float, 4, 4) Matrix4f;

alias Matrix!(int, 1, 1) Matrix1i;
alias Matrix!(int, 2, 2) Matrix2i;
alias Matrix!(int, 3, 3) Matrix3i;
alias Matrix!(int, 4, 4) Matrix4i;

/**
 * Main matrix interface.
 */
struct Matrix (Type, size_t Lines, size_t Cols)
{
    alias Matrix!(Type, Lines, Cols) Self;

    /*
     * Matrix core array.
     */
    private  Type[Cols][Lines] _this;

    static @property pure nothrow @safe 
    {
        /**
         * Returns quantity of matrix columns.
         */
        auto cols () { return Cols; }

        /**
         * Returns quantity of matrix lines.
         */
        auto lines () { return Lines; }
    }

    unittest
    {
        auto m = Matrix!(int, 2, 3)
        (
             3, -1, 6,
             2,  1, 5,
        );

        assert (m.cols == 3);
        assert (m.lines == 2);
    }

    /**
     * Matrix default constructor. It receives a bunch of values in amount
     * of product of matrix lines and columns.
     */
    nothrow @safe this (Type[Lines * Cols] values...) { set (values); }

    /**
     * Matrix additional constructor. It receives one static two-dimensional
     * array that is same to matrix core array. 
     */
    nothrow @safe this (Type[Cols][Lines] values) { _this = values; }

    /**
     * Sets all matrix values in one action. It receives bunch of values.
     */
    nothrow @safe void set (Type[Lines * Cols] values...)
    {
        size_t index;
        foreach (i, ref line; _this)
        {
            foreach (j, ref col; line)
            {
                col = values[index];
                index++;
            }
        }
    }

    /**
     * Additional `set` method. It receives two-dimensional array.
     */
    nothrow @safe void set (Type[Cols][Lines] values) { _this = values; }

    ///
    unittest
    {
        // Creating matrix
        auto m = Matrix!(int, 3, 3)
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );

        // Setting all values at zero.
        m.set
        (
            0, 0, 0,
            0, 0, 0,
            0, 0, 0
        );

        // Testing some values to be zero. 
        assert (m[0][0] == 0);
    }

    /**
     * Stringifies matrix data. 
     */
    string toString () { return _this.to!string (); }

    unittest
    {
        auto m = Matrix3i
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );

        auto str = m.to!string ();
        assert (str == "[[3, -1, 6], [2, 1, 5], [-3, 1, 0]]");
    }

    /**
     * Gives matrix line.
     */
    nothrow @safe ref auto opIndex (size_t lineIndex) { return _this[lineIndex]; }

    unittest
    {
        auto m = Matrix3i
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );

        assert (m[2][0] == -3);
    }

    /**
     * Iterates matrix in turn, excluding line and column numbers. E.g. in
     * Matrix3x3 iteration, returned number of m[1][2] element will be `5`.
     */
    int opApply (int delegate (ref size_t, ref Type) foreach_)
    {
        int result;

        size_t index;
        foreach (size_t i, ref line; _this)
        {
            foreach (size_t j, ref col; line)
            {
                result = foreach_ (index, col);
                index++;

                if (result) break;
            }
        }
        
        return result;
    }

    /**
     * Another iteration method. It returns line and column number with element.
     */
    int opApply (int delegate (ref size_t, ref size_t, ref Type) foreach_)
    {
        int result;
        foreach (size_t i, ref line; _this)
        {
            foreach (size_t j, ref col; line)
            {
                result = foreach_ (i, j, col);

                if (result) break;
            }
        }

        return result;
    }

    ///
    unittest
    {
        auto m = Matrix3i
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );

        // Let's iterate matrix in turn
        size_t index;
        foreach (i, ref element; m)
        {
            if (element == 5)
            {
                index = i;
                break;
            }
        }
        assert (index == 5);

        // Let's iterate matrix with line and column number
        size_t line, col;
        foreach (i, j, ref element; m)
        {
            if (element == 5)
            {
                line = i;
                col = j;
            }
        }
        assert (line == 1 && col == 2);
    }

    /**
     * Processes matrix addition and subtraction.
     */
    nothrow @safe auto opBinary (string op)(in Self summand)
        if (op == "+" || op == "-")
    in
    {
        static assert (!is(Type == bool),
                       "Impossible to apply mathematical action"
                       ~ "to boolean matrix");
    }
    body
    {
        Self newMatrix;

        foreach (i, ref line; newMatrix._this)
            foreach (j, ref col; line)
                mixin ("col = _this[i][j] " ~ op ~ " summand._this[i][j];");
        
        return newMatrix;
    }

    unittest
    {
        auto m = Matrix3i
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );

        auto x = m + m;

        auto equalX = Matrix3i
        (
             6, -2, 12,
             4,  2, 10,
            -6,  2,  0
        );

        assert (x == equalX);
    }

    /**
     * Processes matrix multiplication and division with number.
     */
    nothrow @safe auto opBinary (string op, T)(in T num)
        if ((op == "*" || op == "/") && isNumeric!T)
    in
    {
        static assert (!is(Type == bool),
                       "Impossible to apply mathematical action"
                       ~ "to boolean matrix");
    }
    body
    {
        Self newMatrix;
        
        foreach (i, ref line; newMatrix._this)
            foreach (j, ref col; line)
                mixin ("col = _this[i][j] " ~ op ~ " num;");
        
        return newMatrix;
    }

    unittest
    {
        auto m = Matrix3i
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );
        
        auto y = m * 5;

        auto equalY = Matrix3i
        (
             15, -5, 30,
             10,  5, 25,
            -15,  5,  0
        );

        assert (y == equalY);
    }

    /**
     * Processes matrix multiplication with another matrix.
     */
    nothrow @safe auto opBinary (string op, T)(in T factor)
        if (op == "*" && isMatrix!T)
    in
    {
        static assert (Cols == T.lines);
        static assert (!is(Type == bool),
                       "Impossible to apply mathematical action"
                       ~ "to boolean matrix");
    }
    body
    {
        Matrix!(Type, Lines, T.cols) newMatrix;

        foreach (i, ref line; newMatrix._this)
            foreach (j, ref col; line)
                foreach (k; 0..Cols)
                    mixin ("col += _this[i][k] " ~ op ~ " factor._this[k][j];");
        
        return newMatrix;
    }

    ///
    unittest
    {
        auto m = Matrix!(int, 3, 3)
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );
        
        auto n = Matrix!(int, 3, 2)
        (
            3, 4,
            1, 0,
            5, 2
        );
        
        auto z = m * n;

        auto equalZ = Matrix!(int, 3, 2)
        (
            38,  24,
            32,  18,
            -8, -12
        );

        assert (z == equalZ);
    }

    /**
     * Transposes matrix.
     */
    @property nothrow @safe t ()
    {
        Matrix!(Type, Cols, Lines) newMatrix;

        foreach (size_t i, ref line; newMatrix._this)
            foreach (size_t j, ref col; line)
                col = _this[j][i];

        return newMatrix;
    }

    unittest
    {
        auto m = Matrix!(int, 3, 3)
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );

        assert (m.t.t == m);
    }
}

/**
 * Tests type to be a matrix.
 */
pure nothrow @safe template isMatrix (Type)
{
    enum isMatrix = is (typeof (isMatrixImpl (Type.init)));

    private void isMatrixImpl (Type, size_t Lines, size_t Cols)
    (Matrix!(Type, Lines, Cols)){}
}

///
unittest
{
    auto v = Matrix2i (1, 2, 3, 4);
    auto i = 3;
    assert (isMatrix!(typeof (v)));
    assert (!isMatrix!(typeof (i)));
}