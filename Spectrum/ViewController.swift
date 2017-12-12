import UIKit


class ViewController: UIViewController, FrameExtractorDelegate {
    
    var frameExtractor: FrameExtractor!
    
    // this is the layer that changes color depending on what the user clicked
    var colorDisplayBGLayer: UIView!
    
    // holds the colors from the txt file
    var colorsHex = [String]()
    var colorsHex_basic = [String]()
    var colorsHex_xkcd = [String]()
    
    // where the user clicked
    var pos_x = CGFloat(0)
    var pos_y = CGFloat(0)
    
    // this is dumb ...
    var firstTime = true
    
    // determine if the user has selected to freeze the screen
    var freezeFrame = false
    
    // get the color of where the user pressed and store it here
    var getColor: UIColor!
    
    @IBOutlet weak var freezeButton: UIButton!
    @IBOutlet var flipCameraButton: UIButton!
    
    // the circle that is created when the screen is pressed
    @IBOutlet var screenPressedDisplay: UIImageView!
    
    @IBOutlet var colorNameLabel: UILabel!
    @IBOutlet var colorHexLabel: UILabel!
    
    @IBOutlet var colorDisplay: UIImageView!
    
    // contains the frame
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        
        initalizeScreen()
        
        colorsHex = colorsHex_xkcd
        
    }
    
    func initalizeScreen() {
        initColorDisplay()
        initColorNameSet()
        initScreenPressedDisplay()
        initButtons()
    }
    
    func initColorDisplay() {
        // initialize by inserting the grey circle for where colors will be placed
        let circle = UIView(frame: CGRect(x: 0.0, y: 0.0, width: colorDisplay.frame.width, height: colorDisplay.frame.height))
        
        circle.layer.cornerRadius = colorDisplay.frame.width/2
        circle.layer.borderWidth = 8;
        circle.layer.borderColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8).cgColor
        
        colorDisplay.addSubview(circle)
        
        // also add the layer for the color that will be displayed
        colorDisplayBGLayer = UIView(frame: CGRect(x: 8.0, y: 8.0, width: colorDisplay.frame.width-16, height: colorDisplay.frame.height-16))
        colorDisplay.addSubview(colorDisplayBGLayer)
    }
    
    func initButtons() {
        freezeButton.addSubview(createCircle(obj: freezeButton))
        flipCameraButton.addSubview(createCircle(obj: flipCameraButton))
    }
    
    func setColorDisplay(rgba: UIColor) {
        
        colorDisplayBGLayer.layer.cornerRadius = (colorDisplay.frame.width-16)/2
        colorDisplayBGLayer.layer.backgroundColor = rgba.withAlphaComponent(CGFloat(0.8)).cgColor
    }
    
    // get colors from text file
    func initColorNameSet() {
        
        if let path = Bundle.main.path(forResource: "rgb", ofType: "txt") {
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                colorsHex_xkcd = data.components(separatedBy: .newlines)
                
                // for all colors, split the hex and string
                for col in colorsHex_xkcd {
                    let colorHexSplit = col.components(separatedBy: "\t")
                    if (colorHexSplit.count > 1) {
                        // remove the element that is being looked at
                        let index = colorsHex_xkcd.index(of: col)
                        colorsHex_xkcd.remove(at: index!)
                        
                        // replace it with 2 arrays - the color string and hex
                        colorsHex_xkcd.insert(colorHexSplit[0], at: index!)
                        colorsHex_xkcd.insert(colorHexSplit[1], at: index!+1)
                    }
                }
                
                // remove unneeded values from txt file
                colorsHex_xkcd.removeFirst()
                colorsHex_xkcd.removeLast()
                
            } catch {
                print(error)
            }
        }
    }
    
    // initialize the large circle on the screen
    func initScreenPressedDisplay() {
        let innerCircle = UIView(frame: CGRect(x: 0.0, y: 0.0, width: screenPressedDisplay.frame.width, height: screenPressedDisplay.frame.height))
        
        innerCircle.layer.cornerRadius = screenPressedDisplay.frame.width/2
        innerCircle.layer.borderWidth = 2;
        innerCircle.layer.borderColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8).cgColor
        
        screenPressedDisplay.addSubview(innerCircle)
        
        let outerCircle = UIView(frame: CGRect(x: 5.0, y: 5.0, width: screenPressedDisplay.frame.width/2, height: screenPressedDisplay.frame.height/2))
        
        outerCircle.layer.cornerRadius = screenPressedDisplay.frame.width/2/2
        outerCircle.layer.borderWidth = 1;
        outerCircle.layer.borderColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8).cgColor
        
        screenPressedDisplay.addSubview(outerCircle)
        
        
    }
    
    func createCircle(obj: AnyObject) -> UIView {
        let circle = UIView(frame: CGRect(x: 0.0, y: 0.0, width: obj.frame.width, height: obj.frame.height))
        
        circle.layer.cornerRadius = obj.frame.width/2
        circle.layer.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3).cgColor
        circle.isUserInteractionEnabled = false
        circle.tag = 100
        
        return circle
    }
    
    func captured(image: UIImage) {
        if (!freezeFrame) {
            imageView.image = image
        }
    }
    
    func hexToNum(hexString: NSString) -> Array<Int>{
        
        let hexString:NSString = hexString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) as NSString
        let scanner = Scanner(string: hexString as String)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        return [r,g,b]
    }
    
    // get the color from the loaded txt file that closely resembles that which is selected on screen
    func closestColor(rgba: UIColor) -> (iClosestHex:String, iClosestHex_name:String)? {
        
        var closestHex = "";
        var closestHex_val = 999;
        var closestHex_name = "";
        
        // get r,g,b from UIColor
        let r = rgba.rgb()?.red
        let g = rgba.rgb()?.green
        let b = rgba.rgb()?.blue
        
        var f = 1
        // go through the hex list to find the closest color
        for var i in 0 ..< (colorsHex.count/2) {
            
            let h_rgb = hexToNum(hexString: colorsHex[f] as NSString)
            let h_r = h_rgb[0]
            let h_g = h_rgb[1]
            let h_b = h_rgb[2]
            
            // get the absolute difference
            let dif = Swift.abs(h_r - r!) + Swift.abs(h_g - g!) + Swift.abs(h_b - b!);
            // set the closest color of the current color if it has the smallest difference
            if (dif < closestHex_val) {
                closestHex_val = dif;
                closestHex = colorsHex[f];
                closestHex_name = colorsHex[f-1];
            }
            
            f += 2
        }
        return (iClosestHex:closestHex, iClosestHex_name:closestHex_name)
    }
    
    // when touching anywhere on the screen
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let theTouch = touches.first {
            
            // get the cartesian coordinates
            let endPoint = theTouch.location(in: self.view)
            pos_x = endPoint.x
            pos_y = endPoint.y
            
            // set the x and y coordinates of the circle that appears when user clicks on the screen
            screenPressedDisplay.frame.origin.x = pos_x - screenPressedDisplay.frame.width/2;
            screenPressedDisplay.frame.origin.y = pos_y - screenPressedDisplay.frame.height/2;
            
            // make sure it is no longer hidden - initially it is
            screenPressedDisplay.isHidden = false
            
            getColor = imageView.image?.getPixelColor(pos: CGPoint(x: pos_x, y: pos_y), imageView: imageView)
                        
            // set the color retrieved to the middle cirle and insert its name and hex below it
            setColorDisplay(rgba: getColor!)
            let cc = closestColor(rgba: getColor!)
            colorNameLabel.text = cc?.iClosestHex_name
            colorHexLabel.text = cc?.iClosestHex.uppercased()
            
            // not sure about this one - why can't I just insert this within viewDidLoad()? The world may never know
            if (firstTime) {
                freezeButton.exchangeSubview(at: 0, withSubviewAt: 1)
                flipCameraButton.exchangeSubview(at: 0, withSubviewAt: 1)
                firstTime = !firstTime
            }
            
            // change the background color of the buttons to match the color that the user selected
            changeButtonColor(button: freezeButton)
            changeButtonColor(button: flipCameraButton)
        }
    }
    
    // change the background color of the buttons to the the color that was selected
    func changeButtonColor(button: UIButton) {
        if let viewWithTag = button.viewWithTag(100) {
            viewWithTag.layer.backgroundColor = getColor.withAlphaComponent(CGFloat(0.7)).cgColor
        }
    }
    
    @IBAction func flipCamera(_ sender: Any) {
        frameExtractor.flipCamera()
    }
    
    // stops frame capture
    @IBAction func freezeFrame(_ sender: Any) {
        freezeFrame = !freezeFrame
    }
    
}

