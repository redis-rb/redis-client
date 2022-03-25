ruby: `ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [x86_64-darwin20]`

redis-server: `Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9`


### small string

```
            redis-rb:    22371.1 i/s
        redis-client:    24274.9 i/s - 1.09x  (± 0.00) faster

```

### large string

```
            redis-rb:     7863.2 i/s
        redis-client:    10706.0 i/s - 1.36x  (± 0.00) faster

```

### small list

```
            redis-rb:    16749.3 i/s
        redis-client:    20171.1 i/s - 1.20x  (± 0.00) faster

```

### large list

```
            redis-rb:      213.2 i/s
        redis-client:     1107.1 i/s - 5.19x  (± 0.00) faster

```

### small hash

```
            redis-rb:    13968.8 i/s
        redis-client:    20109.7 i/s - 1.44x  (± 0.00) faster

```

### large hash

```
            redis-rb:      202.5 i/s
        redis-client:     1042.0 i/s - 5.15x  (± 0.00) faster

```

