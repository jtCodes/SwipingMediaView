# SwipingMediaView

### Photos like media swiping for SwiftUI

![RPReplay_Final1662876842 2022-09-11 02_21_24](https://user-images.githubusercontent.com/23707104/189515150-98464eb3-def0-4214-beea-ed9105a13a20.gif)

### Features
- Supports images, gifs and videos
- Pinch to zoom
- Drag to dismiss
- Download images (Important: you must add Privacy - Photo Library Additions Usage Description to info.plist in order to get the download button to work)

### Simple example
```Swift

import SwiftUI
import SwipingMediaView

struct ContentView: View {
    @State var isPresented: Bool = false
    @State var currentIndex: Int = 1
    var mediaItems: [SwipingMediaItem] = []

    init() {
        self.mediaItems =  [SwipingMediaItem(url: "https://i.redd.it/8t6vk567khm91.jpg",
                                             type: .image),
                            SwipingMediaItem(url: "https://i.redd.it/gczavw14bfm91.gif",
                                             type: .gif),
                            SwipingMediaItem(url: "https://preview.redd.it/g232r4ymm4l91.gif?format=mp4&s=91cc39ae920fb57e3273aca59f4e273d974e1253",
                                             type: .video)]
    }

    var body: some View {
        ZStack {
            Color.green
            VStack() {
                Text(String(currentIndex))
                Spacer()
                Button("Present gallery view") {
                    isPresented = true
                }
            }.padding(100)
        }
        .background(Color.blue)
        // FullScreenCover works well in presenting SwipingMediaView
        .fullScreenCover(isPresented: $isPresented) {
            ZStack{
                SwipingMediaView(controllers: mediaItems.map {AnyView(SwipingMediaItemView(mediaItem: $0,
                                                                                           isPresented: $isPresented,
                                                                                           shouldShowDownloadButton: true
                                                                                          ))},
                                 currentIndex: $currentIndex,
                                 startingIndex: currentIndex)
            }
            // Adding a clear background helper here to achieve on drag fading background effect
            .background(BackgroundCleanerView())
            // Ignoring safe area so pinch to zoom don't get cut off
            .ignoresSafeArea(.all)
        }
        .ignoresSafeArea(.all)
    }
}
```
### Example with horizontal scrolled images and on swipe handling
```Swift

struct ContentView: View {
    @State var isPresented: Bool = false
    @State var currentIndex: Int = 1
    var images: [String] = []
    var mediaItems: [SwipingMediaItem] = []

    init() {
        for i in 0..<64 {
            images.append("https://picsum.photos/250?image=" + String(i))
            mediaItems.append(SwipingMediaItem(url: "https://picsum.photos/250?image=" + String(i),
                                                                                        type: .image,
                                                                                        title: "Image " + String(i)))
        }
    }

    var body: some View {
        ZStack {
            Color.green.opacity(0.5)
            VStack() {
                Text("Current index: " + String(currentIndex))
                Spacer()
            }.padding(100)

            // Horizontal scrolled image view.
            // This is responsible for bringing up the full screen SwipingMediaView.
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(0..<images.count) { index in
                            WebImage(url: URL(string: images[index]))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300, alignment: .center)
                                .id(index)
                                .onTapGesture {
                                    currentIndex = index
                                    isPresented = true
                                }
                        }
                        // Scrolling the view to the image that's being shown on SwipingMediaView
                        .onChange(of: currentIndex) { newIndex in
                            proxy.scrollTo(newIndex, anchor: .top)
                        }
                    }
                }
            }
        }
        // FullScreenCover works well in presenting SwipingMediaView
        .fullScreenCover(isPresented: $isPresented) {
            ZStack{
                SwipingMediaView(controllers: mediaItems.map {AnyView(SwipingMediaItemView(mediaItem: $0,
                                                                                           isPresented: $isPresented,
                                                                                           shouldShowDownloadButton: true
                                                                                          ))},
                                 currentIndex: $currentIndex,
                                 startingIndex: currentIndex)
            }
            // Adding a clear background helper here to achieve on drag fading background effect
            .background(BackgroundCleanerView())
            // Ignoring safe area so pinch to zoom don't get cut off
            .ignoresSafeArea(.all)
        }
        .ignoresSafeArea(.all)
    }
}
```

## Installation via Swift Package Manager

You can install `SwipingMediaView` using Swift Package Manager in Xcode:

1. Open your Xcode project.
2. Navigate to `File` > `Swift Packages` > `Add Package Dependency`.
3. Enter the repository URL: `https://github.com/jtCodes/SwipingMediaView.git`
4. Specify the version you want to use. You can specify a version number, a branch name, or a commit hash.
5. Once added, you can import `SwipingMediaView` in your SwiftUI files and start using it.
