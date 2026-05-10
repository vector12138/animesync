from pydantic import BaseModel, field_validator


class UserRegister(BaseModel):
    username: str
    password: str

    @field_validator("username")
    @classmethod
    def username_valid(cls, v: str) -> str:
        v = v.strip()
        if not (3 <= len(v) <= 50):
            raise ValueError("用户名长度 3-50 位")
        return v

    @field_validator("password")
    @classmethod
    def password_valid(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("密码至少 8 位")
        if not any(c.isupper() for c in v):
            raise ValueError("密码需包含大写字母")
        if not any(c.islower() for c in v):
            raise ValueError("密码需包含小写字母")
        if not any(c.isdigit() for c in v):
            raise ValueError("密码需包含数字")
        return v


class UserLogin(BaseModel):
    username: str
    password: str

    @field_validator("username")
    @classmethod
    def username_valid(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("用户名不能为空")
        return v


class UserResponse(BaseModel):
    id: int
    username: str
    created_at: str | None = None

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    refresh_token: str | None = None
    user: UserResponse


class RefreshRequest(BaseModel):
    refresh_token: str


class RefreshResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    refresh_token: str
    user: UserResponse