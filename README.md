# mathed
======
This is a small math library written in D Programming Language.

## Features:
### Matrix and vector
1. All actions is checked at compile time. There are no exceptions.
2. Matrix and vector structure contains only it's data, and nothing additional.
3. Almost all actions is `pure` and `nothrow`.

### Matirx usage
1. Creating matrix
2. Matrix can be:
  - added: `m + m`.
  - subtracted: `m - m`.
  - multiplied by number: `m * 2`.
  - divided by number: `m / 2`.
  - multiplied by another matrix: `m * m`.
  - transposed: `m.t`.
  - iterated by element number:
  - iterated by line and column numbers:
  - set in one action:
3. If you need to check type of some variable to be a matrix, use `isMatrix`
  ```d
    // Creating matrix
    auto m = Matrix!(3, 3, int)
    (
       3, -1, 6,
       2,  1, 5,
      -3,  1, 0
    );
    assert (m[0][2] == 6);
  
    // Iteration by element number
    foreach (i, ref col; m)
    {
      writefln ("The %s-th element of matrix is %s", i, col);
    }
    
    // iteration by line and column numbers:
    foreach (i, j, ref col; m)
    {
      writefln ("The element of %s-th line, %s-th column of matrix is %s", i, j, col);
    }
    
    // Setting all matrix values in one action
    m.set
    (
       3, -1, 6,
       2,  1, 5,
      -3,  1, 0
    );
    
    // Type checking
    assert (isMatrix!m);
  ```
  
### Vector usage
1. Vector can have accessor - a named property method returning one of vector 
element. Accessor can be two types:
  - One-letter accessor:
  - Multiletter accessor. Accessor delimiter in the accessors string should 
  be `,`.
2. Vector has the same actions as matrix, with some differences:
  - Vector could not be iterated by line and column numbers.
  - Vector can be converted to matrix. Matrix type (one-lined or one-columned)
  depends on VectorType (`horizontal` and `vertical`). By default all vectors 
  are `horizontal`.
3. If you need to check type or variable to be a vector, use `isVector`.
  ```d
    // Creating simple vector
    auto v = Vector!(2, int)(10, 20);
    assert (v[0] == 10);
  
    // Vector accessor (one-letter)
    auto v = Vector!(2, int, "xy")(10, 20);
    assert (v.x == 10); 
    
    // Vector accessor (multiletter)
    auto v = Vector!(2, int, "col,row")(10, 20);
    assert (v.col == 10);
    
    // Conversion vector to matrix
    auto v = Vector!(2, int, "col,row")(10, 20);
    auto m = v.toMatrix ();
    assert (isMatrix!m);
  ```

### Current version
**alpha**: by now it provides only matrix and vector implementation.
