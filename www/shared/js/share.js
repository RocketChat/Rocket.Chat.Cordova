// ---------------------------------------------------------------------------------------------------------------------
// Easy Share action handler
//
// @module share
// ---------------------------------------------------------------------------------------------------------------------

cordova.SharingReceptor.listen(function(data)
{
    swal({
        title: 'Select Room',
        text: 'Input room name to share:',
        type: 'input',
        showCancelButton: true,
        animation: 'slide-from-top',
        inputPlaceholder: 'testing'
    }, function(roomName)
    {
        var roomModel = RocketChat.models.Subscriptions.findOne({name: roomName});
        if(roomModel)
        {
            doShare(roomModel, data);
        }
    });
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