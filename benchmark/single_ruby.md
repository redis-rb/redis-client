ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:    33612.8 i/s
        redis-client:    34726.1 i/s - same-ish: difference falls within error

```

### large string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:    16680.5 i/s
        redis-client:    18644.2 i/s - same-ish: difference falls within error

```

### small list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:    25772.9 i/s
        redis-client:    29299.7 i/s - 1.14x  faster

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:      356.9 i/s
        redis-client:     1342.9 i/s - 3.76x  faster

```

### small hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:    22903.5 i/s
        redis-client:    29003.8 i/s - 1.27x  faster

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:      343.3 i/s
        redis-client:     1284.8 i/s - 3.74x  faster

```

