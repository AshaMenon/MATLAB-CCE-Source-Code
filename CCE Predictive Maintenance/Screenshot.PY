import time
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
from playwright.sync_api import sync_playwright

# ================= CONFIGURATION =================
# 1. PI Vision Details
# URL of the display you want to capture
VISION_URL = "https://cencs.angloiit.net/PIVision/#/Displays/63069/Compressor-8-Motor"
SCREENSHOT_FILE = "vision_report.png"

# 2. PI Vision Login Credentials (to bypass 401 Error)
# IMPORTANT: Update this with your NEW password!
VISION_USER = r"angloiit\asam_iit" 
VISION_PASS = "LegacyOfKrishna_2023" 

# 3. Email Settings (Internal Relay Configuration)
RECIPIENT = "asa.aravindakshamenon@valterraplatinum.com"
SENDER = "rpma-pins@valterraplatinum.com"
SMTP_SERVER = "smtp.angloiit.net"
SMTP_PORT = 25  # Internal relays usually use Port 25
# =================================================

def capture_pi_vision():
    print(f"Starting browser to capture: {VISION_URL}")
    with sync_playwright() as p:
        # Launch browser in background (headless)
        browser = p.chromium.launch(headless=True)
        
        # http_credentials handles the automatic Windows/PI Vision login prompt
        context = browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            http_credentials={
                "username": VISION_USER,
                "password": VISION_PASS
            }
        )
        
        page = context.new_page()
        
        try:
            print("Navigating to PI Vision...")
            page.goto(VISION_URL, wait_until="networkidle")
            
            # PI Vision takes time to fetch live data once the page is open
            print("Waiting 25 seconds for data trends to load...")
            time.sleep(25) 
            
            # Take the screenshot
            page.screenshot(path=SCREENSHOT_FILE, full_page=True)
            print(f"Screenshot successfully saved as {SCREENSHOT_FILE}")
            
        except Exception as e:
            print(f"Error during browser capture: {e}")
        finally:
            browser.close()

def send_email_with_image():
    print(f"Constructing email for {RECIPIENT}...")
    
    # Create the root message
    msg = MIMEMultipart('related')
    msg['Subject'] = "Daily Summary: Compressor 8 Motor Status"
    msg['From'] = SENDER
    msg['To'] = RECIPIENT

    # HTML Body with embedded image using 'cid' (Content ID)
    html = """
    <html>
      <body style="font-family: Arial, sans-serif;">
        <h2 style="color: #00447c;">Compressor-8-Motor Status Report</h2>
        <p>Attached is the current PI Vision dashboard for the Compressor 8 Motor.</p>
        <div style="border: 2px solid #444; display: inline-block;">
            <img src="cid:image1">
        </div>
        <br>
        <p style="color: gray; font-size: 11px;">This is an automated report generated from the PI System.</p>
      </body>
    </html>
    """
    msg.attach(MIMEText(html, 'html'))

    # Open the image file and attach it to the email
    try:
        with open(SCREENSHOT_FILE, 'rb') as f:
            img_data = f.read()
            msg_image = MIMEImage(img_data)
            # This ID must match the 'src="cid:image1"' in the HTML above
            msg_image.add_header('Content-ID', '<image1>')
            msg_image.add_header('Content-Disposition', 'inline', filename=SCREENSHOT_FILE)
            msg.attach(msg_image)
    except FileNotFoundError:
        print("Screenshot file not found. Email will not be sent.")
        return

    # Send the email via the Internal SMTP Relay
    try:
        print(f"Connecting to Internal SMTP Relay: {SMTP_SERVER}...")
        # Internal relays usually don't need login or STARTTLS
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.send_message(msg)
            print("Email sent successfully!")
    except Exception as e:
        print(f"Failed to send email: {e}")
        print("\nNote: If 'Relay Access Denied', ask IT to whitelist your IP on the SMTP relay.")

if __name__ == "__main__":
    # Step 1: Open Vision, Login, and Capture Screenshot
    capture_pi_vision()
    
    # Step 2: Build the HTML email and send via Internal Relay
    send_email_with_image()