# Local Angel: App Overview

**Local Angel** is a community-driven mobile application designed to bridge the gap between individuals needing assistance and local volunteers willing to provide it. It digitizes the concept of "neighbors helping neighbors" by creating a secure, location-based network for requesting and receiving daily support, ranging from routine tasks to emergency aid.

---

### **Who is it For?**

The application serves three distinct but interconnected user roles:

* **😇 Angels (The Requesters):** Individuals who require assistance due to age, disability, or temporary situations. They can be independent users or managed by a family member.
* **🛡️ Guardians (The Volunteers):** Community members who sign up to help. They earn points, badges, and rewards for their service. They can be verified via ID to handle sensitive requests.
* **💼 Managers (The Caregivers):** Family members or professionals who manage the profile and requests of an "Angel" who cannot use the app independently. They act as the bridge, ensuring their loved ones get help.

---

### **What Does It Do?**

Local Angel facilitates real-time support through a feature called a **"Ping"** (Help Request).

* **Request Management:** Users create Pings for specific categories (Medical, Mobility, Social, Safety) with defined urgency levels (Routine, Urgent, Emergency).
* **Smart Matching:** The app uses geolocation to broadcast these requests to nearby, available Guardians. It supports "Broadcasting" to the whole community or "Assigning" to specific trusted connections.
* **Safety & Trust:** Includes ID verification for Guardians, "Trusted" networks, and Manager oversight to ensure user safety.
* **Gamification:** To sustain volunteer engagement, Guardians earn points for completed tasks, compete on leaderboards, and unlock real-world rewards from local businesses.

---

### **How Does It Work?**

The operational flow revolves around the lifecycle of a support request:

1. **Onboarding:** Users sign up via Google, define their role (Angel, Guardian, Manager), and grant location permissions.
2. **The Request (Ping):** An Angel (or their Manager) creates a Ping, selecting the type of help needed (e.g., "Need a ride to the doctor").
3. **Notification:** Nearby Guardians receive an alert via the **Community Feed**. They can view the urgency, distance, and details.
4. **Connection:** A Guardian accepts the request. A secure **Chat** is instantly created between the Guardian, the Angel, and the Manager (if applicable) to coordinate details.
5. **Resolution:** Once the task is done, the Ping is marked as complete. The Angel rates the interaction, and the Guardian receives points.

---

Pages:

### **1. Onboarding & Authentication**

These pages handle the entry of new and returning users.

* **Welcome Page** (Entry Point)
* *Includes nested states:* Login, Onboarding Slides, Role Selection, Terms Agreement, Location Permission, Profile Picture Upload, Completion Success.


* **VerificationWaiting Page**
* *Context:* A holding screen for users (specifically Managers) waiting for their role request to be approved.


* **LegalConsentModal**
* *Context:* A blocking modal/screen that forces users to agree to new Terms/Privacy policies before using the app.



### **2. Core Experience**

The main hubs where users land and perform primary actions.

* **Dashboard Page** (Home Screen)
* *Context:* The central hub displaying active events, manager overviews, and quick actions based on the user's role.


* **Create Ping Page**
* *Context:* The form used to create a new help request (for self or managed Angel).


* **Community Alerts Page** (Feed)
* *Context:* A feed of open help requests ("Pings") visible to Guardians and Managers.


* **My Support Requests Page**
* *Context:* A history view for Angels to see their past and current help requests.



### **3. Communication & Social**

Pages dedicated to messaging and managing community relationships.

* **My Chats Page**
* *Context:* A list of all active conversations (Direct Messages and Group/Ping chats).


* **Chat Detail Page**
* *Context:* The actual conversation view for a specific chat.


* **Connections Page** (My Network)
* *Context:* Manages relationships (My Guardians, My Angels) and handles connection requests.
* *Includes Tabs:* My Network, Requests, Search People.



### **4. Gamification (Guardian Features)**

Pages designed to motivate volunteers.

* **Rewards Page**
* *Context:* Shows the Guardian's points, progress bars, available prizes, and achievements.


* **Leaderboard Page**
* *Context:* Displays rankings of top Guardians (Monthly and All-Time).



### **5. Settings & Legal**

Pages for user configuration and static information.

* **Settings Page**
* *Context:* Handles profile editing, role preferences, availability toggles, and privacy settings.


* **Accessibility Page**
* *Context:* Nested under Settings; allows toggling high contrast, large text, etc.


* **Terms Page**
* *Context:* Nested under Settings; displays the Terms of Use.


* **Privacy Page**
* *Context:* Nested under Settings; displays the Privacy Policy.



**Would you like me to generate the database schema that would be required to support these pages?**