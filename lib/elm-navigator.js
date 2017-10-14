'use babel';

import fs from 'fs';
import path from 'path';
import ElmNavigatorView from './elm-navigator-view';
import { CompositeDisposable, Disposable } from 'atom';
import { foldOverDirectoryTree } from './atom-util';
import regexes from './regexes';


Array.prototype.extend = function(other_array) {
  other_array.forEach(function(v) {
    this.push(v);
  }, this);
};

var nextNavigatorUpdate = null;

export default {
  elmNavigatorView: null,
  modalPanel: null,
  subscriptions: null,

  activate(state) {


    var atomPlugin = this;
    var project = atom.project;
    var directories = project.getDirectories();
    var projectDirectory = null;
    if (directories.length > 0) {
      projectDirectory = directories[0];
    }


    var activePaneItem = null;

    this.elmNavigatorView = new ElmNavigatorView(state.elmNavigatorViewState);

    var elm = this.elmNavigatorView.elm;
    this.elm = elm;
    elm.ports.goToLineInFile.subscribe(function({ uri, lineNumber }) {
      atom.workspace.open(uri, { initialLine: lineNumber });
    });

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();

    this.subscriptions.add(

      atom.workspace.addOpener(uri => {
        if (uri === 'atom://elm-navigator') {
          return this.elmNavigatorView;
        }
      }),

      // Register command that toggles this view
      atom.commands.add('atom-workspace', {
        'elm-navigator:toggle': () => this.toggle()
      }),


    );

    atom.workspace.observeActivePaneItem(function(activePaneItem) {


      atomPlugin.activePaneItem = activePaneItem;



      if (typeof activePaneItem !== 'undefined') {
        if (typeof activePaneItem.onDidChange !== 'undefined') {

          activePaneItem.onDidChange(function() {
            nextNavigatorUpdate = {
              when: 'IN_TWO_TICKS',
            };
          })

          const filePath = activePaneItem.getPath();
          if (typeof filePath !== 'undefined' && filePath != null) {
            elm.ports.activeFileChanged.send({ filePath });
          }

        } else {
          nextNavigatorUpdate = null;
        }
      }
    });

    atom.workspace.open('atom://elm-navigator');

    //TODO: remove interval when deactivated

    (function() {
      const UPDATE_INTERVAL_SECONDS = 1.0;
      setInterval(function() {
        if (nextNavigatorUpdate != null) {
          if (nextNavigatorUpdate.when == 'NEXT_TICK') {
            try {
              if (atomPlugin.activePaneItem !== 'undefined') {
                if (atomPlugin.activePaneItem.buffer !== 'undefined') {
                  const editorText = atomPlugin.activePaneItem.buffer.cachedText;
                  if (editorText != null && typeof editorText !== 'undefined') {
                    const filePath = atomPlugin.activePaneItem.getPath();
                    if (typeof filePath !== 'undefined') {
                      const rawTags = editorTextToRawTags(editorText, filePath);
                      const payload = { filePath, rawTags };
                      elm.ports.fileUpdated.send(payload);
                    }
                  }
                }
              }
            } catch (error) {
            }

            nextNavigatorUpdate = null;
          } else if (nextNavigatorUpdate.when == 'IN_TWO_TICKS') {
            nextNavigatorUpdate.when = 'NEXT_TICK'; // it will update in the next tick
          }
        } else {
          // console.log("no navigator update queued");
        }
      }, UPDATE_INTERVAL_SECONDS * 1000);
    })();

    if (projectDirectory != null) {
      setTimeout(function() {
        // setTimeout is an awful hack to delay this expensive synchronous code
        // until after the sidebar has rendered.The better solution is to use
        // async when traversing the directory, which also frees up the UI to
        // do things like display a spinner
        const data = foldOverDirectoryTree({
          directory: projectDirectory,
          func: ({ file, contents, acc }) => {
            const filePath = file.path;
            const rawTags = editorTextToRawTags(contents, filePath);
            acc.extend(rawTags);
            return acc;
          },
          initial: [],
          fileTypes: ['.elm'],
          exclude: ['node_modules', 'elm-stuff'],
        });
        elm.ports.filesUpdated.send(data);
      }, 0);
    }
  },

  deactivate() {
    this.subscriptions.dispose();
    this.elmNavigatorView.destroy();
  },

  toggle() {
    atom.workspace.toggle('atom://elm-navigator');
  },

  serialize() {
    return {
      elmNavigatorViewState: this.elmNavigatorView.serialize(),
    };
  },
};

function editorTextToRawTags(text, filePath) {
  const lines = text.split('\n');
  const numLines = lines.length;

  const output = [];

  for (var lineNumber = 0; lineNumber < numLines; lineNumber++) {
    const line = lines[lineNumber];
    const lineType = determineLineType(line);
    if (lineType) {
      output.push({
        type_: lineType.type_,
        context: lineType.context,
        symbol: lineType.symbol,
        filePath: filePath,
        lineNumber: lineNumber,
      });
    }
  }

  return output;
}

function determineLineType(line) {
  for (const regex of regexes) {
    const matches = line.match(regex.regex);
    if (matches) {
      const context = matches[0];
      const symbol = matches[1];
      return {
        type_: regex.type,
        context,
        symbol,
      };
    }
  }
}
