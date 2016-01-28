// ---------------------------------------------------------------------------------------------------------------------
// Easy Share action handler
//
// @module share
// ---------------------------------------------------------------------------------------------------------------------

Meteor.subscribe('subscription', {
    onReady: function()
    {
        cordova.SharingReceptor.listen(function(data)
        {
            var rooms = _.sortBy(ChatSubscription.find().fetch(), 'name');
            var innerString = _.reduce(rooms, function(accString, room)
            {
                return accString + '<option value="' + room.name + '">' + room.name + '</option>';
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
        });

    }
});

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