'use babel';

import elmApp from '../elm/built/elm.js';

export default class ElmNavigatorView {

  constructor(serializedState, tagsFileContents) {
    // Create root element
    this.element = document.createElement('div');
    this.element.classList.add('elm-navigator');

    const elm = elmApp.Main.embed(this.element, tagsFileContents);
    this.elm = elm;

    elm.ports.focusDomElement.subscribe(function({id}) {
      const anchorElement = document.getElementById(id);
      if (anchorElement != null) {
        const paneElement = document.querySelector(".esn-project-tags");
        paneElement.scrollTop = anchorElement.offsetTop - 55;
      } else {
        // console.log('could not find element', id);
      }
    })

  }

  // Returns an object that can be retrieved when package is activated
  serialize() {}

  // Tear down any state and detach
  destroy() {
    this.element.remove();
  }

  getElement() {
    return this.element;
  }

}
