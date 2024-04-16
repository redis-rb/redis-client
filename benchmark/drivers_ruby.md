ruby: `ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) [arm64-darwin23]
             hiredis:     5085.0 i/s
                ruby:     2922.4 i/s - 1.74x  slower

```

### large string

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) [arm64-darwin23]
             hiredis:    10287.9 i/s
                ruby:    12928.2 i/s - 1.26x  faster

```

### small list x 100

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) [arm64-darwin23]
             hiredis:     2534.8 i/s
                ruby:     1145.9 i/s - 2.21x  slower

```

### large list

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) [arm64-darwin23]
             hiredis:     5904.5 i/s
                ruby:     1508.8 i/s - 3.91x  slower

```

### small hash x 100

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) [arm64-darwin23]
             hiredis:     2993.3 i/s
                ruby:     1179.7 i/s - 2.54x  slower

```

### large hash

```
ruby 3.4.0dev (2024-03-26T11:54:54Z master 2b08406cd0) [arm64-darwin23]
             hiredis:     1473.2 i/s
                ruby:     1460.3 i/s - same-ish: difference falls within error

```

