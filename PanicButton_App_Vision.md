
# PanicButton — App Vision & Product Brief

## Goal

Build a super simple, beautiful, and fast mobile app called **PanicButton**.

This app helps anyone going through a panic or anxiety episode regulate themselves quickly through guided breathwork exercises (max 3 minutes).  
→ In a moment of crisis:  
→ User opens the app → Taps a big button → Breathwork session starts.

---

## Core Features & Requirements

### 1. Main Screen = Panic Button
> Immediate action.

- Large green button → "Presiona y encuentra la calma"  
- On tap → 3-minute guided breathwork starts  
- Visual guide: Simple animation showing inhale / hold / exhale  

### 2. Breathwork Player
> Lightweight + Focused experience.

- Visual: Expanding / contracting circle  
- Optional:  
  - Audio guide  
  - Vibration feedback  

### 3. BOLT Score Tracker
> For long-term progress.

- Users can measure their BOLT Score (CO₂ tolerance and stress indicator)  
- Test = Hold breath after exhale  
- Timer runs → Result saved to user profile  

### 4. User Profile
> Store basic info:

- Name  
- Age  
- Gender  
- BOLT score history  

---

## Tech Stack

| Layer | Tool |
|-------|------|
| Frontend | Flutter (Dart) |
| Backend | Django (Python) |
| Authentication | Firebase Auth |

---

## Backend Integration Notes

IMPORTANT: Backend with Django will be created later as application scales. 

Current backend is managed fully in Supabase. Both storage and also databases. 
## Current Backend Requirements:
- Supabase for database mgmt 
- Supabase for Auth 
- Supabase for storage

### Future Backedn Requirements:

- Django backend verifying Firebase ID tokens  
- Proper Firebase Authentication configuration (iOS & Android)  
- Flutter → Firebase best practices  
- Clear local setup for both backend & frontend  
- Authenticated API calls from Flutter → Django using ID Token  

Use this repo as reference:  
https://github.com/JoaquinAcuna97/Flutter-Django-Login

---

## Deliverables Checklist

- [X] Working Flutter mobile app  
- [X] GitHub Repo  
- [X] Step-by-step setup guide  
- [ ] Dockerized Django backend  
- [ ] Sample `.env` files (Django + Flutter)  
- [X] Suggestions for UI polish (animations for calmness)  
- [X] Animation Idea → Expanding / contracting ball during breathing  
- [ ] Improved animation for breathing. 
- [ ] Integrating sounds to breathing. 
- [ ] Integrating guidance to breathing. 
- [ ] Creating a journey where user can work and traing their stress capacity and reduce panic episodes with breathwork. 

---

## App Branding

### Colors

| Usage | HEX |
|-------|-----|
| Background | #132737 |
| Text | #FFFFFF |
| Alternative Text | #B0B0B0 |
| Highlights & Icons | #00B383 |
| Buttons | White text: #B0B0B0 |
| Panic Button | Background: #00B383 / Text: #132737 |

### Fonts

| Usage | Font | Style |
|-------|------|-------|
| Titles | Unbounded Bold | Strong presence |
| Text | Cabin Regular | Legible, clean |
| Comments / Inside Text | Cabin Italic | Subtle emphasis |

---

## Animation Logic — Flutter / Dart (Example) 

```dart
import 'dart:async';
import 'package:flutter/material.dart';

class BreathingGuide extends StatefulWidget {
  final int breathingDuration; // Total time in seconds

  BreathingGuide({this.breathingDuration = 180});

  @override
  _BreathingGuideState createState() => _BreathingGuideState();
}

class _BreathingGuideState extends State<BreathingGuide> {
  late Timer timer;
  int totalTime = 0;
  int timerCycle = 0;
  int cycleCount = 0;
  String breathState = "inhale";

  final int inhaleDuration = 4;
  final int holdDuration = 2;
  final int exhaleDuration = 6;

  @override
  void initState() {
    super.initState();
    startBreathingCycle();
  }

  void startBreathingCycle() {
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        totalTime += 1;
        timerCycle = (timerCycle + 1) % (inhaleDuration + holdDuration + exhaleDuration);

        if (timerCycle == 0) {
          breathState = "inhale";
          cycleCount += 1;
        } else if (timerCycle == inhaleDuration) {
          breathState = "hold";
        } else if (timerCycle == inhaleDuration + holdDuration) {
          breathState = "exhale";
        }

        if (totalTime >= widget.breathingDuration) {
          breathState = "complete";
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String getInstruction() {
      switch (breathState) {
        case "inhale":
          return "Inhala";
        case "hold":
          return "Retén";
        case "exhale":
          return "Exhala";
        case "complete":
          return "Completado";
        default:
          return "";
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            getInstruction(),
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          AnimatedContainer(
            duration: Duration(seconds: 1),
            width: breathState == "inhale" ? 200 : 100,
            height: breathState == "inhale" ? 200 : 100,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: 20),
          Text("Ciclo \${cycleCount + 1}"),
        ],
      ),
    );
  }
}
```
