# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""This defines a repository rule for configuring the rules' defaults.

The default can be specified as follows:
```python
  === WORKSPACE ===
  load(
    "@io_bazel_rules_k8s//k8s:with-defaults.bzl",
    "k8s_defaults",
  )
  k8s_defaults(
      # This is the name of the generated repository and the rule
      # it defines.
      name = "k8s_deploy",
      # This is the kind of object the generated rule supports manipulating.
      # If this is specified, it may not be overridden.  If not, then it must
      # be specified.
      kind = "deployment",
      # This is the cluster to which these rules communicate when one of the
      # auxiliary actions is `bazel run`.  If this is specified, it may not be
      # overridden.  If not, then it must be specified.
      cluster = "my-gke-cluster",
  )

  === BUILD ===
  load("@k8s_deploy//:defaults.bzl", "k8s_deploy")
```
"""

# Generate an override statement for a particular attribute.
def _override(name, attr, value):
  return """
  if "{attr}" in kwargs:
    fail("Cannot override '{attr}' in '{name}' rule.",
         attr="{attr}")
  kwargs["{attr}"] = "{value}"
""".format(name=name, attr=attr, value=value)


def _impl(repository_ctx):
  """Core implementation of k8s_defaults."""

  # This is required by Bazel.
  repository_ctx.file("BUILD", "")

  overrides = []
  if repository_ctx.attr.kind:
    overrides += [_override(repository_ctx.attr.name,
                            "kind", repository_ctx.attr.kind)]
  if repository_ctx.attr.cluster:
    overrides += [_override(repository_ctx.attr.name,
                            "cluster", repository_ctx.attr.cluster)]

  repository_ctx.file("defaults.bzl", """
load(
  "@io_bazel_rules_k8s//k8s:object.bzl",
  _k8s_object="k8s_object"
)

def {name}(**kwargs):
  {overrides}

  _k8s_object(**kwargs)
""".format(
  name=repository_ctx.attr.name,
  overrides="\n".join(overrides)
))

_k8s_defaults = repository_rule(
    attrs = {
        "kind": attr.string(
          # TODO(mattmoor): Support additional objects
          values = ["deployment"]),
        "cluster": attr.string(),
    },
    implementation = _impl,
)

def k8s_defaults(**kwargs):
  """Creates a version of docker_push with the specified defaults."""
  _k8s_defaults(**kwargs)
