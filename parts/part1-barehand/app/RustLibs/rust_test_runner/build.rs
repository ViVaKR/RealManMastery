use std::env;
use std::fs;
use std::path::PathBuf;

fn find_part1_barehand_dir() -> PathBuf {
    let manifest_dir =
        env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR가 설정되지 않았네 친구!");
    let mut path = PathBuf::from(manifest_dir);
    // Yana 폴더를 찾을 때까지 계속 상위 폴더(pop)로 이동
    while !path.join("part1-barehand").exists() {
        if !path.pop() {
            panic!("[에러] 하늘이 두 쪽 나도 Yana 폴더를 찾을 수 없구만!");
        }
    }

    path.join("part1-barehand")
}

fn main() {
    // 동적으로 Yana/tests 경로 획득! (모냥 빠지는 상대 경로 안녕~)
    let part1_dir = find_part1_barehand_dir();
    let asm_dir = part1_dir.join("tests");

    println!("cargo:rerun-if-changed={}", asm_dir.display());
    let mut build = cc::Build::new();
    if let Ok(entries) = fs::read_dir(&asm_dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if let Some(ext) = path.extension() {
                if ext == "S" || ext == "s" {
                    build.file(&path);
                    println!("cargo:rerun-if-changed={}", path.display());
                }
            }
        }
    }
    build.compile("rust_test_asm");
}
