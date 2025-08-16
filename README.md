**Puspose**
For Auto Install Rocket Chat 7.9

**Key changes made:**
Added MongoDB admin user creation with root privileges,
Created dedicated Rocket.Chat database user with readWrite permissions,
Enabled MongoDB authentication in the configuration,
Updated the Rocket.Chat service to use authenticated MongoDB connection,
Added separate variables for MongoDB admin and Rocket.Chat user passwords,
Included the MongoDB credentials in the final output for reference,
Ensured proper authentication parameters in the MONGO_URL and MONGO_OPLOG_URL environment variables,
Added proper error handling and waits between MongoDB operations.

**The script now follows security best practices by:**
Creating separate users with appropriate privileges,
Enabling MongoDB authentication,
Using password-protected database connections,
Keeping credentials in variables for easy management,
Providing all credentials in the final output for reference,

