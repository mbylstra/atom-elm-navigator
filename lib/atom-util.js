'use babel';

import path from 'path';
import fs from 'fs';

function foldOverDirectoryTree({directory, func, initial, fileTypes, exclude}) {
  let acc = initial;

  const entries = directory.getEntriesSync();
  for (const entry of entries) {
    // use duck typing to work out if it's a Directory or File. Ugh. Get me outta here!
    if (typeof(entry.getEntriesSync) !== 'undefined') {
      const dir = entry;
      const dirPath = dir.getPath();
      const dirName = path.basename(dirPath);
      if (!exclude.includes(dirName)) {
        acc = foldOverDirectoryTree({directory: entry, func, initial: acc, fileTypes, exclude});
      }
    } else {
      const file = entry;
      const filePath = file.getPath();
      const filename = path.basename(filePath);
      if (fileTypes.includes(path.extname(filePath))) {
        contents = fs.readFileSync(filePath, 'utf8');
        acc = func({file, contents, acc});
      }
    }
  }
  return acc;
}

export { foldOverDirectoryTree };
