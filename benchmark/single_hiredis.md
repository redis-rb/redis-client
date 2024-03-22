ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:    47841.9 i/s
        redis-client:    25336.0 i/s - 1.89x  slower

```

### large string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:    21223.9 i/s
        redis-client:    12986.1 i/s - 1.63x  slower

```

### small list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:    43794.1 i/s
        redis-client:    24659.6 i/s - 1.78x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:     7014.5 i/s
        redis-client:     6820.4 i/s - same-ish: difference falls within error

```

### small hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:    41932.1 i/s
        redis-client:    23808.4 i/s - 1.76x  slower

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:     4544.7 i/s
        redis-client:     5388.2 i/s - 1.19x  faster

```

