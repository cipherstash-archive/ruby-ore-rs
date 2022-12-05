#[macro_use]
extern crate rutie;

#[macro_use]
extern crate lazy_static;

use ore_encoding_rs::OrePlaintext;
use ore_rs::{CipherText, ORECipher, OREEncrypt};
use ore_rs::scheme::bit2::OREAES128;
use rutie::{Boolean, Class, Encoding, Float, Integer, Module, Object, RString, VerifiedObject, VM};
use std::cmp::Ordering;

module!(RbORE);
class!(RbOREAES128);
class!(RbOREAES128Ciphertext);

impl VerifiedObject for RbOREAES128Ciphertext {
    fn is_correct_type<T: Object>(object: &T) -> bool {
        let klass = Module::from_existing("ORE").get_nested_class("AES128").get_nested_class("Ciphertext");
        klass.case_equals(object)
    }

    fn error_message() -> &'static str {
        "Error converting to ORE::AES128::Ciphertext"
    }
}

impl From<CipherText<OREAES128, 8>> for RbOREAES128Ciphertext {
    fn from(ct: CipherText<OREAES128, 8>) -> Self {
        let klass = Module::from_existing("ORE").get_nested_class("AES128").get_nested_class("Ciphertext");
        klass.wrap_data(OreAes128Ciphertext { ct: ct.to_bytes(), n: 8 }, &*OREAES128_CIPHERTEXT_WRAPPER)
    }
}

pub struct OreAes128 {
    cipher: OREAES128
}

wrappable_struct!(OreAes128, OreAes128Wrapper, OREAES128_WRAPPER);

pub struct OreAes128Ciphertext {
    #[allow(dead_code)]
    n: u32,
    ct: Vec<u8>
}

wrappable_struct!(OreAes128Ciphertext, OreAes128CiphertextWrapper, OREAES128_CIPHERTEXT_WRAPPER);

methods!(
    RbOREAES128,
    rbself,

    fn ore_aes128_new(k1string: RString, k2string: RString) -> RbOREAES128 {
        let mut k1: [u8; 16] = Default::default();
        let mut k2: [u8; 16] = Default::default();

        k1.clone_from_slice(k1string.unwrap().to_bytes_unchecked());
        k2.clone_from_slice(k2string.unwrap().to_bytes_unchecked());

        let cipher: OREAES128 = ORECipher::init(&k1, &k2).unwrap();

        let klass = Module::from_existing("ORE").get_nested_class("AES128");
        return klass.wrap_data(OreAes128 { cipher: cipher }, &*OREAES128_WRAPPER);
    }

    fn ore_aes128_encrypt_u64(plaintext: Integer) -> RbOREAES128Ciphertext {
        let ore = rbself.get_data_mut(&*OREAES128_WRAPPER);
        plaintext.unwrap().to_u64().encrypt(&mut ore.cipher).map_err(|e| VM::raise(Class::from_existing("RuntimeError"), &format!("Failed to encrypt ORE plaintext: {:?}", e))).unwrap().into()
    }

    fn ore_aes128_encrypt_f64(plaintext: Float) -> RbOREAES128Ciphertext {
        let ore = rbself.get_data_mut(&*OREAES128_WRAPPER);
        OrePlaintext::<u64>::from(plaintext.unwrap().to_f64()).0.encrypt(&mut ore.cipher).map_err(|e| VM::raise(Class::from_existing("RuntimeError"), &format!("Failed to encrypt ORE plaintext: {:?}", e))).unwrap().into()
    }

    fn ore_aes128_encrypt_string(plaintext: RString) -> RbOREAES128Ciphertext {
        let ore = rbself.get_data_mut(&*OREAES128_WRAPPER);
        OrePlaintext::<u64>::from(plaintext.unwrap().to_string_unchecked()).0.encrypt(&mut ore.cipher).map_err(|e| VM::raise(Class::from_existing("RuntimeError"), &format!("Failed to encrypt ORE plaintext: {:?}", e))).unwrap().into()
    }

    fn ore_aes128_encrypt_bool(plaintext: Boolean) -> RbOREAES128Ciphertext {
        let ore = rbself.get_data_mut(&*OREAES128_WRAPPER);
        OrePlaintext::<u64>::from(plaintext.unwrap().to_bool()).0.encrypt(&mut ore.cipher).map_err(|e| VM::raise(Class::from_existing("RuntimeError"), &format!("Failed to encrypt ORE plaintext: {:?}", e))).unwrap().into()
    }
);

methods!(
    RbOREAES128Ciphertext,
    rbself,

    fn ore_aes128_ciphertext_new(serialized_ciphertext: RString, n: Integer) -> RbOREAES128Ciphertext {
        let ct = CipherText::<OREAES128, 8>::from_bytes(&serialized_ciphertext.unwrap().to_vec_u8_unchecked()).map_err(|e| VM::raise(Class::from_existing("ArgumentError"), &format!("Failed to deserialize ORE ciphertext: {:?}", e))).unwrap();

        let klass = Module::from_existing("ORE").get_nested_class("AES128").get_nested_class("Ciphertext");
        return klass.wrap_data(OreAes128Ciphertext { ct: ct.to_bytes(), n: n.unwrap().to_u32() }, &*OREAES128_CIPHERTEXT_WRAPPER);
    }

    fn ore_aes128_ciphertext_serialize() -> RString {
        let obj = rbself.get_data(&*OREAES128_CIPHERTEXT_WRAPPER);

        return RString::from_bytes(&obj.ct, &Encoding::find("BINARY").unwrap());
    }

    fn ore_aes128_ciphertext_cmp(other: RbOREAES128Ciphertext) -> Integer {
        let obj = rbself.get_data(&*OREAES128_CIPHERTEXT_WRAPPER);
        let real_other = other.unwrap();
        let oth = real_other.get_data(&*OREAES128_CIPHERTEXT_WRAPPER);

        match OREAES128::compare_raw_slices(&obj.ct, &oth.ct) {
            Some(Ordering::Equal) => Integer::from(0),
            Some(Ordering::Less) => Integer::from(-1),
            Some(Ordering::Greater) => Integer::from(1),
            None => {
                VM::raise(Class::from_existing("RuntimeError"), "Comparison failed");
                Integer::from(0)
            }
        }
    }
);




#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn Init_ore_rs() {
    Module::from_existing("ORE").define(|oremod| {
        oremod.define_nested_class("AES128", None).define(|cipher_class| {
            cipher_class.singleton_class().def_private("_new", ore_aes128_new);
            cipher_class.def_private("_encrypt_u64", ore_aes128_encrypt_u64);
            cipher_class.def_private("_encrypt_f64", ore_aes128_encrypt_f64);
            cipher_class.def_private("_encrypt_string", ore_aes128_encrypt_string);
            cipher_class.def_private("_encrypt_bool", ore_aes128_encrypt_bool);

            cipher_class.define_nested_class("Ciphertext", None).define(|ciphertext_class| {
                ciphertext_class.singleton_class().def_private("_new", ore_aes128_ciphertext_new);
                ciphertext_class.def_private("_serialize", ore_aes128_ciphertext_serialize);
                ciphertext_class.def_private("_cmp", ore_aes128_ciphertext_cmp);
            });
        });
    });
}
