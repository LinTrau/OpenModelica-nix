# openmodelica-flake

将 [MBanucu/NixOS2505BuildOpenModelicaFromSource](https://github.com/MBanucu/NixOS2505BuildOpenModelicaFromSource) 重构为标准 Nix Flake，
解决原仓库只能在 `nix-shell` 里用、无法作为系统软件安装的问题。

## 使用方式

### 1. 临时试用

```bash
nix run github:your-user/openmodelica-flake
# 或者进入 shell
nix develop github:your-user/openmodelica-flake
```

### 2. 安装到用户 profile

```bash
nix profile install github:your-user/openmodelica-flake
```

### 3. 加入 NixOS 系统配置

**方式 A — 用内置 NixOS Module：**

```nix
# flake.nix（你自己系统的）
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    openmodelica.url = "github:your-user/openmodelica-flake";
  };

  outputs = { nixpkgs, openmodelica, ... }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      modules = [
        openmodelica.nixosModules.default
        {
          programs.openmodelica.enable = true;
        }
      ];
    };
  };
}
```

**方式 B — 用 overlay，手动加入 systemPackages：**

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    openmodelica.url = "github:your-user/openmodelica-flake";
  };

  outputs = { nixpkgs, openmodelica, ... }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      modules = [
        { nixpkgs.overlays = [ openmodelica.overlays.default ]; }
        {
          nixpkgs.config.permittedInsecurePackages = [ "python-2.7.18.8" ];
          environment.systemPackages = [ pkgs.openmodelica ];
        }
      ];
    };
  };
}
```

**方式 C — 直接引用 package：**

```nix
environment.systemPackages = [
  openmodelica.packages.x86_64-linux.default
];
```

## 文件说明

| 文件 | 说明 |
|---|---|
| `flake.nix` | 新增的 flake 入口，暴露 packages / devShells / overlay / nixosModule |
| `openmodelica-core.nix` | 从源码编译 OpenModelica 1.25.0 |
| `openmodelica.nix` | 用 makeWrapper 包装二进制，注入运行时环境变量|

## 注意事项

- 需要 NixOS 25.05（nixpkgs nixos-25.05）对应的 nixpkgs
- 首次构建需要从源码编译，耗时较长
- `python2` 被标记为 insecure，`permittedInsecurePackages` 已在 flake 内部处理好，
  使用 overlay 方式时需要在你的系统 nixpkgs.config 里也加上
