# GS NullOut V1
**Free, Portable Linux Privacy Tool | Created by GhostStrats**

**One Script. One USB. Sixty Seconds.**

## About GS NullOut

GS NullOut V1 is a free, lightweight Bash script designed to provide an additional layer of privacy by automatically requesting a Linux system shutdown after **60 seconds of inactivity**.

I originally built this tool for myself while experimenting with privacy-focused, non-persistent Linux operating systems such as Tails.

My goal was simple: If I unexpectedly step away from my computer, I don't want to leave an active session running unattended.

GS NullOut acts as an inactivity-based shutdown failsafe, helping close that gap without requiring complicated software or installation.

Although primarily designed for bootable Linux operating systems, GS NullOut can also work on compatible regularly installed Linux systems.

## Features

- Free and lightweight
- Portable Bash (`.sh`) script
- Automatic shutdown request after 60 seconds of inactivity
- Timer resets when keyboard or mouse activity is detected
- Yellow terminal countdown
- Red warning during the final 15 seconds
- Optional audible warning
- No internet connection required
- No installation required on systems with supported idle-monitoring capabilities
- Runs directly from a secondary USB flash drive
- Safe testing mode available
- Compatible with multiple Linux desktop environments

## How to Use GS NullOut

### Step 1 — Prepare Your USB Drive

Download the `gsnull.sh` file and save it to a USB flash drive.

A secondary flash drive is recommended if you're running a non-persistent live Linux operating system.

Your flash drive can be organized like this:

```text
USB DRIVE/
├── gsnull.sh
└── README.txt
```

### Step 2 — Boot Into Linux

Boot your preferred Linux operating system.

GS NullOut is primarily intended for live Linux environments but may also work on regular Linux installations.

### Step 3 — Insert Your USB Drive

Insert the flash drive containing `gsnull.sh`.

Open the drive using your Linux file manager.

Right-click an empty area inside the folder and select **Open in Terminal**.

The wording may vary depending on your desktop environment.

### Step 4 — Launch GS NullOut

Enter the following command:

```bash
bash gsnull.sh
```

Press Enter.

GS NullOut will automatically attempt to detect an available inactivity-monitoring method and launch its countdown.

**That's it!**

No software installation, internet connection, or executable permission changes are required to run the script with Bash.

Leave the Terminal running. You may minimize it while continuing to use your computer.

### Step 5 — Stop GS NullOut

To stop the script, return to its Terminal window and press:

**Ctrl + C**

This stops the countdown and prevents the script from initiating its shutdown request.

## Safe Testing Mode

Before using GS NullOut normally, I strongly recommend testing it.

Run:

```bash
bash gsnull.sh --test
```

This activates a shortened 10-second countdown with shutdown disabled.

It allows you to verify that the inactivity monitor and countdown function correctly without powering off your computer.

Try moving your mouse or pressing a key to confirm that the timer resets.

## How GS NullOut Works

One of the most interesting things about GS NullOut is that it takes advantage of monitoring capabilities already available in many Linux environments.

Rather than installing a new monitoring application, the script uses existing desktop services to determine how long your computer has been inactive.

### GNOME IdleMonitor

GNOME is a popular Linux desktop environment.

GNOME includes an inactivity-monitoring service that can report how long the computer has gone without user input.

GS NullOut communicates with this service using **D-Bus**, an interprocess communication system that allows applications and system components to exchange information.

The script uses the existing `gdbus` command to request the idle time from GNOME.

### X11 and xprintidle

X11 is a graphical display system used by many Linux desktop environments.

Through the XScreenSaver extension, X11 can report how long the computer has been inactive.

A small utility called `xprintidle` can retrieve this information in milliseconds.

GS NullOut uses `xprintidle` if it's already available. On supported X11 environments, it can also use existing Python and X11 libraries to retrieve the idle time without downloading additional packages.

For example, if the operating system reports 10,000 milliseconds of inactivity, that equals 10 seconds.

GS NullOut uses that information to calculate the remaining time before shutdown.

### What Happens After 60 Seconds?

Once the system has been inactive for 60 seconds, GS NullOut requests a normal operating-system shutdown using an available Linux power-off command, typically:

```bash
systemctl poweroff
```

The operating system handles the actual shutdown.

Shutdown can still be blocked by system permissions, configuration, or other processes.

**GS NullOut does not record your keystrokes, capture passwords, or inspect what you're doing on your computer.**

It only requests existing inactivity information.

### Unsupported Desktop Environments

If GS NullOut cannot find a compatible inactivity monitor, it offers an optional manual fallback.

Manual mode only detects keystrokes entered into the script's own Terminal window. It does **not** detect mouse movement or activity in other applications.

For normal privacy protection, use the automatic system-wide monitoring mode. If your operating system cannot provide it, do not rely on manual mode as an unattended-session failsafe.

## Why Use a Secondary USB Flash Drive?

When using non-persistent live Linux operating systems, temporary session changes are generally discarded after shutdown.

This provides the convenience of starting with a fresh environment each time you boot.

However, it also means tools installed during a temporary session usually need to be installed again after rebooting.

Rather than downloading GS NullOut every time, I decided to keep it on a separate flash drive.

My setup uses two drives:

- **USB 1:** Bootable Linux operating system
- **USB 2:** GS NullOut and other portable tools

This makes GS NullOut easy to carry between compatible Linux computers.

Plug in the tools drive, open Terminal, and run one command.

## Privacy Benefits

GS NullOut was designed to help reduce the risk of leaving an active Linux session unattended.

When used with a properly configured non-persistent operating system, shutting down ends the temporary session, and the next boot starts fresh.

However, files deliberately saved to persistent storage, external drives, or other permanent locations will remain.

GS NullOut can also work on supported regular Linux installations, but a normal shutdown will **not delete saved files or erase the operating system**.

GS NullOut itself is not a secure wiping tool and does not guarantee removal of all information from memory or storage.

It is an automatic inactivity shutdown utility intended to complement the privacy features already provided by your operating system.

## Compatibility

The following live Linux operating systems have been tested during development:

| Operating System | Status |
|---|---|
| Kali Linux Live | Tested successfully |
| Parrot OS Live | Tested not working  |
| Linux Mint Live | Tested successfully |
| Tails Live | Tested successfully |
| Other Linux desktops | Depends on available idle-monitoring capabilities |

A compatibility fix was made to correctly interpret GNOME's inactivity-monitoring output. Compatibility may vary between different versions, desktop environments, and system configurations.

There is no guarantee that GS NullOut will work on every Linux distribution.

## Troubleshooting

**Countdown does not move:** Confirm you're using the latest version of `gsnull.sh`. Check that the desktop's inactivity monitor returns changing values.

**Script cannot find an inactivity monitor:** Your desktop may not provide a supported monitoring interface. GS NullOut may offer a manual fallback, but manual mode is not suitable for system-wide inactivity protection.

**Script will not start:** Ensure your Terminal is open in the folder containing `gsnull.sh` and that the filename is correct.

**Shutdown does not happen:** Your operating system may block the shutdown command because of permissions or system configuration.

**No warning sound:** Audio alerts depend on the availability and configuration of the system's sound services. The visual warning can still function.

## Disclaimer — Educational Purposes Only

**GS NullOut V1 is a personal privacy experiment created by GhostStrats and shared with the community for educational and experimental purposes only.**

I originally developed this tool for my own use and decided to make it freely available to others interested in Linux, privacy, and system automation.

This software is provided **AS IS**, without warranties or guarantees of functionality, compatibility, security, privacy, or successful shutdown.

**USE AT YOUR OWN RISK.**

GhostStrats is not responsible for lost or unsaved data, interrupted work, system interruptions, or any other consequences resulting from the use of this script, to the extent permitted by law.

Always save important files, maintain appropriate backups, and use the safe testing mode before enabling automatic shutdown.

GS NullOut is not a secure data-erasing utility, emergency detector, or guaranteed privacy solution.

Use this software only on systems you own or have authorization to manage.

## About the Creator

**Created by GhostStrats**

GS NullOut is part of my ongoing experimentation with cybersecurity, digital privacy, Linux, and portable technology.

The goal of this project is to demonstrate how simple scripts can take advantage of capabilities already built into an operating system to create useful tools.

Sometimes the best solutions aren't the most complicated ones.

**One Script. One USB. Sixty Seconds.**

**Privacy is an Illusion.**
