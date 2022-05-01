Ruby bindings for the [ore.rs](https://github.com/cipherstash/ore.rs) Order-Revealing Encryption Rust library.


# Installation

For the most common platforms, we provide "native" gems (which have the shared
object that provides the cryptographic primitives pre-compiled).  At present,
we provide native gems for:

* Linux `x86_64` and `aarch64`
* macOS `x86_64` and `arm64`

On these platforms, you can just install the `ore-rs` gem via your preferred
method, and it should "just work".  If it doesn't, please [report that as a
bug](https://github.com/cipherstash/ruby-ore-rs/issues).

For other platforms, you will need to install the source gem, which requires
that you have Rust 1.31.0 or later installed.  On ARM-based platforms, you must
use Rust nightly, for SIMD intrinsics support.

## Installing from Git

If you have a burning need to install directly from a checkout of the git
repository, you can do so by running `bundle install && rake install`.  As this
is a source-based installation, you will need to have Rust installed, as
described above.


# Usage

First off, load the library:

```ruby
require "ore-rs"
```

Then create a new encryptor:

```ruby
enc = ORE::AES128.new(key1, key2, 64, 8)
```

Encrypt a couple of ciphertexts:

```ruby
ct1 = enc.encrypt(42)
ct2 = enc.encrypt(420)
```

Finally, compare them:

```ruby
ct1 < ct2   # => true
ct1 > ct2   # => false
```

If you need to store a ciphertext, you can turn it into a binary string:

```ruby
File.write("/tmp/ciphertext", ct1.to_s)
```

To turn a binary string back into a ciphertext, just create a new ciphertext with it:

```ruby
ct3 = ORE::AES128::Ciphertext.new(File.binread("/tmp/ciphertext"), 8)
```


# Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md).


# Licence

Unless otherwise stated, everything in this repo is covered by the following
copyright notice:

    Copyright (C) 2022  CipherStash Inc.

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
