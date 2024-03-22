ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:     1460.6 i/s
        redis-client:     5345.6 i/s - 3.66x  faster

```

### large string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:      272.9 i/s
        redis-client:      338.7 i/s - 1.24x  faster

```

### small list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:      732.6 i/s
        redis-client:     1985.5 i/s - 2.71x  faster

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:        2.6 i/s
        redis-client:       31.7 i/s - 12.33x  faster

```

### small hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:      471.1 i/s
        redis-client:     2190.7 i/s - 4.65x  faster

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:        2.5 i/s
        redis-client:       30.9 i/s - 12.19x  faster

```

