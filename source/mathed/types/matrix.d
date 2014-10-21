// Written in the D programming language
/**
 * Implementation of matrix in mathematical definition.
 * Features:
 * $(OL
 *      $(LI All matrix actions is checked at compile time)
 *      $(LI Matrix contains only it's data, and nothing additional)
 *      $(LI Almost all matrix actions is `pure` and `nothrow`)
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

public import mathed.utils.traits : isMatrix, isSimilarMatrices,
    isConvertibleMatrices;

private
{
    import std.traits : isNumeric;
    import std.conv : to;
    import std.array : Appender, appender;
}

alias Matrix!(1, 1) Matrix1f;
alias Matrix!(2, 2) Matrix2f;
alias Matrix!(3, 3) Matrix3f;
alias Matrix!(4, 4) Matrix4f;

alias Matrix!(1, 1, int) Matrix1i;
alias Matrix!(2, 2, int) Matrix2i;
alias Matrix!(3, 3, int) Matrix3i;
alias Matrix!(4, 4, int) Matrix4i;

/**
 * Main matrix interface.
 */
struct Matrix (size_t Lines, size_t Cols, Type = float)
    if (Lines > 0 && Cols > 0)
{
    private
    {
        alias Matrix!(Lines, Cols, Type) Self;

        /*
         * Matrix core array.
         */
        static if (isNumeric!Type)
            Type[Lines * Cols] data = mixin (DefaultInit (Lines * Cols));
        else
            Type[Lines * Cols] data;
    }

    /// Gets quantity of matrix lines.
    alias Lines lines;

    /// Gets quantity of matrix columns.
    alias Cols cols;

    /// Gets type of matrix data
    alias Type type;

    unittest
    {
        auto m = Matrix!(2, 3, int)
        (
             3, -1, 6,
             2,  1, 5,
        );

        assert (m.cols == 3);
        assert (m.lines == 2);
    }

@trusted:

    /**
     * Matrix default constructor. It receives a bunch of values in amount
     * of product of matrix lines and columns.
     */
    this (in Type[Cols * Lines] values...) pure nothrow
    {
        set (values);
    }

    /**
     * Sets all matrix values in one action. It receives bunch of values.
     */
    void set (in Type[Cols * Lines] values...) pure nothrow
    {
        foreach (size_t index, ref element; data)
            element = values[index];
    }

    ///
    unittest
    {
        // Creating matrix
        auto m = Matrix3i
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );

        // Testing some value to be the same as added
        assert (m[2][0] == -3);

        // Setting all values to zero.
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
    string toString ()
    {
        Appender!string result = appender ("[");

        foreach (size_t index; 0..Lines)
            result.put (this[index].to!string ()
                        ~ (index != Lines - 1 ? ", " : ""));

        result.put ("]");

        return result.data;
    }

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
     * Gets matrix line.
     */
    ref auto opIndex (size_t line) pure nothrow
    {
        return data[Cols * line .. Cols + Cols * line];
    }

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
     * Iterates matrix without returning any element number.
     */
    int opApply (int delegate (ref Type) foreach_)
    {
        int result;
        
        foreach (ref element; data)
        {
            result = foreach_ (element);
            if (result) break;
        }
        
        return result;
    }

    /**
     * Iterates matrix by element number. E.g. returned number of m[1][2]
     * element in Matrix3x3 iteration will be `5`.
     */
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
     * Iterates matrix returning line and column number with element.
     */
    int opApply (int delegate (ref size_t, ref size_t, ref Type) foreach_)
    {
        int result;
        
        size_t line, col;
        foreach (size_t index, ref element; data)
        {
            result = foreach_ (line, col, element);
            col++;

            if (index == Cols - 1 + Cols * line)
            {
                line++;
                col = 0;
            }

            if (result) break;
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

        // Let's iterate matrix by element number
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
                break;
            }
        }
        assert (line == 1 && col == 2);
    }

    auto opAssign (NewMatrix)(in NewMatrix newMatrix) pure nothrow
        if (isConvertibleMatrices!(NewMatrix, Self))
    { 
        foreach (size_t index, ref value; data)
            value = cast(Type) newMatrix.data[index];
    }

    unittest
    {
        auto a = Matrix2i (0, 0, 0, 0);
        a = Matrix2f (1, 2, 3, 4);

        assert (a[0][1] == 2);
        assert (is (typeof (a[0][0]) == int));
    }

    /**
     * Inverses matrix sign
     */ 
    auto opUnary(string op)() pure nothrow
        if( op == "-" )
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        return opBinary!"*" (-1);
    }

    /**
     * Processes matrix addition and subtraction.
     */
    Self opBinary (string op, Summand)(in Summand summand) pure nothrow
        if ((op == "+" || op == "-") && isSimilarMatrices!(Summand, Self))
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        Self newMatrix;
        foreach (size_t index, ref element; newMatrix.data)
            mixin ("element = data[index] " ~ op ~ " summand.data[index];");
        return newMatrix;
    }

    /// ditto
    void opOpAssign (string op, Summand)(in Summand summand) pure nothrow
        if ((op == "+" || op == "-") && isSimilarMatrices!(Summand, Self))
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        this = opBinary!op (summand);
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
        m += m;

        auto equalX = Matrix3i
        (
             6, -2, 12,
             4,  2, 10,
            -6,  2,  0
        );

        assert (x == equalX);
        assert (m == equalX);
    }

    /**
     * Processes matrix multiplication and division with number.
     */
    Self opBinary (string op, T)(in T num) pure nothrow
        if ((op == "*" || op == "/") && isNumeric!T)
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        Self newMatrix;
        foreach (size_t index, ref element; newMatrix.data)
            mixin ("element = data[index] " ~ op ~ " num;");
        return newMatrix;
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
        auto m = Matrix3i
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );
        
        auto y = m * 5;
        auto yy = 5 * m;
        m *= 5;

        auto equalY = Matrix3i
        (
             15, -5, 30,
             10,  5, 25,
            -15,  5,  0
        );

        assert (y == equalY);
        assert (yy == equalY);
        assert (m == equalY);
    }

    /**
     * Processes matrix multiplication with another matrix.
     */
    auto opBinary (string op, Factor)(in Factor factor) pure nothrow
        if (op == "*" && isMatrix!Factor && Cols == Factor.lines
            && is (Factor.type : Type))
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        Matrix!(Lines, Factor.cols, Type) newMatrix;

        size_t line, col;
        foreach (ref element; newMatrix.data)
        {
            if (col == Factor.cols)
            {
                line++;
                col = 0;
            }

            foreach (k; 0 .. Cols)
                element += data[Cols * line + k] 
                           * factor.data[Factor.cols * k + col];

            col++;
        }

        return newMatrix;
    }

    /// ditto
    void opOpAssign (string op, Factor)(in Factor factor) pure nothrow
        if (op == "*" && isMatrix!Factor && Cols == Factor.lines
            && is (Factor.type : Type))
    in { static assert (isNumeric!Type, NOT_NUMERIC_FORBIDDEN); }
    body
    {
        this = opBinary!op (factor);
    }

    unittest
    {
        auto m = Matrix!(3, 3, int)
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );
        
        auto n = Matrix!(3, 2, int)
        (
            3, 4,
            1, 0,
            5, 2
        );
        
        auto z = m * n;

        auto equalZ = Matrix!(3, 2, int)
        (
            38,  24,
            32,  18,
            -8, -12
        );

        assert (z == equalZ);
    }

    /**
     * Casts matrix to a new type. It should be matrix type too, with equal
     * quantity of lines and cols.
     */
    NewType opCast (NewType)() pure nothrow
        if (isConvertibleMatrices!(NewType, Self) && isNumeric!Type)
    {
        NewType newMatrix;

        foreach (size_t index, ref element; newMatrix.data)
            element = cast(NewType.type) data[index];

        return newMatrix;
    }

    /// ditto
    Matrix!(Lines, Cols, NewType) castTo (NewType)()
        if (isConvertibleMatrices!(Matrix!(Lines, Cols, NewType), Self)
            && isNumeric!Type)
    {
        return cast(Matrix!(Lines, Cols, NewType)) this;
    }

    unittest
    {
        auto m = Matrix!(3, 3, int)
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );

        auto n = cast(Matrix!(3, 3)) m;
        auto l = m.castTo!double ();

        assert (is (n.type == float));
        assert (is (l.type == double));

        assert (is (typeof (n[0][0]) == float));
        assert (is (typeof (l[0][0]) == double));

        assert (isMatrix!n);
        assert (isMatrix!l);
    }

    /**
     * Casts matrix to a string.
     */
    string opCast (NewType)()
        if (is (NewType == string))
    {
        return toString ();
    }

    /**
     * Transposes matrix.
     */
    @property auto t () pure nothrow
    {
        Matrix!(Cols, Lines, Type) newMatrix;

        size_t line, col;
        foreach (ref element; newMatrix.data)
        {
            if (line == Lines)
            {
                col++;
                line = 0;
            }

            element = data[Cols * line + col];

            line++;
        }

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

        assert (m.t.t == m);
    }

    static if (Lines == Cols && isNumeric!Type)
    {
        /**
         * Returns indentity matrix instead of zero.
         */
        @trusted static @property Self identity () pure nothrow
        {
            Self newMatrix;
            newMatrix.data = mixin (ConstructIdentity ());
            return newMatrix;
        }

        /**
         * Makes matrix with diagonal consists of received values.
         */
        @trusted static Self diag (Type[Lines] values...) pure nothrow
        {
            Self newMatrix;

            size_t line, col, index;
            foreach (ref element; newMatrix.data)
            {
                if (col == Cols)
                {
                    line++;
                    col = 0;
                }

                if (line == col)
                {
                    element = values[index];
                    index++;
                }
                else
                    element = 0;

                col++;
            }

            return newMatrix;
        }
    }

private:

    static if (isNumeric!Type)
    {
        @trusted static string ConstructIdentity () pure nothrow
        {
            string buffer = "[ ";

            size_t line, col;
            foreach (size_t index; 0 .. Lines * Cols)
            {
                if (col == Cols)
                {
                    line++;
                    col = 0;
                }
                
                if (line == col)
                    buffer ~= "1, ";
                else
                    buffer ~= "0, ";
                
                col++;
            }

            return buffer ~= " ]";
        }
    }
}

package static @trusted string DefaultInit (size_t Size) pure nothrow
{
    string buffer = "[ ";
    foreach (size_t index; 0 .. Size)
        buffer ~= "0, ";
    return buffer ~ " ]";
}

private:

enum NOT_NUMERIC_FORBIDDEN = "Impossible to apply mathematical action to "
    ~ "not-numeric matrix";