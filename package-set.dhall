-- https://forum.dfinity.org/t/do-people-actually-use-vessel/9849/8?u=cryptoschindler
-- ^ how to create the hash
let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.13.6-20250121/package-set.dhall sha256:343764618772fc4674059493b3ee0d7d05065383bcc314a4a961e897f8553b6c
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  additions = [
    { name = "base"
    , repo = "https://github.com/dfinity/motoko-base"
    , version = "master"
    , dependencies = [] : List Text
    },
    { name = "matchers"
    , repo = "https://github.com/kritzcreek/motoko-matchers"
    , version = "v1.2.0"
    , dependencies = [] : List Text
    },
    { name = "hex"
    , repo = "https://github.com/letmejustputthishere/motoko-hex"
    , version = "master"
    , dependencies = [ "base" ]
    },
    { name = "canistergeek"
    , repo = "https://github.com/usergeek/canistergeek-ic-motoko"
    , version = "v0.0.3"
    , dependencies = [ "base" ]
    },
    { name = "uuid"
    , version = "v0.2.0"
    , repo = "https://github.com/aviate-labs/uuid.mo"
    , dependencies = [ "base", "io", "encoding" ]
    },
    { name = "array"
    , repo = "https://github.com/aviate-labs/array.mo"
    , version = "v0.2.0"
    , dependencies = [ "base" ]
    },
    { name = "encoding"
    , repo = "https://github.com/aviate-labs/encoding.mo"
    , version = "v0.3.2"
    , dependencies = [ "array", "base" ]
    },
    { name = "hash"
    , repo = "https://github.com/aviate-labs/hash.mo"
    , version = "v0.1.0"
    , dependencies = [ "array", "base" ]
    },
    { name = "accountid"
    , repo = "https://github.com/aviate-labs/principal.mo"
    , version = "main"
    , dependencies = [ "array", "crypto", "base", "encoding", "hash" ]
    },
    { name = "crypto"
    , repo = "https://github.com/aviate-labs/crypto.mo"
    , version = "v0.1.1"
    , dependencies = [ "base", "encoding" ]
    },
    { name = "hex"
    , repo = "https://github.com/letmejustputthishere/motoko-hex"
    , version = "master"
    , dependencies = ["base"] : List Text
    },
    { name = "canistergeek"
    , repo = "https://github.com/usergeek/canistergeek-ic-motoko"
    , version = "v0.0.3"
    , dependencies = ["base"] : List Text
    },
    { name = "uuid"
    , version = "v0.2.0"
    , repo = "https://github.com/aviate-labs/uuid.mo"
    , dependencies = [ "base", "io", "encoding" ]
    },
    { name = "io"
    , version = "v0.3.1"
    , repo = "https://github.com/aviate-labs/io.mo"
    , dependencies = [ "base" ]
    }
  ] : List Package

let overrides = [] : List Package

in  upstream # additions # overrides
