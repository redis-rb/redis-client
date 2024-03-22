ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     6745.7 i/s
                ruby:     5182.0 i/s - 1.30x  slower

```

### large string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:      303.5 i/s
                ruby:      343.1 i/s - 1.13x  faster

```

### small list x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     3683.6 i/s
                ruby:     1952.3 i/s - 1.89x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     6540.2 i/s
                ruby:     2710.0 i/s - 2.41x  slower

```

### small hash x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     4002.6 i/s
                ruby:     2317.0 i/s - 1.73x  slower

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     2467.1 i/s
                ruby:     2439.0 i/s - same-ish: difference falls within error

```

