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
 * Tests two matrix to have equal quantity of lines and cols, and similar types.
 * It means that type of testing matrix should be implicity convertable to a 
 * type of original matrix
 */
template isSimilarMatrices (Test, Original)
    if (isMatrix!Test && isMatrix!Original)
{
    enum isSimilarMatrices = isSimilarMatricesImpl!(Test, Original);
}

/// ditto
template isSimilarMatrices (alias Test, alias Original)
    if (isMatrix!Test && isMatrix!Original)
{
    static if (!__traits (compiles, typeof (Test)))
    {
        static if (!__traits (compiles, typeof (Original)))
            enum isSimilarMatrices = isSimilarMatricesImpl!(Test, Original);
        else
            enum isSimilarMatrices = isSimilarMatricesImpl!(Test, typeof (Original));
    }
    else
    {
        static if (!__traits (compiles, typeof (Original)))
            enum isSimilarMatrices = isSimilarMatricesImpl!(typeof (Test), Original);
        else
            enum isSimilarMatrices = isSimilarMatricesImpl!(typeof (Test), typeof (Original));
    }
}

unittest
{
    assert (isSimilarMatrices!(Matrix3i, Matrix3f));
    assert (!isSimilarMatrices!(Matrix3f, Matrix3i));
}

/**
 * Tests two matrix to have equal quantity of lines and cols, and mutually
 * convertable types. It means that type of testing matrix should be implicity
 * convertable to a type of original matrix, or vice versa.
 */
template isConvertibleMatrices (From, To)
    if (isMatrix!From && isMatrix!To)
{
    enum isConvertibleMatrices = isConvertibleMatricesImpl!(From, To);
}

/// ditto
template isConvertibleMatrices (alias From, alias To)
    if (isMatrix!From && isMatrix!To)
{
    static if (!__traits (compiles, typeof (From)))
    {
        static if (!__traits (compiles, typeof (To)))
            enum isConvertibleMatrices = isConvertibleMatricesImpl!(From, To);
        else
            enum isConvertibleMatrices = isConvertibleMatricesImpl!(From, typeof (To));
    }
    else
    {
        static if (!__traits (compiles, typeof (To)))
            enum isConvertibleMatrices = isConvertibleMatricesImpl!(typeof (From), To);
        else
            enum isConvertibleMatrices = isConvertibleMatricesImpl!(typeof (From), typeof (To));
    }
}

unittest
{
    assert (isConvertibleMatrices!(Matrix3i, Matrix3f));
    assert (isConvertibleMatrices!(Matrix3f, Matrix3i));
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

/**
 * Tests two vectors to have equal size, and similar types. It means that type
 * of testing vector should be implicity convertable to a type of original
 * vector
 */
template isSimilarVectors (Test, Original)
    if (isVector!Test && isVector!Original)
{
    enum isSimilarVectors = isSimilarVectorsImpl!(Test, Original);
}

/// ditto
template isSimilarVectors (alias Test, alias Original)
    if (isVector!Test && isVector!Original)
{
    static if (!__traits (compiles, typeof (Test)))
    {
        static if (!__traits (compiles, typeof (Original)))
            enum isSimilarVectors = isSimilarVectorsImpl!(Test, Original);
        else
            enum isSimilarVectors = isSimilarVectorsImpl!(Test, typeof (Original));
    }
    else
    {
        static if (!__traits (compiles, typeof (Original)))
            enum isSimilarVectors = isSimilarVectorsImpl!(typeof (Test), Original);
        else
            enum isSimilarVectors = isSimilarVectorsImpl!(typeof (Test), typeof (Original));
    }
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
    enum isConvertibleVectors = isConvertibleVectorsImpl!(From, To);
}

/// ditto
template isConvertibleVectors (alias From, alias To)
    if (isVector!From && isVector!To)
{
    static if (!__traits (compiles, typeof (From)))
    {
        static if (!__traits (compiles, typeof (To)))
            enum isConvertibleVectors = isConvertibleVectorsImpl!(From, To);
        else
            enum isConvertibleVectors = isConvertibleVectorsImpl!(From, typeof (To));
    }
    else
    {
        static if (!__traits (compiles, typeof (To)))
            enum isConvertibleVectors = isConvertibleVectorsImpl!(typeof (From), To);
        else
            enum isConvertibleVectors = isConvertibleVectorsImpl!(typeof (From), typeof (To));
    }
}

unittest
{
    assert (isConvertibleVectors!(Vector3i, Vector3f));
    assert (isConvertibleVectors!(Vector3f, Vector3i));
}


private:

template isMatrixImpl (Test)
{
    import mathed.types.matrix : Matrix;

    enum isMatrixImpl = is (typeof (Impl!(Test.lines, Test.cols, Test.type)(Test.init)));
    
    private void Impl (size_t Lines, size_t Cols, Type)
                      (Matrix!(Lines, Cols, Type)){}
}

template isSimilarMatricesImpl (Test, Original)
{
    enum isSimilarMatricesImpl = is (Test.type : Original.type)
        && Test.lines == Original.lines && Test.cols == Original.cols;
}

template isConvertibleMatricesImpl (From, To)
{
    enum isConvertibleMatricesImpl = From.lines == To.lines && From.cols == To.cols
        && (is(From.type : To.type) || is(To.type : From.type));
}

template isVectorImpl (Test)
{
    import mathed.types.vector : Vector; 

    enum isVectorImpl = is (typeof (Impl!(Test.size, Test.type, Test.accessors, Test.orientation)(Test.init)));

    private void Impl (size_t Size, Type, string Accessors, string Orientation)
                              (Vector!(Size, Type, Accessors, Orientation)){}
}

template isSimilarVectorsImpl (Test, Original)
{
    enum isSimilarVectorsImpl = is (Test.type : Original.type)
        && Test.size == Original.size;
}

template isConvertibleVectorsImpl (From, To)
{
    enum isConvertibleVectorsImpl = From.size == To.size
        && (is(From.type : To.type) || is(To.type : From.type));
}