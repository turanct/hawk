# Haskell Stream Processor

Haskell Stream Processor (**hsp**) is a command line utility to process streams
using [Haskell](http://www.haskell.org) code.

There are many reasons why Haskell is suitable for stream processing from the
command line.  Code written in Haskell is concise thanks to a clean syntax and
the type inference which allows code without type decoration. Also it is very
easy to define one-line transformations by combining functions.

For example:

```
hsp "L.map (L.head . words) . lines"
```

prints the first word of each line of the input stream.

## Installation

From the project directory

```
cabal install
```

This will compile and install the executable ```hsp``` and the library
```HSProcess.Representable```.

## Usage

```hsp``` supports different modes:

### Evaluate an expression

It is possible to use ```hsp``` to evaluate a user expression without
input using the option ```-e```:

```
hsp -e "1"
```

### Work on the stream

The standard mode of ```hsp``` process the whole stream. It accepts a
string representing a transformation from the stream, that has type
```Data.ByteString.Lazy.ByteString```, to some value with type that is an
instance of ```Rows```:

```haskell
ByteString -> Rows a
```

```Rows``` is a special case of ```Show``` for representing data on the
command line . For example, to print on stdout what it gets from stdin:

```
hsp "id"
```

### Split stream in chunks and process them

Many times, stream processing is about splitting the stream on some delimiter,
like ```'\n'```, and process each chunk of data. With the standard mode of
```hsp``` this can be achieved using the ```split``` function of ```ByteString```:

```
hsp "L.filter (not . null) . split '\n'"
```

This happens so often that ```hsp``` has a mode to split automatically the
stream on a delimiter using ```-d p<delimiter>[```.  If
```<delimiter>``` is omitted, then it is set to ```\n```. With ```-d```, the
function provided must have type:

```haskell
[ByteString] -> Rows a
```
The command before can be rewritten as:

```
hsp -d "L.filter (not . null)"
```

### Map a function on each chunk of data

A specific case of ```hsp -d <delimiter>``` is ```hsp -d <delimiter> -m``` that
is equivalent of mapping the supplied function to the input list. In this case
the function must have type:

```haskell
ByteString -> Row a
```

For example, to take the first word of each line:

```
hsp -m "L.head . words"
```

When ```-m``` is specified, ```-d``` can be omitted and the delimiter is
automatically set to ```\n```.

## Configuration

Haskell Stream Processor is a command line utility and for this reason it needs
informations, like which modules should be loaded, that cannot be easily passed
as arguments. There are two configuration files located under
```$HOME/.hsp```,  one to import modules and one to import user defined
functions.

### Modules

Haskell Stream Processor reads a list of modules to load from the file
```$HOME/.hsp/modules```. Each line of this file is composed by the name of a
module eventually followed by a space and it's qualified name. An example could
be:

```
Control.Monad
Data.List L
```

which means that all the functions from ```Control.Monad``` and ```Data.List```
will be available to the user, but for ```Data.List``` functions you must
qualify them with ```L.```.

Note that ```Prelude``` is loaded with the qualified name ```P```, so standard
functions are not directly visible.

### User defined functions

It is possible to define new function to be used in Haskell Stream Processor
inside the file ```$HOME/.hsp/toolkit.hs```.

## Differences with the Glasgow Haskell Compiler

It is already possible to evaluate an function using the
[Glasgow Haskell Compiler](http://www.haskell.org/ghc/) using the option
```-e``` and by passing the custom function to ```interact```:

```
ghc -e "interact id"
```

The main differences are that Haskell Stream Processor works on (lazy)
```ByteString``` instead of the slower ```String```, it can load modules
automatically from the ```module``` file and can load user defined functions
from the ```toolkit.hs``` file. Also, Haskell Stream Processor supports
different modes from working on the entire stream, like working on each line.

## Examples

In all the examples, ```Data.ByteString``` is loaded without qualification
whereas ```Data.List``` is qualified as ```L```. The function ```match``` is an
alias for ```Text.Regex.Posix.=~```.

Evaluate ```2^100```:

```
hsp -e "2^100"
```

Print numbers from 1 to 100:

```
hsp -e "[1 .. 100]"
```

Take the first line of a stream:

```
... | hsp -d "L.take 1"
```

Take the last two lines of a stream:

```
... | hsp -d "L.reverse . L.take 2 . L.reverse"
```

Print the 10th element of each line:

```
... | hsp -m "(L.!! 10) . words"
```

Print the elements from the 2nd to the 20th of each line:

```
... | hsp -m "L.take 20 . L.drop 1 . words"
```

Get the number of words:

```
... | hsp -d "L.length . L.concatMap words"
```

Get the number of lines:

```
... | hsp -d "L.length"
```

Sort integers and remove duplicates:

```
... | hsp -d "L.nub . L.sort . L.map asInt"
```

Sum the 2nd elements of every line:

```
... | hsp -d "P.sum . L.map (asFloat . (L.!! 1) . words)"
```

Split each line on a delimiter ':' and print the second element:

```
... | hsp -m "(L.!! 1) . split ':'"
```

Remove empty lines:

```
... | hsp -d "L.filter (not . null)"
```

Filter lines that match a pattern:

```
... | hsp -d "L.filter (`match` "t\\w\\wt")"
```