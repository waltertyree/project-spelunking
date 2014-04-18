{
if ($1 ~ /Author:/) {a = $2 " " $3};
if ($1 ~ /Date:/) {b = $2 " " $3 " " $4 " " $5 " " $6};
if (a != "" && b !="") {
if (a in authors) 
{  c = authors[a];
  c++;
  authors[a] = c;
}
else 
{
    authors[a] = 1;
    dates[a] = b;
}
a = "";
b = "";
}
}
END {
  for (a in authors) 
    print (a "\t" authors[a] "\t" dates[a]);
    }
