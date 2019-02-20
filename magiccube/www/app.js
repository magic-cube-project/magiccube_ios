/**
 * version
 * @param {*} originalVersion 
 * @param {*} newVersion 
 */
function versionControl(originalPath, newPath, channel) {
    function _loadUrl(url) {
        window.location.href = url;
    }

    Jajax({
        url: "https://api.mofangvr.com/setting/channelLimit",
        data: {
            channel: channel
        },
        complete: function (res) {
            let remoteVersion = res.result.version; //远程版本
            let userAgentMessage = navigator.userAgent;
            let tap = 'app_version:';
            let index = userAgentMessage.search(tap)
            let localVersion = userAgentMessage.substring(index + tap.length, userAgentMessage.length)
            console.log(remoteVersion,localVersion);
            if (remoteVersion >= localVersion) {
                 _loadUrl(newPath);
            } else{
                _loadUrl(originalPath);
            }
        },
        json_back: true,
        error: function () {
            _loadUrl(originalPath);
        }
    });
}

versionControl("app/ios/index.html?sys=ios&t=1","https://exchange.mofangvr.com", "ios");

