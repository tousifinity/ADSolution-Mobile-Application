from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import mysql.connector
import mysql.connector.pooling
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, HTTPException, BackgroundTasks, Path
import secrets
import asyncio
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import MySQLdb
import bcrypt
import uvicorn

app = FastAPI()

# MySQL Database Configuration
db_config = {
    'host': 'localhost',
    'port': 3308,
    'user': 'root',
    'password': '',
    'database': 'eco_guardian',
}

# CORS Middleware to allow cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],  # Include OPTIONS method here
    allow_headers=["*"],
)

# Model for User Signup Data


class UserSignup(BaseModel):
    name: str
    email: str
    password: str

# Model for User Login Data


class UserLogin(BaseModel):
    email: str
    password: str


class User(BaseModel):
    username: str
    password: str
    email: str


# Establish MySQL connection pool
conn_pool = mysql.connector.pooling.MySQLConnectionPool(**db_config)

# API Endpoint for Root URL


@app.get("/")
async def root():
    return {"message": "Welcome to the FastAPI MySQL integration demo!"}

# API Endpoint for User Signup
# API Endpoint for User Signup


@app.post("/signup/")
async def signup(user_data: UserSignup):
    try:
        # Acquire a connection from the pool
        conn = conn_pool.get_connection()
        cursor = conn.cursor()
        # Check if the email already exists in the users table
        # with conn.cursor() as cursor:
        sql_check_email = "SELECT * FROM users WHERE email = %s"
        cursor.execute(sql_check_email, (user_data.email,))
        existing_user = cursor.fetchone()

        if existing_user:
            # If the email already exists, raise HTTPException with status code 409 (Conflict)
            raise HTTPException(
                status_code=409, detail="Email already exists. Please use a different email.")

        # If the email doesn't exist, insert user data into the users table
        sql_insert_user = "INSERT INTO users (name, email, password) VALUES (%s, %s, %s)"
        values = (user_data.name, user_data.email, user_data.password)
        cursor.execute(sql_insert_user, values)

        # Commit changes
        conn.commit()
        return {"message": "User signed up successfully"}

    except mysql.connector.Error as e:
        # In case of any MySQL errors, raise HTTPException
        raise HTTPException(status_code=500, detail=f"MySQL Error: {str(e)}")
    finally:
        # Release the connection back to the pool
        if conn.is_connected():
            conn.close()


# API Endpoint for User Login
@app.post("/login/")
async def login(user_data: UserLogin):
    try:
        # Acquire a connection from the pool
        conn = conn_pool.get_connection()
        cursor = conn.cursor()

        # Check if email and password match in the users table
        # conn.cursor() as cursor:
        sql = "SELECT * FROM users WHERE email = %s AND password = %s"
        values = (user_data.email, user_data.password)
        cursor.execute(sql, values)

        user = cursor.fetchone()

        if user:
            # User credentials are correct
            return {"message": "Login successful"}
        else:
            # User credentials are incorrect
            raise HTTPException(status_code=401, detail="Invalid credentials")

    except mysql.connector.Error as e:
        # In case of any MySQL errors, raise HTTPException
        raise HTTPException(status_code=500, detail=f"MySQL Error: {str(e)}")
    finally:
        # Release the connection back to the pool
        if conn.is_connected():
            conn.close()


async def remove_otp(email: str):
    await asyncio.sleep(300)  # Remove OTP after 5 minutes
    if email in otp_map:
        del otp_map[email]

otp_map = {}


def send_email(subject, message, to_email):
    try:
        # Set up the email server
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()

        # Replace 'YOUR_EMAIL_USERNAME' and 'YOUR_EMAIL_PASSWORD' with your actual email credentials
        email_username = 'shakilahmed4024@gmail.com'
        email_password = ' jiqzixdpxtasgrrk'

        server.login(email_username, email_password)

        # Create message
        msg = MIMEMultipart()
        msg['From'] = email_username
        msg['To'] = to_email
        msg['Subject'] = subject
        msg.attach(MIMEText(message, 'plain'))

        # Send the email
        server.sendmail(email_username, to_email, msg.as_string())
        print("Email sent successfully!")
    except smtplib.SMTPException as e:
        print(f"Failed to send email: {e}")
    finally:
        server.quit()


@app.post("/generate_otp/")
async def generate_otp(email: str):
    print(f"Received email: {email}")
    if '@' not in email or '.' not in email:
        raise HTTPException(status_code=400, detail="Invalid email format")

    otp = str(secrets.randbelow(900000) + 100000)  # Generate a 6-digit OTP
    otp_map[email] = otp
    asyncio.create_task(remove_otp(email))
    send_email("User Verification", f"Your OTP is: {otp}", email)
    print(f"OTP for {email} is: {otp}")
    return {"message": "OTP generated successfully."}


@app.post("/validate_otp/")
async def validate_otp(email: str, entered_otp: str):
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

# @app.post("/users/")
# def create_user(user: User):
#     hashed_password = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt())
#     cursor = conn_pool.cursor()
#     query = "INSERT INTO user (username, password, email) VALUES (%s, %s, %s, %s)"
#     cursor.execute(query, (user.username, hashed_password, user.email))
#     conn_pool.commit()
#     #user.id = cursor.lastrowid
#     cursor.close()
#     return {'msg': 'create successfull'}


@app.post("/users/")
def create_user(user: User):
    try:
        # Acquire a connection from the pool
        conn = conn_pool.get_connection()

        # Hash the password
        hashed_password = bcrypt.hashpw(
            user.password.encode('utf-8'), bcrypt.gensalt())

        # Create a cursor from the connection
        cursor = conn.cursor()

        # Execute the query
        query = "INSERT INTO user (name, password, email) VALUES (%s, %s, %s, %s)"
        cursor.execute(query, (user.username, hashed_password, user.email))

        # Commit the transaction
        conn.commit()

        # Close the cursor
        cursor.close()

        return {'msg': 'create successful'}
    except mysql.connector.Error as e:
        # In case of any MySQL errors, raise HTTPException
        raise HTTPException(status_code=500, detail=f"MySQL Error: {str(e)}")

    finally:
        # Release the connection back to the pool
        if conn.is_connected():
            conn.close()


@app.get("/get-latest-data")
def get_latest_data():
    try:
        # Acquire a connection from the pool
        conn = conn_pool.get_connection()

        # Create a cursor from the connection
        cursor = conn.cursor()

        # Execute the query
        query = "SELECT * FROM availablebinspage WHERE id=1"
        cursor.execute(query)
        rows = cursor.fetchall()
        conn.commit()
        cursor.close()

        finalResult = []
        for row in rows:
            finalResult.append({
                "id": row[0],
                "binName": row[1],
                "fillpercentage": row[2],
                "binStatus": row[3],
            })

        return finalResult[0]
    except mysql.connector.Error as e:
        # In case of any MySQL errors, raise HTTPException
        raise HTTPException(status_code=500, detail=f"MySQL Error: {str(e)}")

    finally:
        # Release the connection back to the pool
        if conn.is_connected():
            conn.close()


if "__name__" == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
