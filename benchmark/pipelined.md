ruby: ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [x86_64-darwin20]
redis-server: Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9

### small string

```
Warming up --------------------------------------
            redis-rb    83.000  i/100ms
          hiredis-rb   322.000  i/100ms
        redis-client   228.000  i/100ms
Calculating -------------------------------------
            redis-rb    844.467  (± 3.2%) i/s -      4.233k in   5.018020s
          hiredis-rb      3.231k (± 4.5%) i/s -     16.422k in   5.094854s
        redis-client      2.286k (± 2.3%) i/s -     11.628k in   5.090197s

Comparison:
            redis-rb:      844.5 i/s
          hiredis-rb:     3230.8 i/s - 3.83x  (± 0.00) faster
        redis-client:     2285.6 i/s - 2.71x  (± 0.00) faster

```

### large string

```
Warming up --------------------------------------
            redis-rb    10.000  i/100ms
          hiredis-rb    15.000  i/100ms
        redis-client    11.000  i/100ms
Calculating -------------------------------------
            redis-rb    105.881  (±10.4%) i/s -    530.000  in   5.066927s
          hiredis-rb    160.796  (± 6.2%) i/s -    810.000  in   5.060606s
        redis-client    107.741  (± 6.5%) i/s -    539.000  in   5.023661s

Comparison:
            redis-rb:      105.9 i/s
          hiredis-rb:      160.8 i/s - 1.52x  (± 0.00) faster
        redis-client:      107.7 i/s - same-ish: difference falls within error

```

### small list

```
Warming up --------------------------------------
            redis-rb    30.000  i/100ms
          hiredis-rb   180.000  i/100ms
        redis-client    89.000  i/100ms
Calculating -------------------------------------
            redis-rb    307.341  (± 3.6%) i/s -      1.560k in   5.082035s
          hiredis-rb      1.820k (± 4.9%) i/s -      9.180k in   5.057512s
        redis-client    909.114  (± 1.3%) i/s -      4.628k in   5.091638s

Comparison:
            redis-rb:      307.3 i/s
          hiredis-rb:     1819.8 i/s - 5.92x  (± 0.00) faster
        redis-client:      909.1 i/s - 2.96x  (± 0.00) faster

```

### large list

```
Warming up --------------------------------------
            redis-rb     1.000  i/100ms
          hiredis-rb     4.000  i/100ms
        redis-client     1.000  i/100ms
Calculating -------------------------------------
            redis-rb      1.478  (± 0.0%) i/s -      8.000  in   5.420321s
          hiredis-rb     47.890  (± 4.2%) i/s -    240.000  in   5.024349s
        redis-client     11.529  (± 0.0%) i/s -     58.000  in   5.032495s

Comparison:
            redis-rb:        1.5 i/s
          hiredis-rb:       47.9 i/s - 32.39x  (± 0.00) faster
        redis-client:       11.5 i/s - 7.80x  (± 0.00) faster

```

### small hash

```
Warming up --------------------------------------
            redis-rb    21.000  i/100ms
          hiredis-rb   158.000  i/100ms
        redis-client    85.000  i/100ms
Calculating -------------------------------------
            redis-rb    211.807  (± 5.2%) i/s -      1.071k in   5.068451s
          hiredis-rb      1.557k (± 3.5%) i/s -      7.900k in   5.080080s
        redis-client    863.107  (± 1.7%) i/s -      4.335k in   5.024063s

Comparison:
            redis-rb:      211.8 i/s
          hiredis-rb:     1557.3 i/s - 7.35x  (± 0.00) faster
        redis-client:      863.1 i/s - 4.07x  (± 0.00) faster

```

### large hash

```
Warming up --------------------------------------
            redis-rb     1.000  i/100ms
          hiredis-rb     2.000  i/100ms
        redis-client     1.000  i/100ms
Calculating -------------------------------------
            redis-rb      1.373  (± 0.0%) i/s -      7.000  in   5.100355s
          hiredis-rb     27.377  (±11.0%) i/s -    136.000  in   5.031463s
        redis-client     11.182  (± 0.0%) i/s -     56.000  in   5.009408s

Comparison:
            redis-rb:        1.4 i/s
          hiredis-rb:       27.4 i/s - 19.93x  (± 0.00) faster
        redis-client:       11.2 i/s - 8.14x  (± 0.00) faster

```

