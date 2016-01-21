restart
needsPackage "JSON"
A = get "./ReverseEngineering/gfan-input-data.json"
A = get "./ReverseEngineering/Gepasi.json"
B = parseJSON A
C = B#"task"#"input"#"reverseEngineeringInputData"
p = C#"fieldCardinality"
n = C#"numberVariables"
netList C#"timeSeriesData"
kk = ZZ/p
