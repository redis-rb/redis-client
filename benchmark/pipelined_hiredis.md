ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:     5438.6 i/s
        redis-client:     5552.9 i/s - same-ish: difference falls within error

```

### large string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:      354.4 i/s
        redis-client:      310.9 i/s - 1.14x  slower

```

### small list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:     3081.4 i/s
        redis-client:     2733.0 i/s - 1.13x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:       82.3 i/s
        redis-client:       65.0 i/s - 1.26x  slower

```

### small hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:     2249.0 i/s
        redis-client:     3117.0 i/s - 1.39x  faster

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:       46.9 i/s
        redis-client:       67.5 i/s - 1.44x  faster

```

