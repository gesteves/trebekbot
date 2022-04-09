# trebekbot

A Jeopardy! bot for Slack, powered by the [jService](http://jservice.io/) API. Sets up a perpetual game of Jeopardy! in your Slack channels.

<img width="671" alt="Screen Shot 2022-04-06 at 11 00 17 AM" src="https://user-images.githubusercontent.com/6379/162028505-0811ac6e-2e15-494b-b8dc-33a168af8320.png">

## Installation

Just click this button to add the bot to your Slack team:

<a href="https://slack.com/oauth/v2/authorize?client_id=20888890816.3331520890821&redirect_uri=https%3A%2F%2Fwww.trebekbot.com%2Fslack%2Fauth&scope=users%3Aread%2Capp_mentions%3Aread%2Cchat%3Awrite"><img alt="Add to Slack" height="40" width="139" src="https://platform.slack-edge.com/img/add_to_slack.png" srcSet="https://platform.slack-edge.com/img/add_to_slack.png 1x, https://platform.slack-edge.com/img/add_to_slack@2x.png 2x" /></a>

## Usage

After installing the bot, invite it into one or more channels with `/invite @trebekbot`. Pro-tip: Create a new channel (for example, #jeopardy) just for this purpose, to avoid creating a huge distraction in other channels.

After that, simply mentioning "@trebekbot" will start a new game in the current channel.

You can also say:

* "@trebekbot my score" to see your current score
* "@trebekbot leaderboard" to see the top scores
* "@trebekbot help" to see a list of commands
