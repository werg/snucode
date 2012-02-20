# snucode

snucode is a basic realtime-collaborative text editor with syntax highlighting. Check out the live demo at [snucode.com](http://snucode.com)

Contact me: [@werg](http://twitter.com/werg) 

## Dependencies

snucode uses the Node.js websockets framework [SocketStream](https://github.com/socketstream/socketstream) (v 0.2 for now), and the syntax-highlighted editor [CodeMirror](http://codemirror.net/) as well as a bit of [Backbone.js](http://documentcloud.github.com/backbone/) for MVC structure on the client side.

## Features

* Arbitrarily many authors can **edit** the same file **simultaneously**.
* All  **syntax-highlighting** modes [CodeMirror](http://codemirror.net/) provides are supported,
* as well as most of the **visual themes**. 
* **Author attribution** is done by decorating text with color-coded underlining.
* **Open files** from local file system using the HTML 5 [File API](http://www.html5rocks.com/en/tutorials/file/dndfiles/).
* Tries to **guess filetype** from file extension or MIME type.
* **Line Wrapping** optional.
* **Save files** to disk using Douglas Neiner's [Downloadify](https://github.com/dcneiner/Downloadify) (uses Flash since there's no reliable HTML 5 solution).
* **Documents expire** a set amount of time after last access (default two weeks, using Redis expire).

For bugs or feature requests please either send me a [tweet](http://twitter.com/werg) or raise an issue on [github](https://github.com/werg/snucode/issues).

## Install

To roll your own copy, install Node.js and SocketStream [at version 0.2](https://github.com/socketstream/socketstream/tree/0.2) (which currently still should be default version available on npm).
To test it simply run
    socketstream start

And head to [0.0.0.0:3000](http://0.0.0.0:3000).

## Operational Transformation

I chose a rather simplifying and (to my mind elegant) approach to operational transformation (i.e. making sure that concurrent edits get integrated at the right place in the document). You can read up on it at my [weblog](http://gpickard.wordpress.com/2012/02/17/my-approach-to-operational-transformation/).

## License

Copyright (c) 2012 Gabriel Pickard

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.