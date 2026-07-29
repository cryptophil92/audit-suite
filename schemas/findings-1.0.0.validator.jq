def nonempty_string:
  type == "string" and length > 0;

def string_array:
  type == "array" and all(.[]; nonempty_string);

def only_keys($allowed):
  (keys_unsorted - $allowed | length) == 0;

def safe_reference_path:
  nonempty_string
  and test("^[A-Za-z0-9][A-Za-z0-9._/-]*$")
  and (startswith("/") | not)
  and (test("(^|/)\\.\\.(/|$)") | not)
  and (test("^[A-Za-z]:") | not);

def asset_valid:
  type == "object"
  and only_keys(["id", "address", "hostname"])
  and (.id | nonempty_string)
  and ((has("address") | not) or (.address | nonempty_string))
  and ((has("hostname") | not) or (.hostname | nonempty_string))
  and (((.address // "") | length) > 0 or ((.hostname // "") | length) > 0);

def scope_valid:
  type == "object"
  and only_keys(["target", "relation"])
  and (.target | nonempty_string)
  and (.relation | IN("direct", "derived"));

def service_valid:
  . == null
  or (
    type == "object"
    and only_keys(["transport", "port", "name"])
    and (.transport | IN("tcp", "udp", "sctp", "other"))
    and (.port | type == "number" and floor == . and . >= 1 and . <= 65535)
    and (.name | nonempty_string)
  );

def scoring_valid:
  type == "object"
  and (
    (
      .status == "unscored"
      and only_keys(["status", "rationale"])
      and (.rationale | nonempty_string)
    )
    or
    (
      .status == "scored"
      and only_keys([
        "status",
        "score",
        "scale",
        "method",
        "method_version",
        "vector",
        "rationale",
        "source"
      ])
      and (.score | type == "number" and . >= 0)
      and (.scale | type == "number" and . > 0)
      and (.score <= .scale)
      and (.method | IN("cvss-v3.1", "cvss-v4.0", "source", "manual"))
      and (.method_version | nonempty_string)
      and (.rationale | nonempty_string)
      and (.source | nonempty_string)
      and (
        if .method == "cvss-v3.1" then
          (
            .vector
            | type == "string"
              and test(
                "^CVSS:3\\.1/AV:(N|A|L|P)/AC:(L|H)/PR:(N|L|H)/UI:(N|R)/S:(U|C)/C:(N|L|H)/I:(N|L|H)/A:(N|L|H)$"
              )
          )
        elif .method == "cvss-v4.0" then
          (
            .vector
            | type == "string"
              and test(
                "^CVSS:4\\.0/AV:(N|A|L|P)/AC:(L|H)/AT:(N|P)/PR:(N|L|H)/UI:(N|P|A)/VC:(H|L|N)/VI:(H|L|N)/VA:(H|L|N)/SC:(H|L|N)/SI:(H|L|N)/SA:(H|L|N)$"
              )
          )
        else
          ((has("vector") | not) or (.vector | nonempty_string))
        end
      )
    )
  );

def evidence_valid:
  type == "object"
  and only_keys(["id", "kind", "source", "path", "captured_at", "sha256"])
  and (.id | nonempty_string)
  and (.kind | IN("file_reference", "data_reference", "manual_reference"))
  and (.source | nonempty_string)
  and (.path | safe_reference_path)
  and (.captured_at | nonempty_string)
  and (
    (has("sha256") | not)
    or (.sha256 | type == "string" and test("^[A-Fa-f0-9]{64}$"))
  );

def source_valid:
  type == "object"
  and only_keys(["module", "tool", "tool_version", "collected_at", "provenance"])
  and (.module | nonempty_string)
  and ((has("tool") | not) or (.tool | nonempty_string))
  and ((has("tool_version") | not) or (.tool_version | nonempty_string))
  and (.collected_at | nonempty_string)
  and (.provenance | nonempty_string);

def remediation_valid:
  type == "object"
  and only_keys([
    "priority",
    "effort",
    "action",
    "rationale",
    "prerequisites",
    "change_risk",
    "compensating_control",
    "verification"
  ])
  and (.priority | IN("immediate", "short_term", "planned", "monitor", "none"))
  and (.effort | IN("low", "medium", "high", "unknown"))
  and (.action | nonempty_string)
  and (.rationale | nonempty_string)
  and ((.prerequisites // []) | string_array)
  and (.change_risk | nonempty_string)
  and (
    (has("compensating_control") | not)
    or (.compensating_control | nonempty_string)
  )
  and (.verification | nonempty_string);

def finding_valid:
  type == "object"
  and only_keys([
    "id",
    "type",
    "title",
    "category",
    "asset",
    "scope",
    "service",
    "severity",
    "scoring",
    "confidence",
    "validation_status",
    "observation",
    "impact",
    "evidence",
    "source",
    "remediation",
    "references",
    "limitations"
  ])
  and (.id | type == "string" and test("^finding\\.[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$"))
  and (.type | IN(
    "observation",
    "potential_vulnerability",
    "confirmed_vulnerability",
    "informational"
  ))
  and (.title | nonempty_string)
  and (.category | type == "string" and test("^[a-z][a-z0-9_]{1,63}$"))
  and (.asset | asset_valid)
  and (.scope | scope_valid)
  and (.service | service_valid)
  and (.severity | IN("informational", "low", "medium", "high", "critical", "unknown"))
  and (.scoring | scoring_valid)
  and (.confidence | IN("low", "medium", "high"))
  and (.validation_status | IN(
    "observed",
    "potential",
    "confirmed",
    "false_positive",
    "accepted_risk",
    "resolved",
    "unknown"
  ))
  and (.observation | nonempty_string)
  and (.impact | nonempty_string)
  and (.evidence | type == "array" and length > 0 and all(.[]; evidence_valid))
  and (.source | source_valid)
  and (.remediation | remediation_valid)
  and (.references | string_array)
  and (.limitations | string_array);

. as $items
| ($items | type == "array")
  and all($items[]; finding_valid)
  and (($items | map(.id) | unique | length) == ($items | length))
