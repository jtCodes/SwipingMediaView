import SwiftUI
import UIKit
import SVEVideoUI
import SDWebImageSwiftUI
import Kingfisher

public struct SwipingMediaView: UIViewControllerRepresentable {
    public typealias UIViewControllerType = UIPageViewController
    @Binding var currentIndex: Int
    var controllers: [UIViewController] = []
    var startingIndex: Int = 0
    
    public init(controllers: [AnyView] = [],
                currentIndex: Binding<Int>,
                startingIndex: Int = 0) {
        self._currentIndex = currentIndex
        self.controllers = controllers.map {UIHostingController(rootView: $0)}
        self.startingIndex = startingIndex
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    public class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let parent: SwipingMediaView
        
        public init(_ parent: SwipingMediaView) {
            self.parent = parent
        }
        
        public func pageViewController(_ pageViewController: UIPageViewController, 
                                       viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = self.parent.controllers.firstIndex(of: viewController) else { return nil }
            if index == 0 {
                let vc = self.parent.controllers.last
                vc?.view.frame = UIScreen.main.bounds
                vc?.view.backgroundColor = .clear
                return vc
            }
            
            let vc = self.parent.controllers[index - 1]
            vc.view.frame = UIScreen.main.bounds
            vc.view.backgroundColor = .clear
            return vc
        }
        
        public func pageViewController(_ pageViewController: UIPageViewController,
                                       viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = self.parent.controllers.firstIndex(of: viewController) else { return nil }
            if index == self.parent.controllers.count - 1 {
                let vc = self.parent.controllers.first
                vc?.view.frame = UIScreen.main.bounds
                vc?.view.backgroundColor = .clear
                return vc
            }
            
            let vc = self.parent.controllers[index + 1]
            vc.view.frame = UIScreen.main.bounds
            vc.view.backgroundColor = .clear
            return vc
        }
        
        public func pageViewController(_ pageViewController: UIPageViewController, 
                                       didFinishAnimating finished: Bool,
                                       previousViewControllers: [UIViewController],
                                       transitionCompleted completed: Bool) {
            guard completed else { return }
            if let viewControllerIndex = parent.controllers.firstIndex(of: pageViewController.viewControllers!.first!) {
                parent.currentIndex = viewControllerIndex
            }
        }
    }
    
    public func makeUIViewController(context: Context) -> UIPageViewController {
        // setup the pageviewcontroller
        let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageViewController.providesPresentationContextTransitionStyle = true
        pageViewController.definesPresentationContext = true
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        pageViewController.view.frame = UIScreen.main.bounds
        pageViewController.view.backgroundColor = .clear
        
        // add the initial pageview item
        let vc = controllers[startingIndex]
        vc.view.frame = UIScreen.main.bounds
        vc.view.backgroundColor = .clear
        pageViewController.setViewControllers([vc], direction: .forward, animated: true)
        
        return pageViewController
    }
    
    public func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        
    }
}

class SwipingMediaViewSettings: ObservableObject {
    static let shared: SwipingMediaViewSettings = SwipingMediaViewSettings()
    @Published var isControlsVisible: Bool = false
    var shouldShowDownloadButton: Bool = false
}

public enum SwipingMediaItemFormatType {
    case video, image, gif
}

public struct SwipingMediaItem {
    public init(
        id: String = "",
        url: String,
        type: SwipingMediaItemFormatType,
        placeHolder: String = "",
        title: String = "",
        description: String = "") {
            self.id = id
            self.url = url
            self.placeHolder = placeHolder
            self.type = type
            self.title = title
            self.description = description
        }
    
    let id: String
    let url: String
    let placeHolder: String
    let type: SwipingMediaItemFormatType
    let title: String
    let description: String
}

public struct SwipingMediaItemView: View {
    @ObservedObject var swipingMediaViewSettings: SwipingMediaViewSettings = SwipingMediaViewSettings.shared
    
    @State var yOffset: CGFloat = 0
    @State var isPlaying: Bool = true
    @State var isLoadingError: Bool = false
    @Binding var isPresented: Bool
    var mediaItem: SwipingMediaItem
    
    public init(mediaItem: SwipingMediaItem,
                isPresented: Binding<Bool>,
                shouldShowDownloadButton: Bool = false ) {
        self.mediaItem = mediaItem
        self._isPresented = isPresented
        swipingMediaViewSettings.shouldShowDownloadButton = shouldShowDownloadButton
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity((1 - yOffset) * 1.3)
                .ignoresSafeArea(.all)
            DraggableView(yOffset: $yOffset,
                          isPresented: $isPresented) {
                
                if mediaItem.type == .image {
                    ZoomableScrollView {
                        KFImage(URL(string: mediaItem.url))
                            .cancelOnDisappear(true)
                            .placeholder {
                                VStack {
                                    if (isLoadingError) {
                                        Text("Error loading image")
                                            .font(.title)
                                    } else {
                                        Image(systemName: "arrow.2.circlepath.circle")
                                            .font(.largeTitle)
                                            .opacity(0.3)
                                        Text("Loading...")
                                            .font(.title)
                                    }
                                }
                            }
                            .onFailure { e in
                                isLoadingError = true
                                print("Error \(e)")
                            }
                            .resizable()
                            .scaledToFit()
                    }
                } else if mediaItem.type == .gif {
                    AnimatedImage(url: URL(string: mediaItem.url))
                        .placeholder() {
                            VStack {
                                if (isLoadingError) {
                                    Text("Error loading image")
                                        .font(.title)
                                } else {
                                    Image(systemName: "arrow.2.circlepath.circle")
                                        .font(.largeTitle)
                                        .opacity(0.3)
                                    Text("Loading...")
                                        .font(.title)
                                }
                            }
                        }
                        .onFailure() {_ in
                            isLoadingError = true
                        }
                        .resizable()
                        .scaledToFit()
                } else {
                    Video(url: URL(string: mediaItem.url)!)
                        .isPlaying($isPlaying)
                        .loop(.constant(true))
                        .playbackControls(true)
                        .isMuted(false)
                }
            }
            
            if (swipingMediaViewSettings.isControlsVisible == true) {
                SwipingMediaItemViewControlsView(mediaItem: mediaItem,
                                                 isPresented: $isPresented)
                .opacity((1 - yOffset) * 1.2)
            }
        }
        .onChange(of: isPresented) { newValue in
            if (isPresented == false) {
                swipingMediaViewSettings.isControlsVisible = false
            }
        }
        .onDidAppear {
            if (mediaItem.type == .video) {
                swipingMediaViewSettings.isControlsVisible = false
                isPlaying = true
            }
            print("item did apear", mediaItem.type)
        }
        .onWillDisappear{
            if (mediaItem.type == .video) {
                isPlaying = false
            }
            print("item willdisapear", mediaItem.type)
        }
        .if(mediaItem.type != .video) { view in
            view.ignoresSafeArea(.all)
        }
        .if(mediaItem.type != .video) { view in
            view.simultaneousGesture(
                TapGesture().onEnded {
                    withAnimation(.spring()) { swipingMediaViewSettings.isControlsVisible.toggle() }
                }
            )
        }
    }
}

public struct SwipingMediaItemViewControlsView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    var swipingMediaViewSettings: SwipingMediaViewSettings = SwipingMediaViewSettings.shared
    var mediaItem: SwipingMediaItem
    @Binding var isPresented: Bool
    
    public init(mediaItem: SwipingMediaItem,
                isPresented: Binding<Bool>) {
        self.mediaItem = mediaItem
        self._isPresented = isPresented
    }
    
    public var body: some View {
        VStack() {
            HStack(alignment: .center) {
                HStack(alignment: .center) {
                    Button {
                        swipingMediaViewSettings.isControlsVisible = false
                        isPresented = false
                    } label: {
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(Color.gray)
                            .font(.system(size: 24))
                            .padding(5)
                    }
                    .frame(width: 25, height: 25, alignment: .center)
                    Spacer()
                    Text(mediaItem.title)
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    Spacer()
                    if (swipingMediaViewSettings.shouldShowDownloadButton == true && mediaItem.type != .video) {
                        Button {
                            SDWebImageManager.shared.loadImage(
                                with: URL(string: mediaItem.url),
                                options: .continueInBackground, // or .highPriority
                                progress: nil,
                                completed: {(image, data, error, cacheType, finished, url) in
                                    
                                    if let err = error {
                                        // Do something with the error
                                        print(err)
                                        return
                                    }
                                    
                                    guard let img = image else {
                                        
                                        // No image handle this error
                                        return
                                    }
                                    
                                    // Do something with image
                                    let imageSaver = ImageSaver()
                                    imageSaver.writeToPhotoAlbum(image: img)
                                    imageSaver.successHandler = {
                                        
                                    }
                                }
                            )
                        } label: {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .foregroundColor(Color.gray)
                                .font(.system(size: 18))
                                .padding(5)
                        }
                    }
                }
                .padding(.leading, 15)
                .padding(.trailing, 15)
                .padding(.top, safeAreaInsets.top)
                .padding(.bottom, 15)
            }
            .frame(maxWidth: .infinity)
            .background(BackgroundBlurView(blurStyle: .systemUltraThinMaterialDark))
            Spacer()
        }
    }
}

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        // set up the UIScrollView
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator  // for viewForZooming(in:)
        scrollView.maximumZoomScale = 20
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.contentInsetAdjustmentBehavior = .never
        
        // create a UIHostingController to hold our SwiftUI content
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)
        
        return scrollView
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: self.content,
                                                                  ignoreSafeArea: true))
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // update the hosting controller's SwiftUI content
        context.coordinator.hostingController.view.backgroundColor = .clear
        context.coordinator.hostingController.rootView = self.content
        assert(context.coordinator.hostingController.view.superview == uiView)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        
        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
    }
}

struct DraggableView<Content: View>: UIViewRepresentable {
    @Binding var isPresented: Bool
    @Binding var yOffset: CGFloat
    private var content: Content
    let uiView = UIView()
    
    init(yOffset: Binding<CGFloat>,
         isPresented: Binding<Bool>,
         @ViewBuilder content: () -> Content) {
        self._yOffset = yOffset
        self._isPresented = isPresented
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIView {
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, 
                                                action: #selector(context.coordinator.didDrag(gesture:)))
        panGesture.delegate = context.coordinator
        
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = uiView.bounds
        uiView.addGestureRecognizer(panGesture)
        uiView.addSubview(hostedView)
        
        return uiView
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self,
                           hostingController: UIHostingController(rootView: self.content,
                                                                  ignoreSafeArea: true))
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // update the hosting controller's SwiftUI content
        context.coordinator.hostingController.view.backgroundColor = .clear
        context.coordinator.hostingController.rootView = self.content
        assert(context.coordinator.hostingController.view.superview == uiView)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private var initialCenter: CGPoint = .zero
        var parent: DraggableView
        var hostingController: UIHostingController<Content>
        
        init(parent: DraggableView,
             hostingController: UIHostingController<Content>) {
            self.parent = parent
            self.hostingController = hostingController
        }
        
        @objc func didDrag(gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: hostingController.view)
            
            if gesture.state == .began {
                initialCenter = hostingController.view.center
            }
            
            if gesture.state == .changed {
                hostingController.view.center = CGPoint(x: hostingController.view.center.x,
                                                        y: hostingController.view.center.y + translation.y)
                gesture.setTranslation(CGPoint.zero,
                                       in: self.hostingController.view)
                parent.yOffset = (hostingController.view.center.y - initialCenter.y / 2) / hostingController.view.frame.height
            }
            
            if gesture.state == .ended {
                if (hostingController.view.center.y > self.hostingController.view.frame.height * 0.6 ) {
                    UIView.animate(withDuration: 0.2,
                                   delay: 0,
                                   usingSpringWithDamping: 0.75,
                                   initialSpringVelocity: 3,
                                   options: .curveEaseInOut,
                                   animations: { [self] in
                        hostingController.view.center = CGPoint(x: hostingController.view.center.x,
                                                                y: self.hostingController.view.frame.height * 2)
                        parent.yOffset = 1
                    }) { (completed) in
                        self.parent.isPresented = false
                    }
                } else {
                    UIView.animate(withDuration: 0.2,
                                   delay: 0,
                                   usingSpringWithDamping: 0.75,
                                   initialSpringVelocity: 3,
                                   options: .curveEaseInOut,
                                   animations: { [self] in
                        hostingController.view.center = CGPoint(x: hostingController.view.center.x,
                                                                y: self.hostingController.view.frame.height / 2)
                        parent.yOffset = 0
                    }) { (completed) in  }
                }
            }
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
                let translation = panGesture.translation(in: hostingController.view)
                return translation.x == 0
            }
            else {
                return false
            }
        }
    }
}

extension UIHostingController {
    convenience public init(rootView: Content, ignoreSafeArea: Bool) {
        self.init(rootView: rootView)
        
        if ignoreSafeArea {
            disableSafeArea()
        }
    }
    
    func disableSafeArea() {
        guard let viewClass = object_getClass(view) else { return }
        
        let viewSubclassName = String(cString: class_getName(viewClass)).appending("_IgnoreSafeArea")
        if let viewSubclass = NSClassFromString(viewSubclassName) {
            object_setClass(view, viewSubclass)
        }
        else {
            guard let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String else { return }
            guard let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0) else { return }
            
            if let method = class_getInstanceMethod(UIView.self, #selector(getter: UIView.safeAreaInsets)) {
                let safeAreaInsets: @convention(block) (AnyObject) -> UIEdgeInsets = { _ in
                    return .zero
                }
                class_addMethod(viewSubclass, #selector(getter: UIView.safeAreaInsets), imp_implementationWithBlock(safeAreaInsets), method_getTypeEncoding(method))
            }
            
            objc_registerClassPair(viewSubclass)
            object_setClass(view, viewSubclass)
        }
    }
}

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        (UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero).insets
    }
}

extension EnvironmentValues {
    
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

private extension UIEdgeInsets {
    
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

public struct BackgroundCleanerView: UIViewRepresentable {
    public init() {}
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {}
}

struct BackgroundBlurView: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        view.autoresizingMask = [.flexibleHeight]
        //        DispatchQueue.main.async {
        //            view.superview?.superview?.backgroundColor = .clear
        //        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class ImageSaver: NSObject {
    var successHandler: (() -> Void)?
    var errorHandler: ((Error) -> Void)?
    
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            errorHandler?(error)
        } else {
            successHandler?()
        }
    }
}

func verifyUrl (urlString: String?) -> Bool {
    if let urlString = urlString {
        if let url = NSURL(string: urlString) {
            return UIApplication.shared.canOpenURL(url as URL)
        }
    }
    return false
}

struct WillDisappearHandler: UIViewControllerRepresentable {
    func makeCoordinator() -> WillDisappearHandler.Coordinator {
        Coordinator(onWillDisappear: onWillDisappear)
    }

    let onWillDisappear: () -> Void

    func makeUIViewController(context: UIViewControllerRepresentableContext<WillDisappearHandler>) -> UIViewController {
        context.coordinator
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<WillDisappearHandler>) {
    }

    typealias UIViewControllerType = UIViewController

    class Coordinator: UIViewController {
        let onWillDisappear: () -> Void

        init(onWillDisappear: @escaping () -> Void) {
            self.onWillDisappear = onWillDisappear
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            onWillDisappear()
        }
    }
}

struct WillDisappearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content
            .background(WillDisappearHandler(onWillDisappear: callback))
    }
}

struct DidAppearHandler: UIViewControllerRepresentable {
    func makeCoordinator() -> DidAppearHandler.Coordinator {
        Coordinator(onDidAppear: onDidAppear)
    }

    let onDidAppear: () -> Void

    func makeUIViewController(context: UIViewControllerRepresentableContext<DidAppearHandler>) -> UIViewController {
        context.coordinator
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<DidAppearHandler>) {
    }

    typealias UIViewControllerType = UIViewController

    class Coordinator: UIViewController {
        let onDidAppear: () -> Void

        init(onDidAppear: @escaping () -> Void) {
            self.onDidAppear = onDidAppear
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onDidAppear()
        }
    }
}

struct DidAppearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content
            .background(DidAppearHandler(onDidAppear: callback))
    }
}

extension View {
    func onWillDisappear(_ perform: @escaping () -> Void) -> some View {
        self.modifier(WillDisappearModifier(callback: perform))
    }
    
    func onDidAppear(_ perform: @escaping () -> Void) -> some View {
        self.modifier(DidAppearModifier(callback: perform))
    }
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
