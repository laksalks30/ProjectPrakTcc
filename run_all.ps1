Start-Process "C:\xampp\mysql_start.bat"
Start-Sleep -Seconds 5
Start-Process "powershell" -ArgumentList "-NoExit -Command `"cd auth-service; npm run dev`""
Start-Process "powershell" -ArgumentList "-NoExit -Command `"cd medication-service; .\venv\Scripts\activate; uvicorn app.main:app --host 0.0.0.0 --port 8002 --reload`""
Start-Process "powershell" -ArgumentList "-NoExit -Command `"cd frontend; npm run dev`""
