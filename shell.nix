{ pkgs ? import <nixpkgs> {} }:

# Define the environment
pkgs.mkShell {
  buildInputs = with pkgs;[
    gcc
  ];
}
