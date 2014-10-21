module mathed.utils.traits;

version (unittest)
{
    private
    {
        import mathed.types.matrix : Matrix2i, Matrix3i, Matrix3f;
        import mathed.types.vector : Vector3i, Vector3f;
    }
}

/**
 * Tests type to be a matrix.
 */
template isMatrix (Test) 
{
    enum isMatrix = isMatrixImpl!Test;
}

/**
 * Tests variable to be a matrix.
 */
template isMatrix (alias Variable) 
{
    static if (!__traits (compiles, typeof (Variable)))
        enum isMatrix = isMatrixImpl!Variable;
    else
        enum isMatrix = isMatrixImpl!(typeof(Variable));
}

///
unittest
{
    auto v = Matrix2i (1, 2, 3, 4);
    auto i = 3;
    assert (isMatrix!v);
    assert (!isMatrix!i);
}

/**
 * Tests type to be a vector.
 */
template isVector (Test)
{
    enum isVector = isVectorImpl!Test;
}

/**
 * Tests variable to be a vector.
 */
template isVector (alias Variable)
{
    static if (!__traits (compiles, typeof (Variable)))
        enum isVector = isVectorImpl!Variable;
    else
        enum isVector = isVectorImpl!(typeof(Variable));
}

///
unittest
{
    auto v = Vector3i (1, 2, 3);
    auto i = 3;
    assert (isVector!v);
    assert (!isVector!i);
}

private:

template isMatrixImpl (Test)
{
    import mathed.types.matrix : Matrix;

    enum isMatrixImpl = is (typeof (Impl!(Test.lines, Test.cols, Test.type)(Test.init)));
    
    private void Impl (size_t Lines, size_t Cols, Type)
                      (Matrix!(Lines, Cols, Type)){}
}

template isVectorImpl (Test)
{
    import mathed.types.vector : Vector; 

    enum isVectorImpl = is (typeof (Impl!(Test.size, Test.type, Test.accessors, Test.orientation)(Test.init)));

    private void Impl (size_t Size, Type, string Accessors, string Orientation)
                              (Vector!(Size, Type, Accessors, Orientation)){}
}