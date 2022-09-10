import SwiftUI
import UIKit
import SVEVideoUI
import SDWebImageSwiftUI

public struct SwipingMediaView: UIViewControllerRepresentable {
    public typealias UIViewControllerType = UIPageViewController
    @Binding var currentIndex: Int
    var controllers: [UIViewController] = []
    var startingIndex: Int = 0
    
    public init(controllers: [AnyView] = [],
                currentIndex: Binding<Int>,
                startingIndex: Int = 0) {
        self.controllers = controllers.map {UIHostingController(rootView: $0)}
        self._currentIndex = currentIndex
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
        
        public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
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
        
        public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
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
        
        public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed else { return }
            if let viewControllerIndex = parent.controllers.firstIndex(of: pageViewController.viewControllers!.first!) {
                parent.currentIndex = viewControllerIndex
                print(viewControllerIndex)
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

public enum SwipingMediaItemFormatType {
    case video, image
}

public struct SwipingMediaItem {
    public init(
        id: String = "",
        url: String,
        type: SwipingMediaItemFormatType,
        title: String = "",
        description: String = "") {
            self.id = id
            self.url = url
            self.type = type
            self.title = title
            self.description = description
        }
    
    let id: String
    let url: String
    let type: SwipingMediaItemFormatType
    let title: String
    let description: String
}

public struct SwipingMediaItemView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var yOffset: CGFloat = 0
    @State var isPlaying: Bool = false
    @State var isPresented: Bool = true
    var mediaItem: SwipingMediaItem
    
    public init(mediaItem: SwipingMediaItem) {
        self.mediaItem = mediaItem
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity((1 - yOffset) * 1.2)
            DraggableView(yOffset: $yOffset,
                          isPresented: $isPresented) {
                
                if mediaItem.type == .image {
                    ZoomableScrollView {
                        AnimatedImage(url: URL(string: mediaItem.url))
                            .resizable()
                            .indicator(SDWebImageProgressIndicator.default) // UIKit indicator component
                            .scaledToFit()
                    }
                } else {
                    Video(url: URL(string: mediaItem.url)!)
                        .isPlaying($isPlaying)
                        .loop(true)
                        .playbackControls(true)
                        .onAppear() {
                            isPlaying = true
                        }
                        .onDisappear() {
                            isPlaying = false
                        }
                }
            }
        }
        .onChange(of: isPresented) { newValue in
            if (isPresented == false) {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .ignoresSafeArea(.all)
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
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.didDrag(gesture:)))
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
                if (hostingController.view.center.y > self.hostingController.view.frame.height * 0.8 ) {
                    UIView.animate(withDuration: 0.2, delay: 0, options: [] , animations: { [self] in
                        hostingController.view.center = CGPoint(x: hostingController.view.center.x,
                                                                y: self.hostingController.view.frame.height * 2)
                        parent.yOffset = 1
                    }) { (completed) in
                        self.parent.isPresented = false
                    }
                } else {
                    UIView.animate(withDuration: 0.1, delay: 0, options: [] , animations: { [self] in
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



