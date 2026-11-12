"""Supabase 연결 도우미: 사용자마다 따로 로그인한 클라이언트를 만든다."""
import os

from dotenv import load_dotenv
from supabase import Client, create_client

# override=True: 컴퓨터에 같은 이름의 환경 변수가 있어도 이 프로젝트의 .env 값을 사용
load_dotenv(override=True)

URL = os.getenv("SUPABASE_URL")
ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
TEST_PASSWORD = os.getenv("TEST_PASSWORD")


def new_client() -> Client:
    """로그인 안 한 클라이언트 (anon)"""
    return create_client(URL, ANON_KEY)


def login(email: str) -> Client:
    """해당 이메일로 로그인한 클라이언트"""
    client = new_client()
    client.auth.sign_in_with_password({"email": email, "password": TEST_PASSWORD})
    return client
