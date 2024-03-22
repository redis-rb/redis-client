ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     5346.6 i/s
                ruby:     2984.3 i/s - 1.79x  slower

```

### large string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:      304.2 i/s
                ruby:      204.1 i/s - 1.49x  slower

```

### small list x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     2612.0 i/s
                ruby:     1240.8 i/s - 2.11x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     6772.7 i/s
                ruby:     1540.7 i/s - 4.40x  slower

```

### small hash x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     3293.2 i/s
                ruby:     1234.0 i/s - 2.67x  slower

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     1421.7 i/s
                ruby:     1481.0 i/s - same-ish: difference falls within error

```

