import SwiftUI
import SDWebImageSwiftUI
import SwipingMediaView

//struct ContentView: View {
//    @State var isPresented: Bool = false
//    @State var currentIndex: Int = 1
//    var images: [String] = []
//    var mediaItems: [SwipingMediaItem] = []
//
//    init() {
//        for i in 0..<64 {
//            images.append("https://picsum.photos/250?image=" + String(i))
//            mediaItems.append(SwipingMediaItem(url: "https://picsum.photos/250?image=" + String(i),
//                                                                                        type: .image,
//                                                                                        title: "Image " + String(i)))
//        }
//    }
//
//    var body: some View {
//        ZStack {
//            Color.green.opacity(0.5)
//            VStack() {
//                Text("Current index: " + String(currentIndex))
//                Spacer()
//            }.padding(100)
//
//            // Horizontal scrolled image view.
//            // This is responsible for bringing up the full screen SwipingMediaView.
//            ScrollViewReader { proxy in
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack {
//                        ForEach(0..<images.count) { index in
//                            WebImage(url: URL(string: images[index]))
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 300, height: 300, alignment: .center)
//                                .id(index)
//                                .onTapGesture {
//                                    currentIndex = index
//                                    isPresented = true
//                                }
//                        }
//                        // Scrolling the view to the image that's being shown on SwipingMediaView
//                        .onChange(of: currentIndex) { newIndex in
//                            proxy.scrollTo(newIndex, anchor: .top)
//                        }
//                    }
//                }
//            }
//        }
//        // FullScreenCover works well in presenting SwipingMediaView
//        .fullScreenCover(isPresented: $isPresented) {
//            ZStack{
//                SwipingMediaView(controllers: mediaItems.map {AnyView(SwipingMediaItemView(mediaItem: $0,
//                                                                                           isPresented: $isPresented,
//                                                                                           shouldShowDownloadButton: true
//                                                                                          ))},
//                                 currentIndex: $currentIndex,
//                                 startingIndex: currentIndex)
//            }
//            // Adding a clear background helper here to achieve on drag fading background effect
//            .background(BackgroundCleanerView())
//            // Ignoring safe area so pinch to zoom don't get cut off
//            .ignoresSafeArea(.all)
//        }
//        .ignoresSafeArea(.all)
//    }
//}

// example working with images, gifs and video at the same time
struct ContentView: View {
    @State var isPresented: Bool = false
    @State var currentIndex: Int = 1
    var mediaItems: [SwipingMediaItem] = []
    
    init() {
        self.mediaItems =  [SwipingMediaItem(url: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
                                             type: .video),
                            SwipingMediaItem(url: "https://i.redd.it/8t6vk567khm91.jpg",
                                             type: .image,
                                             shouldShowDownloadButton: true),
                            SwipingMediaItem(url: "https://i.redd.it/gczavw14bfm91.gif",
                                             type: .gif)]
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
                SwipingMediaView(mediaItems: mediaItems,
                                 isPresented: $isPresented,
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


