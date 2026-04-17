"""Sort complex versions using packaging.version (replaces deprecated distutils.version)."""

from packaging.version import Version


def filter_sort_versions(value):
    """Ansible filter entrypoint: sorts a list of version strings."""
    return sorted(value, key=lambda v: Version(v))


class FilterModule(object):
    """Sort complex versions like 0.10.2, 0.1.1, 0.10.12."""

    def filters(self):
        return {"sort_versions": filter_sort_versions}
