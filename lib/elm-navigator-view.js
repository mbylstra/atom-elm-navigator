'use babel';

import elmApp from '../elm/built/elm.js';

export default class ElmNavigatorView {

  constructor(serializedState) {
    // Create root element


    this.element = document.createElement('div');
    this.element.classList.add('elm-navigator');

    const elm = elmApp.Main.embed(this.element);
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


  getTitle() {
    // Used by Atom for tab text
    return 'Elm Navigator';
  }

  getIconName() {
    return 'list-unordered';
  }

  getDefaultLocation() {
    // This location will be used if the user hasn't overridden it by dragging the item elsewhere.
    // Valid values are "left", "right", "bottom", and "center" (the default).
    return 'left';
  }

  getAllowedLocations() {
    // The locations into which the item can be moved.
    return ['left', 'right'];
  }

  getURI() {
    // Used by Atom to identify the view when toggling.
    return 'atom://elm-navigator'
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
