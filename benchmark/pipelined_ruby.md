ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:     1212.6 i/s
        redis-client:     3007.1 i/s - 2.48x  faster

```

### large string

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:      238.9 i/s
        redis-client:      306.1 i/s - 1.28x  faster

```

### small list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:      604.3 i/s
        redis-client:     1190.9 i/s - 1.97x  faster

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:        2.3 i/s
        redis-client:       14.2 i/s - 6.16x  faster

```

### small hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:      401.8 i/s
        redis-client:     1123.9 i/s - 2.80x  faster

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
            redis-rb:        2.3 i/s
        redis-client:       14.5 i/s - 6.41x  faster

```

