# FeedMe by Morten Sieker <http://sieker.dk>
# Change the RSS-feed, update interval and number of entries as needed
# Defaults to a 5 entries and updates every 5 minutes

#The feed to monitor
feed = 'http://feeds.arstechnica.com/arstechnica/index?format=xml'

#Display X number of entries
entries = 5

#Refresh every X minute
interval = 5

command: "curl -s 'http://ajax.googleapis.com/ajax/services/feed/load?v=1.0&num=#{entries}&q=#{feed}'"
refreshFrequency: interval * 60000

style: """
    top: 100px
    left: 10px
    font-family Avenir, Helvetica Neue
    color: #fff

    #feed
        background: rgba(#000, 0.4)

    #feedtitle
        background: rgba(#000, 0.6) 
        color: rgba(#fff, 0.7)
        text-transform: uppercase
        text-align: right
        font-size: 20px
        padding: 10px   
        transform: rotate(-90deg)
        transform-origin: right top
        position: absolute
        top: 0
        right: 100%

    .entry
        padding: 10px 20px

    .title
        font-size: 20px
        font-weight: 400
        color: rgba(#fff, 0.8)

    .date
        font-size: 12px;
        font-weight: 400
        color: rgba(#fff, 0.4)
"""

render: -> """
    <div id="feed">
    </div>
"""

update: (output, domEl) ->
    $domEl = $(domEl)
    $container = $domEl.find '#feed'
    $container.empty()
    result = JSON.parse output
    title = result.responseData.feed.title
    $container.append('<div id="feedtitle">'+title+'</div>')
    
    for e in result.responseData.feed.entries
        localdate = new Date(e.publishedDate)
        localdate = localdate.toLocaleDateString()
        $container.append('<div class="entry"><div class="title">'+e.title+'</div><div class="date">'+localdate+'</div></div>')

    $('.entry').css('margin-left', $domEl.find('#feedtitle').height())
    $('#feedtitle').css('width', $domEl.find('#feed').height()-20)

    