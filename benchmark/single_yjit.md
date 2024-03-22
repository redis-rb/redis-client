ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:    36024.0 i/s
        redis-client:    38624.3 i/s - same-ish: difference falls within error

```

### large string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:    18402.4 i/s
        redis-client:    21330.5 i/s - same-ish: difference falls within error

```

### small list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:    28625.5 i/s
        redis-client:    34434.7 i/s - 1.20x  faster

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:      404.9 i/s
        redis-client:     2856.7 i/s - 7.05x  faster

```

### small hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:    25868.4 i/s
        redis-client:    34166.3 i/s - 1.32x  faster

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
            redis-rb:      378.0 i/s
        redis-client:     2432.8 i/s - 6.44x  faster

```

