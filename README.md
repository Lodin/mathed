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
  1. added: `m + m`.
  2. subtracted: `m - m`.
  3. multiplied by number: `m * 2`.
  4. divided by number: `m / 2`.
  5. multiplied by another matrix: `m * m`.
  6. transposed: `m.t`.
  7. iterated by element number:
  8. iterated by line and column numbers:
  9. set in one action:
3. If you need to check type of some variable to be a matrix, use `isMatrix`
  ```d
    // Creating matrix
    auto m = Matrix!(int, 3, 3)
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
    bool check = isMatrix!(typeof (m));
  ```
### Vector usage
1. Vector can have accessor - a named property method returning one of vector 
element. Accessor can be two types:
  1. One-letter accessor:
  2. Multiletter accessor. Accessor delimiter in the accessors string should 
  be `|` or `,`.
2. Vector has the same actions as matrix, with some differences:
  1. Vector could not be iterated by line and column numbers (`#8`).
  2. Vector can be converted to matrix. Matrix type (one-lined or one-columned)
  depends on VectorType (`horizontal` and `vertical`). By default all vectors 
  are `horizontal`.
3. If you need to check type of some variable to be a vector, use `isVector`.
  ```d
    // Creating simple vector
    auto vec = Vector!(int, 2)(10, 20);
    assert (vec[0] == 10);
  
    // Vector accessor (one-letter)
    auto vec = Vector!(int, 2, "xy")(10, 20);
    assert (vec.x == 10); 
    
    // Vector accessor (multiletter)
    auto vec = Vector!(int, 2, "col|row")(10, 20);
    assert (vec.col == 10);
    
    // Convertion vector to matrix
    auto vec = Vector!(int, 2, "col|row")(10, 20);
    vec.toMatrix ();
    assert (isMatrix!(typeof (vec)));
  ```

### Current version
**alpha**: by now it provides only matrix and vector implementation.
