'use babel';

export default [
  { type: "Function", regex: /^([a-z][a-zA-Z0-9_]+)[ ]*:[^:].*->.*/ },   // the group is the function name
  { type: "Type", regex: /^type +([A-Z][a-zA-Z_]+)/ },
  { type: "TypeAlias", regex: /^type alias +([A-Z][a-zA-Z_]+)/ },
  { type: "Constant", regex: /^([a-z][a-zA-Z0-9_]+) *:[^:][^-]+$/ },
  { type: "Port", regex: /^port +([a-z][a-zA-Z0-9_]+)[ ]*:[^:]/ },
];
