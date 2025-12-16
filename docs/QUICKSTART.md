# Quick Start - Send This To Family

Copy and paste the message below to whoever you're helping:

---

## Message to send:

> Hey! I'm going to help fix your computer remotely. Here's what I need you to do:
>
> **Step 1: Download the setup script**
> 1. Open this link: [REPLACE WITH YOUR RAW GITHUB LINK]
> 2. Right-click anywhere on the page and click "Save as..."
> 3. Save it to your Desktop
>
> **Step 2: Run the script**
> 1. Right-click on the file you downloaded
> 2. Click "Run with PowerShell"
> 3. If Windows asks "Do you want to allow this app to make changes?" click **Yes**
> 4. Wait for it to finish (about 1 minute)
>
> **Step 3: Send me the info**
> The script will show you a window with an **ID** and **Password**.
> Send me both of those numbers.
>
> That's it! I'll handle everything else. When I connect, you'll see a popup asking to allow control - just click Accept.

---

## Alternative: One-liner they can paste

If they're comfortable with PowerShell, have them run this in an **Administrator** PowerShell:

```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/bootstrap.ps1 | iex
```

Replace `YOUR_USERNAME` with your GitHub username.

---

## After they send you the RustDesk ID/password:

1. Open RustDesk on your machine
2. Enter their ID and password
3. Once connected, download and run `setup.ps1`:

```powershell
# In an Admin PowerShell on THEIR machine (via RustDesk)
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/setup.ps1 -OutFile setup.ps1
.\setup.ps1 -Interactive
```

4. Follow the prompts to enter your Tailscale auth key
5. Save the password it generates
6. Done! You can now SSH directly without RustDesk
