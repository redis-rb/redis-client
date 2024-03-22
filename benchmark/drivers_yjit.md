ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     6795.5 i/s
                ruby:     5696.7 i/s - 1.19x  slower

```

### large string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:      291.0 i/s
                ruby:      339.3 i/s - same-ish: difference falls within error

```

### small list x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     3661.1 i/s
                ruby:     2351.8 i/s - 1.56x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     6839.3 i/s
                ruby:     5330.8 i/s - 1.28x  slower

```

### small hash x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     3966.9 i/s
                ruby:     3243.4 i/s - 1.22x  slower

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin23]
             hiredis:     4609.7 i/s
                ruby:     4612.8 i/s - same-ish: difference falls within error

```

