BEGIN {FS = "|"}

/^r[0-9]*/ { a = $2 
  b = $3
  if (a in authors) 
    { c = authors[a]
      c++
      authors[a] = c
    }
  else 
    {
      authors[a] = 1
      dates[a] = b
    }
}

END {
  for (a in authors) 
    print (a "\t" authors[a] "\t" dates[a])
    }
