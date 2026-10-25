# R1 input

Review request: read-only review of this diff.

```diff
-    out = os.path.join(root, name)
+    out = root + "/" + name
     result = run(cmd)
-    if result.returncode != 0:
-        raise Failed(result)
+    log(result)
+  # comment with odd indent
```

The project runs on Windows and Linux.
