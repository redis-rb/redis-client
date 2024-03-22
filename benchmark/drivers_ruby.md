ruby: `ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]`

redis-server: `Redis server v=7.0.12 sha=00000000:0 malloc=libc bits=64 build=a11d0151eabf466c`


### small string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     5369.2 i/s
                ruby:     3095.8 i/s - 1.73x  slower

```

### large string x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:      303.9 i/s
                ruby:      217.9 i/s - 1.39x  slower

```

### small list x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     2706.0 i/s
                ruby:     1325.4 i/s - 2.04x  slower

```

### large list

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     6827.5 i/s
                ruby:     1755.0 i/s - 3.89x  slower

```

### small hash x 100

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     3453.2 i/s
                ruby:     1359.5 i/s - 2.54x  slower

```

### large hash

```
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23]
             hiredis:     1655.5 i/s
                ruby:     1666.5 i/s - same-ish: difference falls within error

```

