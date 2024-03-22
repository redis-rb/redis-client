ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     5470.4 i/s
                ruby:     3246.7 i/s - 1.68x  slower

```

### large string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:      304.4 i/s
                ruby:      230.2 i/s - 1.32x  slower

```

### small list x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     2643.4 i/s
                ruby:     1312.4 i/s - 2.01x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     6761.3 i/s
                ruby:     1796.0 i/s - 3.76x  slower

```

### small hash x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     3293.2 i/s
                ruby:     1435.0 i/s - 2.29x  slower

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     1765.3 i/s
                ruby:     1782.7 i/s - same-ish: difference falls within error

```

