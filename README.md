# trebekbot

A Jeopardy! bot for Slack, powered by the [jService](http://jservice.io/) API. Sets up a perpetual game of Jeorpardy! in your Slack channels.

![](http://i.imgur.com/BjMDf6Z.png)

## Installation

Clone the repo, set up a Heroku app with RedisCloud (the free level is more than enough), and set up a Slack outgoing webhook to post to it. Make sure to set up the config variables in
[.env.example](https://github.com/gesteves/trebekbot/blob/master/.env.example) in your Heroku app's settings screen.

## Usage

* `trebekbot jeopardy me`: starts a round of Jeopardy! trebekbot will pick a category and score for you.
* `trebekbot what/who is/are [answer]`: sends an answer. Remember, responses must be in the form of a question!
* `trebekbot what's my score`: shows your current score.
* `trebekbot help`: shows this help information.

## To-do

I literally built this in 20 minutes, so there's a lot to do.

* Better matching of answers (it's very strict)
* Speak out the answers after time runs out
* Let users select category and scores

## Credits & acknowledgements

Big thanks to [Steve Ottenad](https://github.com/sottenad) for building [jService](http://jservice.io/), the service that powers this bot.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License 

Copyright (c) 2014, Guillermo Esteves
All rights reserved.

BSD license

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
