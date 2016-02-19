// ---------------------------------------------------------------------------------------------------------------------
// Easy Share action handler
//
// @module share
// ---------------------------------------------------------------------------------------------------------------------

Meteor.subscribe('subscription', {
    onReady: function()
    {
        readFile(cordova.file.cacheDirectory, 'pendingShare.json', function(err, shareInfo)
        {
            if(err)
            {
                return;
            }

            removeFile(cordova.file.cacheDirectory, 'pendingShare.json', function() { });
            selectRoom(JSON.parse(shareInfo));
        });

        cordova.SharingReceptor.listen(function(data)
        {
            var serverOptions = '';
            if(Servers.getServers().length > 1)
            {
                serverOptions = _.reduce(Servers.getServers(), function(accString, server)
                {
                    return accString + '<option value="' + server.url + '">' + server.name + '</option>';
                }, '');

                var serverString = '<select id="server-select" name="server-list">' + serverOptions + '</select>';

                swal({
                        title: 'Select server',
                        text: serverString,
                        html: true,
                        animation: true,
                        showCancelButton: true
                    },
                    function()
                    {
                        var currentServerUrl = Servers.getActiveServer().url;
                        var serverUrl = $('#server-select')[0].value;

                        if(serverUrl != currentServerUrl)
                        {
                            writeFile(cordova.file.cacheDirectory, 'pendingShare.json', JSON.stringify(data), function(err, data)
                            {
                                if(err)
                                {
                                    console.log('Error saving share file', err);
                                    return;
                                }
                                localStorage.setItem('pendingShare', JSON.stringify(data));

                                $(document.body).addClass('loading');
                                $('.loading-text').text(cordovai18n("Loading_s", serverUrl));
                                setTimeout(function()
                                {
                                    Servers.setActiveServer(serverUrl);
                                    Servers.startServer(serverUrl, function() { });
                                }, 200);
                            });
                        }
                        else
                        {
                            selectRoom(data);
                        }
                    });
            }
            else
            {
                selectRoom(data);
            }
        });

    }
});

function selectRoom(data)
{
    var roomPrefixes = {
        d: '@',
        p: '&',
        c: '#'
    };

    var rooms = _.sortBy(ChatSubscription.find({open: true}).fetch(), function(room)
    {
        return [room.t, room.name].join('-');
    });

    var innerString = _.reduce(rooms, function(accString, room)
    {
        return accString + '<option value="' + room.name + '">' + roomPrefixes[room.t] + ' ' + room.name + '</option>';
    }, '');

    var tempString = '<select id="room-select" name="room-list">' + innerString + '</select>';

    swal({
        title: 'Select room to share',
        text: tempString,
        html: true,
        animation: true,
        showCancelButton: true
    }, function()
    {
        var roomName = $('#room-select')[0].value;
        var roomModel = ChatSubscription.findOne({name: roomName});

        if(roomModel)
        {
            doShare(roomModel, data);
        }
    });
}

function doShare(roomModel, data)
{
    if(_.startsWith(data.intent.type, 'text'))
    {
        // Add callback to send message when ready
        RocketChat.callbacks.add('enter-room', function(room)
        {
            // Actually send the message
            Meteor.call('sendMessage', {
                _id: Random.id(),
                rid: roomModel.rid,
                ts: new Date(),
                msg: data.intent.extras['android.intent.extra.TEXT']
            });

            // Clean up the callback
            RocketChat.callbacks.remove('enter-room', 'ShareText');
        }, RocketChat.callbacks.priority.MEDIUM, 'ShareText');

        // Open selected room to upload
        openRoom(roomModel.t, roomModel.name);
    }
    else if(_.startsWith(data.intent.type, 'image'))
    {
        // Get Android FileEntry
        resolveLocalFileSystemURL(data.intent.extras['android.intent.extra.STREAM'], function(fsEntry)
        {
            // Get HTML5 File object
            fsEntry.file(function(fileObj)
            {
                // Add callback to upload when room is ready
                RocketChat.callbacks.add('enter-room', function(room)
                {
                    // Actually upload the file (this needs to be deferred for some reason)
                    Meteor.defer(function()
                    {
                        fileUpload([
                            {
                                file: fileObj,
                                name: 'Shared File'
                            }
                        ]);

                        // Clean up the callback
                        RocketChat.callbacks.remove('enter-room', 'UploadFile');
                    });
                }, RocketChat.callbacks.priority.MEDIUM, 'UploadFile');

                // Open selected room to upload
                openRoom(roomModel.t, roomModel.name);
            });
        });
    }
}

// ---------------------------------------------------------------------------------------------------------------------