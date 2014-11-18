#The site to monitor
site = 'github.com'

command: "ping -c 10 -q #{site}"

refreshFrequency: 20000

style: """
    top: 10px
    left: 10px
    font-family: Helvetica Neue
    color: #fff

    .time
        font-size: 42px
        text-align: right

    .site
        font-size: 21px
        text-align: right
        color: rgba(#fff, 0.5)
"""

render: -> """
<div id="response">
    <div class="time"><span class="timeval"></span>ms</div>
    <div class="site"></div>
</div
"""
#.*round.*\=.*\/(.*).*\/.*\/
update: (output, domEl) ->
    $container = $(domEl).find '#response'
    avg = Math.round((/.*round.*\=.*\/([0-9.]*).*\/.*\/.*ms/.exec(output))[1])
    site = (/PING(.*)\(/.exec(output))[1]
    $('.timeval').text avg
    $('.site').text site