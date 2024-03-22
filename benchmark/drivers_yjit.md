ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     6775.6 i/s
                ruby:     5212.3 i/s - 1.30x  slower

```

### large string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:      306.1 i/s
                ruby:      335.5 i/s - same-ish: difference falls within error

```

### small list x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     3566.7 i/s
                ruby:     1999.6 i/s - 1.78x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     6563.1 i/s
                ruby:     2984.7 i/s - 2.20x  slower

```

### small hash x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     3870.9 i/s
                ruby:     2387.4 i/s - 1.62x  slower

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     2641.9 i/s
                ruby:     2575.8 i/s - same-ish: difference falls within error

```

