
curl -X POST http://localhost:8000/users/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","role":"professional"}'
  
curl http://localhost:8000/feed/{user_id}