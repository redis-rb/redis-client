ruby: `ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:     5239.0 i/s
                ruby:     2957.4 i/s - 1.77x  slower

```

### large string

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:    12784.9 i/s
                ruby:    14948.2 i/s - same-ish: difference falls within error

```

### small list x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:     2599.3 i/s
                ruby:     1300.0 i/s - 2.00x  slower

```

### large list

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:     6836.0 i/s
                ruby:     1867.6 i/s - 3.66x  slower

```

### small hash x 100

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:     3392.5 i/s
                ruby:     1408.9 i/s - 2.41x  slower

```

### large hash

```
ruby 3.4.0dev (2024-03-19T14:18:56Z master 5c2937733c) [arm64-darwin23]
             hiredis:     1786.2 i/s
                ruby:     1811.9 i/s - same-ish: difference falls within error

```

