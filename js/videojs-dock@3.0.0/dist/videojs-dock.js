/*! @name videojs-dock @version 3.0.0 @license Apache-2.0 */
(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports, require('video.js')) :
  typeof define === 'function' && define.amd ? define(['exports', 'video.js'], factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, factory(global.videojsDock = {}, global.videojs));
})(this, (function (exports, videojs) { 'use strict';

  function _interopDefaultLegacy (e) { return e && typeof e === 'object' && 'default' in e ? e : { 'default': e }; }

  var videojs__default = /*#__PURE__*/_interopDefaultLegacy(videojs);

  let guid = 1;

  const newGuid = function newGuid() {
    return guid++;
  };

  var version = "3.0.0";

  const dom = videojs__default["default"].dom || videojs__default["default"];
  const registerPlugin = videojs__default["default"].registerPlugin || videojs__default["default"].plugin;
  const Component = videojs__default["default"].getComponent('Component');
  /**
   * Title Component
   */

  class Title extends Component {
    constructor(player, options) {
      super(player, options);
      const tech = player.$('.vjs-tech');
      tech.setAttribute('aria-labelledby', this.title.id);
      tech.setAttribute('aria-describedby', this.description.id);
    }

    createEl() {
      const title = dom.createEl('div', {
        className: 'vjs-dock-title',
        title: this.options_.title,
        innerHTML: this.options_.title
      }, {
        id: `vjs-dock-title-${newGuid()}`
      });
      const desc = dom.createEl('div', {
        className: 'vjs-dock-description',
        title: this.options_.description,
        innerHTML: this.options_.description
      }, {
        id: `vjs-dock-description-${newGuid()}`
      });
      const el = super.createEl('div', {
        className: 'vjs-dock-text'
      });
      this.title = title;
      this.description = desc;
      el.appendChild(title);
      el.appendChild(desc);
      return el;
    }

    update(title, description) {
      this.title.innerHTML = '';
      this.description.innerHTML = '';
      this.title.appendChild(document.createTextNode(title));
      this.description.appendChild(document.createTextNode(description));
    }

  }
  /**
   * Shelf Component
   */

  class Shelf extends Component {
    createEl() {
      return super.createEl('div', {
        className: 'vjs-dock-shelf'
      });
    }

  }
  videojs__default["default"].registerComponent('Title', Title);
  videojs__default["default"].registerComponent('Shelf', Shelf);
  /**
   * A video.js plugin.
   *
   * In the plugin function, the value of `this` is a video.js `Player`
   * instance. You cannot rely on the player being in a "ready" state here,
   * depending on how the plugin is invoked. This may or may not be important
   * to you; if not, remove the wait for "ready"!
   *
   * @function dock
   * @param    {Object} [options={}]
   *           An object of options left to the plugin author to define.
   */

  const dock = function (options) {
    const opts = options || {};
    const settings = {
      title: {
        title: opts.title || '',
        description: opts.description || ''
      }
    };
    let title = this.title;
    let shelf = this.shelf;
    this.addClass('vjs-dock'); // If dock is initalized as part of player options, the player won't be ready
    // and the dock items will be hidden by the poster image when it's created.
    // In those cases, wait for player ready.

    this.ready(() => {
      const bpbIndex = this.children().indexOf(this.getChild('bigPlayButton'));
      const index = bpbIndex > 0 ? bpbIndex - 1 : null; // add shelf first so `title` is added before it if available
      // because shelf will now be at index

      if (!shelf) {
        shelf = this.shelf = this.addChild('shelf', settings, index);
      }

      if (!title) {
        title = this.title = this.addChild('title', settings.title, index);
      } else {
        title.update(settings.title.title, settings.title.description);
      }

      this.one(title, 'dispose', function () {
        this.title = null;
      });
      this.one(shelf, 'dispose', function () {
        this.shelf = null;
      }); // Update aria attributes to describe video content if title/description
      // IDs and text content are present. If unavailable, accessibility
      // landmark can fall back to generic `Video Player` aria-label.

      const titleEl = title.title;
      const descriptionEl = title.description;
      const titleId = titleEl.id;
      const descriptionId = descriptionEl.id;

      if (titleId && titleEl.textContent) {
        this.setAttribute('aria-labelledby', this.id() + ' ' + titleId);
      }

      if (descriptionId && descriptionEl.textContent) {
        this.setAttribute('aria-describedby', descriptionId);
      }
    }, true);
  };

  dock.VERSION = version; // Register the plugin with video.js.

  registerPlugin('dock', dock);

  exports.Shelf = Shelf;
  exports.Title = Title;
  exports["default"] = dock;

  Object.defineProperty(exports, '__esModule', { value: true });

}));
