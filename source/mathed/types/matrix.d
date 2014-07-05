// Written in the D programming language
/**
 * Implementation of mathematic matrix. 
 * 
 * It is created at compile time with main settings: `Type` - type of inner
 * data, `Lines` - quantity of matrix lines, and `Cols` - quantity of matrix
 * columns. Then, in runtime, matrix is initialized by numbers.
 * 
 * Examples:
 * --------------------
 * auto m = Matrix!(int, 3, 3)
 * (
 *      3, -1, 6,
 *      2,  1, 5,
 *     -3,  1, 0
 * );
 * --------------------
 * 
 * Created structure can be treated as a mathematic matrix. Matrix could be added to
 * another matrix, it could be multiplied by number or another matrix, and so
 * on.
 * 
 * Examples:
 * --------------------
 * auto x = m + m; // x =  6, -2, 12,
 *                 //      4,  2, 10,
 *                 //     -6,  2,  0
 * 
 * auto y = m * 2  // y =  6, -2, 12,
 *                 //      4,  2, 10,
 *                 //     -6,  2,  0
 * 
 * auto n = Matrix!(int, 3, 2)
 * (
 *     3, 4,
 *     1, 0,
 *     5, 2
 * );
 * 
 * auto z = m * n  // z = 38,  24,
 *                 //     32,  18,
 *                 //     -8, -12
 * --------------------
 */
module mathed.types.matrix;

private
{
    import std.traits : hasMember, isStaticArray, isNumeric, 
        isBoolean, isSomeString;
    import std.conv : to;   
}

alias Matrix!(float, 2, 2) Matrix2f;
alias Matrix!(float, 3, 3) Matrix3f;
alias Matrix!(float, 4, 4) Matrix4f;

alias Matrix!(int, 2, 2) Matrix2i;
alias Matrix!(int, 3, 3) Matrix3i;
alias Matrix!(int, 4, 4) Matrix4i;

/**
 * Main matrix interface
 */
struct Matrix (Type, size_t Lines, size_t Cols)
{
    alias Matrix!(Type, Lines, Cols) Self;

    // Main matrix container. It keeps all matrix data.
    private  Type[Cols][Lines] _this;

    // Methods return matrix column and line quantity
    pure nothrow @safe static @property 
    {
        auto cols () { return Cols; }
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
     * Matrix constructor.
     * 
     * Params:
     *        values  =      array of new matrix values.
     */
    nothrow @safe this (Type[Lines * Cols] values...) { set (values); }

    /**
     * Method sets all matrix values in one action.
     * 
     * Params:
     *        values  =      array of setting matrix values.
     */
    nothrow @safe void set (Type[Lines * Cols] values...)
    {
        size_t index = 0;
        foreach (i; 0..Lines)
        {
            foreach (j; 0..Cols)
            {
                _this[i][j] = values[index];
                index++;
            }
        }
    }

    unittest
    {
        auto m = Matrix3i
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );

        m.set
        (
            0, 0, 0,
            0, 0, 0,
            0, 0, 0
        );

        assert (m[0][0] == 0);
    }

    /**
     * Method stringifies matrix data.
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
     * Method returns matrix line.
     * 
     * Params:
     *        lineIndex  =      index of calling matrix line
     * 
     * Returns: matrix line as static array.
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

    int opApply (int delegate (size_t, size_t, Type) foreach_)
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

    unittest
    {
        auto m = Matrix3i
        (
             3, -1, 6,
             2,  1, 5,
            -3,  1, 0
        );
        
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
     * Method implements matrix addition. Adding matrix should be equal by type,
     * lines and colums quantity.
     * 
     * Params:
     *        summand  =      adding matrix.
     * 
     * Returns: result matrix.
     */
    nothrow @safe auto opBinary (string op)(Self summand)
        if (op == "+" || op == "-")
    {
        Type[Cols * Lines] newMatrix;

        size_t index;
        foreach (i; 0..Lines)
        {
            foreach (j; 0..Cols)
            {
                mixin ("newMatrix[index] = _this[i][j] " ~ op ~ " summand[i][j];");
                index++;
            }
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
     * Method implements matrix multiplication by number. 
     * 
     * Params:
     *        num  =      multiplication number.
     * 
     * Returns: result matrix;
     */
    nothrow @safe auto opBinary (string op, T)(T num)
        if (op == "*" && isNumeric!(T))
    {
        Type[Lines * Cols] newMatrix;
        
        auto index = 0;
        foreach (i; 0..Lines)
        {
            foreach (j; 0..Cols)
            {
                newMatrix[index] = _this[i][j] * num;
                index++;
            }
        }
        
        return Self (newMatrix);
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
     * Method implements matrix multiplication by matrix. Multiplication matrix
     * should have lines quantity equal to current matrix columns quantity. If
     * it is not correct, error will be shown at compile time. 
     * 
     * Params:
     *        factor  =      multiplication matrix.
     * 
     * Returns: result matrix;
     */
    nothrow @safe auto opBinary (string op, T)(T factor)
        if (op == "*" && isMatrix!(T))
    in { static assert (Cols == T.lines); }
    body
    {
        Type[Lines * T.cols] newMatrix;
        
        auto index = 0;
        foreach (i; 0..Lines)
        {
            foreach (j; 0..T.cols)
            {
                Type result = 0;
                foreach (k; 0..Cols)
                    result += _this[i][k] * factor[k][j];
                
                newMatrix[index] = result;
                index++;
            }
        }
        
        return Matrix!(Type, Lines, factor.cols)(newMatrix);
    }

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
}

/**
 * Template checks type for being a matrix.
 * 
 * Params:
 *        Type  =      tesing type.
 */
pure nothrow @safe template isMatrix (Type)
{
    enum isMatrix = is (typeof (isMatrixImpl (Type.init)));
}

private void isMatrixImpl (Type, size_t Lines, size_t Cols)
                          (Matrix!(Type, Lines, Cols)){}

unittest
{
    auto v = Matrix2i (1, 2, 3, 4);
    auto i = 3;
    assert (isMatrix!(typeof (v)));
    assert (!isMatrix!(typeof (i)));
}