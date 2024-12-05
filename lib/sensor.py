from fastapi import FastAPI, HTTPException, BackgroundTasks, Request
from pydantic import BaseModel
import mysql.connector
import mysql.connector.pooling
from fastapi.middleware.cors import CORSMiddleware
import bcrypt
import uvicorn
import secrets
import asyncio
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta

app = FastAPI()

# MySQL Database Configuration
db_config = {
    'host': 'localhost',
    'port': 3308,
    'user': 'root',
    'password': '',
    'database': 'ad_solution',
}

# CORS Middleware to allow cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "PUT", "OPTIONS"],
    allow_headers=["*"],
)

# Pydantic Models


class UserSignup(BaseModel):
    name: str
    age: int
    gender: str
    email: str
    password: str
    caregiver_email: str  # New field for caregiver email


class UserLogin(BaseModel):
    email: str
    password: str


class EmailRequest(BaseModel):
    email: str


class OTPValidationRequest(BaseModel):
    email: str
    otp: str


class UserProfile(BaseModel):
    name: str
    age: int
    gender: str
    email: str
    caregiver_email: str  # New field for caregiver email
    password: str


# Establish MySQL connection pool
conn_pool = mysql.connector.pooling.MySQLConnectionPool(**db_config)


@app.get("/")
async def root():
    return {"message": "Welcome to the FastAPI MySQL integration demo!"}


@app.post("/signup/")
async def signup(user_data: UserSignup):
    try:
        conn = conn_pool.get_connection()
        cursor = conn.cursor()

        sql_check_email = "SELECT * FROM users WHERE email = %s"
        cursor.execute(sql_check_email, (user_data.email,))
        existing_user = cursor.fetchone()

        if existing_user:
            raise HTTPException(
                status_code=409, detail="Email already exists. Please use a different email.")

        hashed_password = bcrypt.hashpw(
            user_data.password.encode('utf-8'), bcrypt.gensalt())

        sql_insert_user = "INSERT INTO users (user_id, name, age, gender, email, password, caregiver_email) VALUES (UUID(), %s, %s, %s, %s, %s, %s)"
        values = (user_data.name, user_data.age, user_data.gender,
                  user_data.email, hashed_password, user_data.caregiver_email)  # Include caregiver email
        cursor.execute(sql_insert_user, values)

        conn.commit()
        return {"message": "User signed up successfully"}

    except mysql.connector.Error as e:
        raise HTTPException(status_code=500, detail=f"MySQL Error: {str(e)}")
    finally:
        if conn.is_connected():
            conn.close()


@app.post("/login/")
async def login(user_data: UserLogin):
    try:
        conn = conn_pool.get_connection()
        cursor = conn.cursor()

        sql_check_email = "SELECT * FROM users WHERE email = %s"
        cursor.execute(sql_check_email, (user_data.email,))
        user = cursor.fetchone()

        if user and bcrypt.checkpw(user_data.password.encode('utf-8'), user[5].encode('utf-8')):
            return {"message": "Login successful", "email": user[4]}
        else:
            raise HTTPException(status_code=401, detail="Invalid credentials")

    except mysql.connector.Error as e:
        raise HTTPException(status_code=500, detail=f"MySQL Error: {str(e)}")
    finally:
        if conn.is_connected():
            conn.close()


@app.get("/profile/")
async def get_profile(email: str):
    try:
        conn = conn_pool.get_connection()
        cursor = conn.cursor()

        sql_get_profile = "SELECT name, age, gender, email, caregiver_email FROM users WHERE email = %s"
        cursor.execute(sql_get_profile, (email,))
        data = cursor.fetchone()

        if data:
            return {
                "name": data[0],
                "age": data[1],
                "gender": data[2],
                "email": data[3],
                "caregiver_email": data[4]  # Include caregiver's email
            }
        else:
            raise HTTPException(
                status_code=404, detail="No profile found for the given email")

    except mysql.connector.Error as e:
        raise HTTPException(status_code=500, detail=f"MySQL Error: {str(e)}")
    finally:
        if conn.is_connected():
            conn.close()


@app.put("/profile/")
async def update_profile(user_data: UserProfile):
    try:
        conn = conn_pool.get_connection()
        cursor = conn.cursor()

        hashed_password1 = bcrypt.hashpw(
            user_data.password.encode('utf-8'), bcrypt.gensalt())

        sql_update_profile = "UPDATE users SET name = %s, age = %s, gender = %s, password = %s, caregiver_email = %s WHERE email = %s"
        values = (user_data.name, user_data.age, user_data.gender,
                  hashed_password1, user_data.caregiver_email, user_data.email)  # Include caregiver email
        cursor.execute(sql_update_profile, values)

        conn.commit()

        return {"message": "Profile updated successfully"}

    except mysql.connector.Error as e:
        raise HTTPException(status_code=500, detail=f"MySQL Error: {str(e)}")
    finally:
        if conn.is_connected():
            conn.close()


# Threshold constants
TEMPERATURE_THRESHOLD = 38.0  # Example threshold value
BPM_THRESHOLD = 85  # Example threshold value
SPO2_THRESHOLD = 90  # Example threshold value

# Global variables
last_email_sent_time = None
EMAIL_COOLDOWN_PERIOD = timedelta(minutes=1)  # Cooldown period of 1 minute
first_email_sent = False  # Flag to check if the first email has been sent


@app.get("/sensor-data/")
async def get_sensor_data(email: str):
    global last_email_sent_time
    global first_email_sent
    try:
        conn = conn_pool.get_connection()
        cursor = conn.cursor()

        sql_get_data = """
        SELECT temperature, humidity, bpm, spo2, latitude, longitude, altitude, timestamp, caregiver_email
        FROM health_data 
        JOIN users ON health_data.user_id = users.user_id
        WHERE users.email = %s 
        ORDER BY health_data.timestamp DESC LIMIT 1
        """
        cursor.execute(sql_get_data, (email,))
        data = cursor.fetchone()

        if data:
            sensor_data = {
                "temperature": data[0],
                "humidity": data[1],
                "bpm": data[2],
                "spo2": data[3],
                "latitude": data[4],
                "longitude": data[5],
                "altitude": data[6],
                "timestamp": data[7]
            }

            # Retrieve caregiver's email
            caregiver_email = data[8]

            # Check each sensor parameter and collect exceeded thresholds
            current_time = datetime.now()
            exceeded_parameters = []

            # Check temperature
            if sensor_data["temperature"] > TEMPERATURE_THRESHOLD:
                exceeded_parameters.append(
                    f"Temperature: {sensor_data['temperature']}°C (Threshold: {TEMPERATURE_THRESHOLD}°C)")

            # Check bpm
            if sensor_data["bpm"] > BPM_THRESHOLD:
                exceeded_parameters.append(
                    f"BPM: {sensor_data['bpm']} (Threshold: {BPM_THRESHOLD})")

            # Check spo2
            if sensor_data["spo2"] < SPO2_THRESHOLD:
                exceeded_parameters.append(
                    f"SpO2: {sensor_data['spo2']} (Threshold: {SPO2_THRESHOLD})")

            # Send email if any thresholds are exceeded and cooldown period has passed
            if exceeded_parameters:
                if not first_email_sent or (current_time - last_email_sent_time) > EMAIL_COOLDOWN_PERIOD:
                    # Create map link
                    map_link = f"https://www.google.com/maps?q={sensor_data['latitude']},{sensor_data['longitude']}"
                    email_body = f"""
                    <html>
                    <body>
                    <p>Alert: The following parameters have exceeded their thresholds:</p>
                    <ul>
                    {''.join(f'<li>{param}</li>' for param in exceeded_parameters)}
                    </ul>
                    <p>Location: <a href="{map_link}" target="_blank">View on Map</a></p>
                    </body>
                    </html>
                    """
                    send_email(
                        "Alert", email_body, caregiver_email)
                    last_email_sent_time = current_time
                    print(f"Email sent at {current_time}")
                    if not first_email_sent:
                        first_email_sent = True

            return sensor_data
        else:
            raise HTTPException(
                status_code=404, detail="No data found for the given email")

    except mysql.connector.Error as e:
        raise HTTPException(status_code=500, detail=f"MySQL Error: {str(e)}")
    finally:
        if conn.is_connected():
            conn.close()


# OTP Handling
otp_map = {}


async def remove_otp(email: str):
    await asyncio.sleep(300)  # Remove OTP after 5 minutes
    if email in otp_map:
        del otp_map[email]


def send_email(subject, message, to_email):
    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()

        email_username = '1901011@iot.bdu.ac.bd'
        email_password = 'rtxaucfofhdrthdr'

        server.login(email_username, email_password)

        msg = MIMEMultipart()
        msg['From'] = email_username
        msg['To'] = to_email
        msg['Subject'] = subject
        msg.attach(MIMEText(message, 'html'))

        server.sendmail(email_username, to_email, msg.as_string())
        print("Email sent successfully!")
    except smtplib.SMTPException as e:
        print(f"Failed to send email: {e}")
    finally:
        server.quit()


@app.post("/generate_otp/")
async def generate_otp(email_request: EmailRequest):
    email = email_request.email
    if '@' not in email or '.' not in email:
        raise HTTPException(status_code=400, detail="Invalid email format")

    otp = str(secrets.randbelow(900000) + 100000)  # Generate a 6-digit OTP
    otp_map[email] = otp
    asyncio.create_task(remove_otp(email))
    send_email("User Verification", f"Your OTP is: {otp}", email)
    print(f"OTP for {email} is: {otp}")
    return {"message": "OTP generated successfully."}


@app.post("/validate_otp/")
async def validate_otp(otp_request: OTPValidationRequest):
    email = otp_request.email
    entered_otp = otp_request.otp
    if email not in otp_map:
        raise HTTPException(
            status_code=404, detail="OTP not found for the given email.")

    stored_otp = otp_map[email]
    if stored_otp == entered_otp:
        del otp_map[email]
        print(f"OTP for {email} validated successfully.")
        return {"message": "OTP validated successfully."}
    else:
        print(f"OTP validation failed for {email}.")
        raise HTTPException(status_code=400, detail="Invalid OTP.")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
