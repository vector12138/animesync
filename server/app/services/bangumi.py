#!/usr/bin/env python3
"""Bangumi API 客户端

封装 Bangumi API v0 的请求，用于搜索番剧、获取详情等。
文档: https://bangumi.github.io/api/
"""

import httpx
import asyncio
from typing import Optional, List, Dict, Any
from dataclasses import dataclass


@dataclass
class BangumiAnime:
    """Bangumi 番剧信息"""
    id: int
    name: str
    name_cn: str
    summary: str
    air_date: str
    images: Dict[str, str]
    total_episodes: int
    rating: Optional[float]
    tags: List[str]
    url: str


class BangumiClient:
    """Bangumi API 客户端"""
    
    BASE_URL = "https://api.bgm.tv"
    
    def __init__(self, user_agent: str = "AnimeSync/0.1.0"):
        self.user_agent = user_agent
        self.client = httpx.AsyncClient(
            base_url=self.BASE_URL,
            headers={
                "User-Agent": user_agent,
                "Accept": "application/json",
            },
            timeout=10.0,
        )
    
    async def search(
        self,
        keyword: str,
        limit: int = 10,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """搜索番剧
        
        Returns:
            搜索结果列表
        """
        params = {
            "type": 2,  # 动画
            "limit": min(limit, 25),
            "offset": offset,
        }
        try:
            response = await self.client.get(
                f"/v0/search/subjects",
                params=params,
                json={"keyword": keyword}
            )
            response.raise_for_status()
            data = response.json()
            return data.get("data", [])
        except Exception as e:
            # Log error but don't crash
            return []
    
    async def get_subject(self, subject_id: int) -> Optional[Dict[str, Any]]:
        """获取番剧详情
        
        Args:
            subject_id: Bangumi 的 subject ID
            
        Returns:
            番剧详情
        """
        try:
            response = await self.client.get(
                f"/v0/subjects/{subject_id}"
            )
            response.raise_for_status()
            return response.json()
        except Exception:
            return None
    
    async def get_user_collection(self, username: str) -> List[Dict[str, Any]]:
        """获取用户的收藏列表 (需要认证)
        
        Args:
            username: Bangumi 用户名
            
        Returns:
            收藏列表
        """
        try:
            response = await self.client.get(
                f"/v0/users/{username}/collections",
                params={"subject_type": 2}  # 动画
            )
            response.raise_for_status()
            return response.json()
        except Exception:
            return []
    
    def _parse_anime(self, data: Dict[str, Any]) -> BangumiAnime:
        """解析 Bangumi API 返回的数据为结构化对象"""
        infobox = data.get("infobox", [])
        total_ep = 0
        for item in infobox:
            if item.get("key") == "话数":
                try:
                    total_ep = int(item.get("value", "0"))
                except (ValueError, TypeError):
                    total_ep = 0
                break
        
        rating = None
        if "rating" in data and "score" in data["rating"]:
            rating = float(data["rating"]["score"])
        
        tags = [t["name"] for t in data.get("tags", [])[:5]]
        
        return BangumiAnime(
            id=data["id"],
            name=data.get("name", ""),
            name_cn=data.get("name_cn", ""),
            summary=data.get("summary", ""),
            air_date=data.get("date", ""),
            images=data.get("images", {}),
            total_episodes=total_ep,
            rating=rating,
            tags=tags,
            url=f"https://bgm.tv/subject/{data['id']}",
        )
    
    async def close(self):
        await self.client.aclose()
    
    async def __aenter__(self):
        return self
    
    async def __aexit__(self, *args):
        await self.close()


# 全局客户端实例
_bangumi_client: Optional[BangumiClient] = None


def get_bangumi_client() -> BangumiClient:
    """获取 Bangumi 客户端单例"""
    global _bangumi_client
    if _bangumi_client is None:
        _bangumi_client = BangumiClient()
    return _bangumi_client