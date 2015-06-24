import QtQuick 2.4
import QtQuick.Controls 1.2
import QtMultimedia 5.4
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.3
import "./resource"
import CleanPlayerCore 1.0

Rectangle {
    id:root
    width:1000
    height: 600
    color: "#333333"
    MediaPlayer {
         id: mediaplayer

     }

    //工具函数
    Util {
        id:util
    }

    BaiduMusic {
        id: baiduMusic
        onSearchComplete: showSearchResult(currentPage,pageCount,keyword,songList)
        onGetSuggestionComplete: showSug(suggestion)

    }

    Playlist{
        id:playlist
        mediaPlayer: mediaplayer
        baiduMusic: baiduMusic
    }

    //底部栏
    Rectangle {
        id:bottomBar
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width
        height: 80
        color: "#444444"

        //播放、上一首、下一首
        Rectangle {
            id: playController
            width: 180
            height: parent.height
            color: "#00000000"
            anchors.leftMargin: 20
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            PreviousButton {
                id:previousButton
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                onPrevious: {
                   playlist.previous();
                }
            }
            PlayButton {
                id:playButton
                anchors.centerIn:parent
                onPause: {
                    //暂停
                    playlist.pause();
                }
                onPlay: {
                    //播放
                    playlist.play();
                }
            }
            NextButton {
                id:nextButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onNext: {
                    //下一首
                    playlist.next();
                }
            }
        }

        //进度条
        Slider {
            id:slider
            x:15
            anchors.left: playController.right
            anchors.leftMargin: 15
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            maximumValue:50
            value: 20
            stepSize:0.5
        }

    }


    //顶部栏
    Rectangle {
        id:topBar
        width: parent.width
        height: 60
        color: "#444444"
        anchors.left: parent.left
        anchors.top: parent.top

        //左上角
        Rectangle {
            id: brand
            width: 200
            height: parent.height
            anchors.top: parent.top
            anchors.left: parent.left
            Text {
                id: brandText
                font.pixelSize:28
                text: qsTr("CleanPlayer")
                anchors.centerIn: parent
            }
        }

        //搜索条
        SearchBar {
            anchors.left: brand.right
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter

            onTextCleared: {
                suggestionTips.visible = false;
            }
            onKeywordChanged: baiduMusic.getSuggestion(keyword)
            onBeforeSearch: {
                baiduMusic.search(keyword,1);
                suggestionTips.visible = false;
            }
            onTextFocusOut: {
                suggestionTips.visible = false;
            }
        }


        //边条
        Rectangle {
            width: parent.width
            height: 2
            color: "#E61E16"
            anchors.bottom: parent.bottom
        }
    }

    //左侧栏
    Rectangle {
        id: leftList
        width: 200
        color: "#555555"
        anchors.left: parent.left
        anchors.top: topBar.bottom
        anchors.bottom: bottomBar.top

        Component {
            id:leftListViewDelegate
            Item {
                width: 200
                height: 20
                Rectangle{
                    anchors.fill: parent
                    color:"gray"
                    Text {
                        anchors.centerIn: parent
                        text:listname
                    }
                }
            }
        }

        ListModel {
            id:leftListModel
        }

        ListView {
            id:leftListView
            anchors.fill: parent
            delegate: leftListViewDelegate
            model: leftListModel
            header: Component {
                Item {
                    width: 200
                    height: 30
                    Rectangle{
                        anchors.fill: parent
                        color:"white"
                        Text {
                            anchors.centerIn: parent
                            font.pixelSize:16
                            text:"播放列表"
                        }
                    }
                }
            }
        }

    }

    //内容区域
    Rectangle {
        id:container
        anchors.top: topBar.bottom
        anchors.left: leftList.right
        anchors.bottom: bottomBar.top
        anchors.right: parent.right
        SearchResult {
            id:searchResult
            anchors.fill: parent
            onSongDoubleClicked: {
                playlist.addSong(clone(song));
                var last = playlist.count() - 1;
                playlist.setIndex(last);
            }
            onPageChanged: {
                baiduMusic.search(keyword,pagenum);
            }
        }

    }

    //搜索建议弹出框
    Rectangle {
        id: suggestionTips
        anchors.top: topBar.bottom
        anchors.topMargin: -5
        anchors.left: topBar.left
        anchors.leftMargin: 220
        z:300
        height: 400
        width: 200
        color: "white"
        visible: false

        ListModel {
            id: suggestionModel
        }

        Component {
            id: highlightBar
            Rectangle {
                width: 200; height: 50
                color: "#FFFF88"
                y: suggestionView.currentItem.y;
            }

        }

        Component  {
            id: suggestionDelegate
            Item {
                id: wrapper
                width:200
                height: 20
                Rectangle{
                    Text {
                        text: sname + '-' + singer
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        wrapper.ListView.view.currentIndex = index;
                        suggestionTips.visible = false;
                        var song = suggestionModel.get(index);
                        playlist.addSong(clone(song));
                        var last = playlist.count() - 1;
                        playlist.setIndex(last);
                    }
                }
            }
        }

        ListView {
            id:suggestionView
            height: parent.height
            width: parent.width
            model: suggestionModel
            delegate: suggestionDelegate
            highlight: highlightBar
        }
    }

    MouseArea{
        anchors.fill: parent
        z:-1
        onClicked: {
            suggestionTips.visible = false;
        }
    }


    //显示搜索建议
    function showSug(sug){
        try{
            var suggestion = JSON.parse(sug);
            var data = suggestion.data
            var songs = data.song
            suggestionModel.clear();

            for(var i in songs){

                suggestionModel.append(songs[i]);
                 console.log("sug:"+JSON.stringify(songs[i]));
            }
            suggestionTips.visible = true

        } catch(e){
            console.log("showSug:"+e);
        }
    }

    //显示搜索结果
    function showSearchResult(cur,count,keyword,songlist){
        try{
            var songList = JSON.parse(songlist);
            //如果错误
            if(songList.error){
                //TODO:搜索出错
            }
        }catch(e){
            console.log(e);
            return;
        }
        searchResult.showResult(cur,count,keyword,songList)
    }

    //加载播放列表
    function loadPlaylist(){
        //读取保存的播放列表
        var savedList = JSON.parse(util.readFile("playlist"));
        for(var i in savedList){
            playlist.playlists[i] = savedList[i];
        }
    }

    //显示播放列表名称
    function showPlaylistName(){
        for(var i in playlist.playlists){
           leftListModel.append({"listname":i});
        }
    }

    //对象克隆
    function clone(obj){
        var o;
        switch(typeof obj){
        case 'undefined': break;
        case 'string'   : o = obj + '';break;
        case 'number'   : o = obj - 0;break;
        case 'boolean'  : o = obj;break;
        case 'object'   :
            if(obj === null){
                o = null;
            }else{
                if(obj instanceof Array){
                    o = [];
                    for(var i = 0, len = obj.length; i < len; i++){
                        o.push(clone(obj[i]));
                    }
                }else{
                    o = {};
                    for(var k in obj){
                        o[k] = clone(obj[k]);
                    }
                }
            }
            break;
        default:
            o = obj;break;
        }
        return o;
    }

   //关闭时
    Component.onDestruction: {
        //保存播放列表
        util.saveFile("playlist",JSON.stringify(playlist.playlists));
    }

    //加载结束
    Component.onCompleted: {
        //加载播放列表
        loadPlaylist();
        showPlaylistName();
        if(playlist.count()>0){
            playlist.index = 0;
        }
    }
}

