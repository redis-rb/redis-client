ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     5402.4 i/s
                ruby:     2877.9 i/s - 1.88x  slower

```

### large string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:      297.2 i/s
                ruby:      291.2 i/s - same-ish: difference falls within error

```

### small list x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     2632.0 i/s
                ruby:     1136.1 i/s - 2.32x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     6640.8 i/s
                ruby:     1293.1 i/s - 5.14x  slower

```

### small hash x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     3419.6 i/s
                ruby:     1129.0 i/s - 3.03x  slower

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     1299.3 i/s
                ruby:     1275.3 i/s - same-ish: difference falls within error

```

