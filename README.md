# **Flatware** 

**Flatware** provides a tiny S3 buffer between you and Google Spreadsheets, protecting you from downtime, lag and the terrifying caprice of Mountain View. It's meant to be used with [Tabletop.js](https://github.com/jsoma/tabletop).

### The Whole Shebang

**Step One**: [Get a Heroku account](https://devcenter.heroku.com/articles/quickstart) and install their [Toolbelt nonsense](https://toolbelt.heroku.com)

**Step Two**: [Get an Amazon Web Services account](http://aws.amazon.com) and [create an S3 bucket](http://www.hongkiat.com/blog/amazon-s3-the-beginners-guide/)

**Step Three**: Clone this repo and push it up to an Heroku instance

    git clone git@github.com:jsoma/flatware.git
    cd flatware
    heroku create
    git push heroku master

**Step Four**: Visit your page and add a Google Spreadsheet. Maybe just use this one down here:

    https://docs.google.com/spreadsheet/pub?hl=en_US&hl=en_US&key=0AmYzu_s7QHsmdE5OcDE1SENpT1g2R2JEX2tnZ3ZIWHc&output=html
    
**Step Five**: Process the JSON to S3, using either `heroku run rake flatware:process` or clicking the **Sync all spreadsheets** button.

**Step Six**: Edit a Tabletop.js file to reflect your new cached set of data on S3. Try `/examples/proxy/index.html` and changing `proxy: 'https://s3.amazonaws.com/flatware-live'` to reflect your bucket

**Step Seven**: If you'd like, you can use [Heroku Scheduler](https://devcenter.heroku.com/articles/scheduler) to automatically run your `rake` task every X minutes.

### Me?

Hi, I'm Soma, I make things. Questions/comments/tiny daggers can be shot to [@dangerscarf](http://twitter.com/dangerscarf) or [jonathan.soma@gmail.com](jonathan.soma@gmail.com).