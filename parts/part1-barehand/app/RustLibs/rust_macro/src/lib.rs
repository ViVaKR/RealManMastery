use proc_macro::TokenStream;
use quote::quote;
use syn::{ItemFn, parse_macro_input};

#[proc_macro_attribute]
pub fn rust_export(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let mut input_fn = parse_macro_input!(item as ItemFn);

    // C-ABI 규격 (extern "C") 강제 적용
    input_fn.sig.abi = Some(syn::parse_quote!(extern "C"));

    let fn_vis = &input_fn.vis;
    let fn_sig = &input_fn.sig;
    let fn_block = &input_fn.block;

    // #[unsafe(no_mangle)] 자동 주입
    let expanded = quote! {
        #[unsafe(no_mangle)]
        #fn_vis #fn_sig {
            #fn_block
        }
    };
    TokenStream::from(expanded)
}
