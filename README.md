# SwipingMediaView

### Photos like media swiping for SwiftUI

https://user-images.githubusercontent.com/23707104/189459481-2fa4bc93-022c-49be-837b-b06dc9f86fcb.mp4

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
    var controllers: [AnyView] = []

    init() {
        self.controllers =  [AnyView(SwipingMediaItemView(mediaItem: SwipingMediaItem(url: "https://i.redd.it/8t6vk567khm91.jpg",
                                                                                      type: .image))),
                             AnyView(SwipingMediaItemView(mediaItem: SwipingMediaItem(url: "https://i.redd.it/gczavw14bfm91.gif",
                                                                                      type: .image))),
                             AnyView(SwipingMediaItemView(mediaItem: SwipingMediaItem(url: "https://preview.redd.it/g232r4ymm4l91.gif?format=mp4&s=91cc39ae920fb57e3273aca59f4e273d974e1253",
                                                                                      type: .video)))]
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
        .fullScreenCover(isPresented: $isPresented) {
            ZStack{
                SwipingMediaView(controllers: controllers,
                                 currentIndex: $currentIndex,
                                 startingIndex: 1)
            }
            .background(BackgroundCleanerView())
            .ignoresSafeArea(.all)
        }
        .transaction({ transaction in
            if (!isPresented) {
                transaction.disablesAnimations = true
            }
        })
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
    var controllers: [AnyView] = []
    
    init() {
        for i in 0..<64 {
            images.append("https://picsum.photos/250?image=" + String(i))
            controllers.append(AnyView(SwipingMediaItemView(mediaItem: SwipingMediaItem(url: "https://picsum.photos/250?image=" + String(i),
                                                                                        type: .image,
                                                                                        title: "Image " + String(i)),
                                                            shouldShowDownloadButton: true
            )))
        }
    }
    
    var body: some View {
        ZStack {
            Color.green.opacity(0.5)
            VStack() {
                Text("Current index: " + String(currentIndex))
                Spacer()
            }.padding(100)
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
                        .onChange(of: currentIndex) { newIndex in
                            proxy.scrollTo(newIndex, anchor: .top)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isPresented) {
            ZStack{
                SwipingMediaView(controllers: controllers,
                                 currentIndex: $currentIndex,
                                 startingIndex: currentIndex)
                .onTapGesture {
                    print("tap")
                }
            }
            .background(BackgroundCleanerView())
            .ignoresSafeArea(.all)
        }
        .transaction({ transaction in
            if (!isPresented) {
                transaction.disablesAnimations = true
            }
        })
        .ignoresSafeArea(.all)
    }
}
```
