const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const os_tag = target.result.os.tag;
    const dotnet_rid: []const u8 = switch (os_tag) {
        .macos => "osx-arm64",
        .linux => "linux-arm64",
        else => @panic("RealManMastery는 macOS / Linux (AArch64)만 지원한다네"),
    };
    const dylib_ext: []const u8 = if (os_tag == .macos) "dylib" else "so";
    const rpath_token: []const u8 = if (os_tag == .macos) "@executable_path" else "$ORIGIN";
    const config: []const u8 = if (optimize == .Debug) "Debug" else "Release";

    const dotnet_exe = b.findProgram(&.{"dotnet"}, &.{}) catch
        @panic("dotnet 을 PATH 에서 못 찾았네");

    // ==========================================
    // 1. app/DotnetLibs (.NET Native AOT) 스텝
    // ==========================================
    const clean_dotnet = b.addSystemCommand(&.{ "rm", "-rf", "obj", "bin", "out" });
    clean_dotnet.setCwd(b.path("app/DotnetLibs"));

    const restore_dotnet = b.addSystemCommand(&.{ dotnet_exe, "restore" });
    restore_dotnet.step.dependOn(&clean_dotnet.step);
    restore_dotnet.addFileArg(b.path("app/DotnetLibs/DotnetLibs.csproj"));

    restore_dotnet.addArgs(&.{ "-r", dotnet_rid });

    // restore_dotnet 스텝 자체를 없애고, publish에서 --no-restore 제거
    const publish_dotnet = b.addSystemCommand(&.{ dotnet_exe, "publish" });
    publish_dotnet.step.dependOn(&clean_dotnet.step); // restore 대신 clean에 바로 의존
    publish_dotnet.addFileArg(b.path("app/DotnetLibs/DotnetLibs.csproj"));
    publish_dotnet.addArgs(&.{ "-c", config, "-r", dotnet_rid, "-o", "out" }); // --no-restore 삭제
    publish_dotnet.setCwd(b.path("app/DotnetLibs"));

    const dotnet_lib_name = b.fmt("DotnetLibs.{s}", .{dylib_ext});
    const dotnet_lib_path = b.path(b.fmt("app/DotnetLibs/out/{s}", .{dotnet_lib_name}));

    // ==========================================
    // 2. app/RustLibs (Rust rust_core) 스텝
    // ==========================================
    const rust_profile = if (optimize == .Debug) "debug" else "release";

    const cargo_build = b.addSystemCommand(&.{ "cargo", "build", "-p", "rust_core" });
    if (optimize != .Debug) {
        cargo_build.addArg("--release");
    }
    cargo_build.setCwd(b.path("app/RustLibs")); // Cargo.toml 워크스페이스 루트

    const rust_lib_name = b.fmt("librust_core.{s}", .{dylib_ext});
    const rust_lib_path = b.path(b.fmt("app/RustLibs/target/{s}/{s}", .{ rust_profile, rust_lib_name }));

    // ==========================================
    // 3. 실행 파일 (RealManApp) 설정
    // ==========================================
    const exe = b.addExecutable(.{
        .name = "RealManApp",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    // ⭐️ [추가] 디버그 기호 보존을 위해 무조건 스트립(Strip)을 끕니다.
    exe.root_module.strip = false;

    // ⭐️ [추가] macOS 전용 디버그 심볼 생성을 강제합니다.
    if (os_tag == .macos) {
        exe.bundle_compiler_rt = true; // 런타임 심볼 보장
    }

    // Include Search Path 설정
    exe.root_module.addIncludePath(b.path("src"));
    exe.root_module.addIncludePath(b.path("src/includes"));

    // src 하위의 모든 .S / .s 어셈블리 소스 파일 자동 탐색 및 등록
    addAssemblyFilesRecursively(b, exe, "src") catch |err| {
        @panic(b.fmt("어셈블리 파일 탐색 중 에러 발생: {s}", .{@errorName(err)}));
    };

    // .NET AOT 및 Rust 빌드가 완료되어야 실행파일 링킹 진행
    exe.step.dependOn(&publish_dotnet.step);
    exe.step.dependOn(&cargo_build.step);

    // .NET 및 Rust 동적 라이브러리 연결
    exe.root_module.addObjectFile(dotnet_lib_path);
    exe.root_module.addObjectFile(rust_lib_path);
    exe.root_module.addRPathSpecial(rpath_token);

    if (os_tag == .macos) {
        exe.root_module.linkFramework("CoreFoundation", .{});
        exe.root_module.linkFramework("Security", .{});
    }

    // ==========================================
    // 4. 배포 및 설치 (zig-out/bin 복사) 스텝
    // ==========================================
    b.installArtifact(exe);

    // .NET dylib 복사 설치 (publish 완료 후 진행)
    const install_dotnet_lib = b.addInstallFileWithDir(dotnet_lib_path, .bin, dotnet_lib_name);
    install_dotnet_lib.step.dependOn(&publish_dotnet.step);
    b.getInstallStep().dependOn(&install_dotnet_lib.step);

    // Rust dylib 복사 설치 (cargo build 완료 후 진행)
    const install_rust_lib = b.addInstallFileWithDir(rust_lib_path, .bin, rust_lib_name);
    install_rust_lib.step.dependOn(&cargo_build.step);
    b.getInstallStep().dependOn(&install_rust_lib.step);

    // ==========================================
    // 5. 실행 (run) 스텝
    // ==========================================
    const run_step = b.step("run", "Build & run RealManApp");
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_step.dependOn(&run_cmd.step);
}

// OS Command 방식으로 .S / .s 어셈블리 파일 탐색
fn addAssemblyFilesRecursively(b: *std.Build, exe: *std.Build.Step.Compile, dir_path: []const u8) !void {
    const find_result = b.run(&.{
        "find", dir_path, "-type", "f", "(", "-name", "*.S", "-o", "-name", "*.s", ")",
    });

    var lines = std.mem.tokenizeAny(u8, find_result, "\r\n");
    while (lines.next()) |file_path| {
        if (file_path.len > 0) {
            exe.root_module.addAssemblyFile(b.path(file_path));
        }
    }
}
