ruby: ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [x86_64-darwin20]
redis-server: Redis server v=6.2.6 sha=00000000:0 malloc=libc bits=64 build=c6f3693d1aced7d9

### small string

```
Warming up --------------------------------------
            redis-rb     2.240k i/100ms
          hiredis-rb     3.475k i/100ms
        redis-client     2.484k i/100ms
Calculating -------------------------------------
            redis-rb     21.537k (± 7.5%) i/s -    107.520k in   5.029717s
          hiredis-rb     34.098k (± 6.6%) i/s -    170.275k in   5.022052s
        redis-client     24.725k (± 2.1%) i/s -    124.200k in   5.025403s

Comparison:
            redis-rb:    21536.7 i/s
          hiredis-rb:    34097.7 i/s - 1.58x  (± 0.00) faster
        redis-client:    24725.4 i/s - 1.15x  (± 0.00) faster

```

### large string

```
Warming up --------------------------------------
            redis-rb   737.000  i/100ms
          hiredis-rb     1.148k i/100ms
        redis-client     1.119k i/100ms
Calculating -------------------------------------
            redis-rb      7.745k (± 8.0%) i/s -     39.061k in   5.081076s
          hiredis-rb     11.305k (± 7.7%) i/s -     56.252k in   5.012673s
        redis-client     10.598k (± 5.1%) i/s -     53.712k in   5.083341s

Comparison:
            redis-rb:     7745.5 i/s
          hiredis-rb:    11304.6 i/s - 1.46x  (± 0.00) faster
        redis-client:    10598.5 i/s - 1.37x  (± 0.00) faster

```

### small list

```
Warming up --------------------------------------
            redis-rb     1.655k i/100ms
          hiredis-rb     3.171k i/100ms
        redis-client     2.096k i/100ms
Calculating -------------------------------------
            redis-rb     17.098k (± 1.8%) i/s -     86.060k in   5.035054s
          hiredis-rb     31.118k (± 3.6%) i/s -    158.550k in   5.102171s
        redis-client     20.883k (± 2.3%) i/s -    104.800k in   5.021049s

Comparison:
            redis-rb:    17098.2 i/s
          hiredis-rb:    31117.5 i/s - 1.82x  (± 0.00) faster
        redis-client:    20883.0 i/s - 1.22x  (± 0.00) faster

```

### large list

```
Warming up --------------------------------------
            redis-rb    19.000  i/100ms
          hiredis-rb   472.000  i/100ms
        redis-client   109.000  i/100ms
Calculating -------------------------------------
            redis-rb    205.221  (± 5.8%) i/s -      1.026k in   5.016504s
          hiredis-rb      4.719k (± 2.9%) i/s -     23.600k in   5.005678s
        redis-client      1.095k (± 1.6%) i/s -      5.559k in   5.078594s

Comparison:
            redis-rb:      205.2 i/s
          hiredis-rb:     4718.9 i/s - 22.99x  (± 0.00) faster
        redis-client:     1094.9 i/s - 5.34x  (± 0.00) faster

```

### small hash

```
Warming up --------------------------------------
            redis-rb     1.343k i/100ms
          hiredis-rb     2.894k i/100ms
        redis-client     2.022k i/100ms
Calculating -------------------------------------
            redis-rb     14.064k (± 4.5%) i/s -     71.179k in   5.075051s
          hiredis-rb     28.230k (± 3.8%) i/s -    141.806k in   5.030964s
        redis-client     19.792k (± 6.5%) i/s -     99.078k in   5.033603s

Comparison:
            redis-rb:    14063.9 i/s
          hiredis-rb:    28229.9 i/s - 2.01x  (± 0.00) faster
        redis-client:    19792.4 i/s - 1.41x  (± 0.00) faster

```

### large hash

```
Warming up --------------------------------------
            redis-rb    21.000  i/100ms
          hiredis-rb   296.000  i/100ms
        redis-client    92.000  i/100ms
Calculating -------------------------------------
            redis-rb    185.011  (± 7.0%) i/s -    924.000  in   5.018292s
          hiredis-rb      2.909k (± 3.1%) i/s -     14.800k in   5.092775s
        redis-client      1.005k (± 4.0%) i/s -      5.060k in   5.044686s

Comparison:
            redis-rb:      185.0 i/s
          hiredis-rb:     2909.0 i/s - 15.72x  (± 0.00) faster
        redis-client:     1004.9 i/s - 5.43x  (± 0.00) faster

```

