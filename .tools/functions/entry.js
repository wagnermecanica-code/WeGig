"use strict";

// Keep the existing exports from index.js, plus any extra modules we add.
const core = require("./index.js");
const blocksIndex = require("./blocks_index.js");
const moderation = require("./moderation.js");
const nearbyOverride = require("./nearby_posts_override.js");
const commentNotification = require("./comment_notification.js");

module.exports = {
  ...core,
  ...blocksIndex,
  ...moderation,
  ...nearbyOverride,
  ...commentNotification,
};
