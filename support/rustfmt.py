"""Apply one Rust style while respecting Cargo's parser edition metadata."""

from collections import defaultdict
from pathlib import Path
import subprocess
import sys
import tomllib


def read_manifest(path):
    return tomllib.loads(path.read_text())


def edition_for(source):
    for parent in Path(source).resolve().parents:
        manifest = parent / "Cargo.toml"
        if not manifest.is_file():
            continue
        package = read_manifest(manifest).get("package")
        if package is None:
            continue
        edition = package.get("edition", "2015")
        if isinstance(edition, str):
            return edition
        if edition.get("workspace") is not True:
            raise ValueError(f"Invalid edition in {manifest}")
        roots = (
            [(parent / package["workspace"]).resolve()]
            if "workspace" in package
            else [parent, *parent.parents]
        )
        for root in roots:
            workspace_manifest = root / "Cargo.toml"
            if workspace_manifest.is_file():
                workspace = read_manifest(workspace_manifest).get("workspace")
                if workspace is not None:
                    inherited = workspace.get("package", {}).get("edition")
                    if not isinstance(inherited, str):
                        raise ValueError(
                            f"No workspace.package.edition in {workspace_manifest}"
                        )
                    return inherited
        raise ValueError(f"No workspace found for {manifest}")
    return "2024"


def main():
    binary, settings, *files = sys.argv[1:]
    groups = defaultdict(list)
    for source in files:
        groups[edition_for(source)].append(source)
    for edition, sources in groups.items():
        result = subprocess.run(
            [binary, "--config-path", settings, "--edition", edition, *sources],
            check=False,
        )
        if result.returncode:
            return result.returncode
    return 0


if __name__ == "__main__":
    sys.exit(main())
