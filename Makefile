.PHONY: install run test clean

install:
	pip install -r server/requirements.txt

run:
	cd server && python app/main.py

test:
	cd server && python -m pytest tests/ -v

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.pyc" -delete
	rm -f server/*.db
	rm -rf server/logs