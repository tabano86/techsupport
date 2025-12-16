# Google Account Confusion - Fix Guide

This guide helps untangle the mess when someone has multiple Google accounts and doesn't know which is which.

## Quick Diagnosis

Run this on their computer:
```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/google-audit.ps1 | iex
```

This will show:
- All Chrome profiles and which Google accounts are signed in
- Google Drive sync status
- Potential issues

## Common Scenarios

### Scenario 1: "I can't find my files"

**Symptoms:**
- Files uploaded on phone don't appear on computer
- Files saved "to Google Drive" are nowhere to be found
- Different files show up on different devices

**Cause:** Signed into different Google accounts on different devices.

**Fix:**
1. Run `google-audit.ps1` to see which accounts are on the computer
2. On their phone: Settings > Google > see which account is signed in
3. Make sure the SAME account is used everywhere
4. If needed, share files between accounts (see below)

### Scenario 2: "Chrome keeps signing me into the wrong account"

**Symptoms:**
- Open Gmail, wrong inbox appears
- YouTube recommendations are weird
- Bookmarks don't sync

**Cause:** Multiple Chrome profiles, or signed into multiple accounts in one profile.

**Fix:**
1. Click the profile icon (top right of Chrome)
2. Click "Manage profiles"
3. Create a dedicated profile for each account:
   - "Personal" profile → personal@gmail.com
   - "Work" profile → work@company.com
4. Use the correct profile for each task

### Scenario 3: "Google Drive is using too much space / syncing wrong things"

**Symptoms:**
- Computer is slow or out of disk space
- Files they don't recognize are syncing
- Multiple "Google Drive" folders

**Cause:** Multiple accounts syncing, or old Backup & Sync still installed.

**Fix:**
1. Check what's installed:
   - Google Drive for Desktop (new, good)
   - Backup and Sync (old, should uninstall)
2. Open Google Drive settings (click tray icon)
3. Check "Account" tab - which email is syncing?
4. Check "Folders from Drive" - what's syncing?
5. Remove duplicate sync folders

### Scenario 4: "I forgot which email I used"

**Symptoms:**
- Can't log into a service
- Password reset emails go to unknown inbox
- Created account years ago, don't remember

**Fix:**
1. Check Chrome saved passwords: `chrome://settings/passwords`
2. Search for the service name
3. The email used will be shown
4. Or try Google's account recovery: https://accounts.google.com/signin/recovery

### Scenario 5: "Someone else's account is on my computer"

**Symptoms:**
- See someone else's bookmarks/history
- Their Google account suggestions appear
- Shared computer situation

**Fix:**
1. Create separate Windows user accounts (best)
2. Or create separate Chrome profiles
3. Sign out of their accounts completely:
   - Go to: https://myaccount.google.com/device-activity
   - Sign out from all devices if needed

## Step-by-Step: Clean Google Setup

### Step 1: Figure out what accounts exist

1. Go to: https://myaccount.google.com
2. Note which account you're logged into
3. Click profile picture > "Add another account"
4. Try common email variations:
   - firstname@gmail.com
   - firstnamelastname@gmail.com
   - Old email addresses

### Step 2: Decide on ONE primary account

Pick the account that:
- Has the most important files
- Is used for the most services
- They can actually remember the password for

### Step 3: Consolidate files

If files are scattered across accounts:

**Option A: Share with yourself**
1. In old account's Drive, select all files
2. Right-click > Share
3. Share with new primary account
4. In primary account, move shared files to "My Drive"

**Option B: Download and re-upload**
1. Download everything from old account
2. Upload to new primary account
3. (Time-consuming but clean)

### Step 4: Set up computer correctly

1. **Remove old Google Drive apps:**
   - Uninstall "Backup and Sync from Google" if present
   - Keep only "Google Drive for Desktop"

2. **Sign into correct account:**
   - Open Google Drive app
   - Sign into PRIMARY account only
   - Configure what to sync

3. **Set up Chrome properly:**
   - Create one profile for primary account
   - Make it the default profile
   - Sign in and turn on sync

### Step 5: Update other devices

1. **Phone:**
   - Settings > Accounts > Google
   - Make sure primary account is there
   - Remove old/unused accounts if appropriate

2. **Tablet:** Same as phone

3. **Other computers:** Repeat Step 4

## Quick Links

| What | Link |
|------|------|
| Google Account Settings | https://myaccount.google.com |
| See signed-in devices | https://myaccount.google.com/device-activity |
| Security checkup | https://myaccount.google.com/security-checkup |
| Check storage usage | https://drive.google.com/settings/storage |
| Download all your data | https://takeout.google.com |
| Password manager | https://passwords.google.com |
| Find your accounts | https://accounts.google.com/signin/recovery |

## Common Mistakes to Avoid

1. **Don't delete the wrong account** - Always verify which account has important data before removing anything

2. **Don't sign out everywhere at once** - You might lose access if you forget the password

3. **Don't use "Sign in with Google" carelessly** - This creates ties between services and that Google account

4. **Don't ignore 2FA** - Write down backup codes for the primary account

## Prevention Tips

For the future:

1. **Use a password manager** (Bitwarden is free and good)
2. **Write down which email is for what** (store in password manager)
3. **Enable 2FA on important accounts**
4. **Use ONE Google account for personal stuff**
5. **Keep work and personal separate** (different Chrome profiles)
