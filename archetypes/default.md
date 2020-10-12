---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true

---

{{ range first 10 ( where .Site.RegularPages "Type" "cool" ) }}
* {{ .Title }}
{{ end }}