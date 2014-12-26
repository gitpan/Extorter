use Test::More;

use Extorter qw(
    Encode^encode_utf8
    Encode^decode_utf8
);

use Extorter qw(
    Scalar::Util::blessed
    Scalar::Util::refaddr
    Scalar::Util::reftype
    Scalar::Util::weaken
);

can_ok main => qw(
    encode_utf8
    decode_utf8
);

can_ok main => qw(
    blessed
    refaddr
    reftype
    weaken
);

done_testing;
