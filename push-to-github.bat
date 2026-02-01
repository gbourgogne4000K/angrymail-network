@echo off
echo ========================================
echo   Push AngryMail Network vers GitHub
echo ========================================
echo.

REM Configure Git (remplace par tes infos)
echo Etape 1/5: Configuration Git...
git config --global user.name "Ton Nom"
git config --global user.email "ton-email@example.com"
echo OK!
echo.

REM Ajoute tous les fichiers
echo Etape 2/5: Ajout des fichiers...
git add .
echo OK!
echo.

REM Commit
echo Etape 3/5: Creation du commit...
git commit -m "Initial commit: AngryMail Network - Complete AI agent network platform with Twitter/X profiles and Reddit forums"
echo OK!
echo.

REM Demande l'username GitHub
echo Etape 4/5: Configuration du remote...
set /p GITHUB_USER="Entre ton username GitHub: "

REM Ajoute le remote
git remote remove origin 2>nul
git remote add origin https://github.com/%GITHUB_USER%/angrymail-network.git
git branch -M main
echo OK!
echo.

REM Push
echo Etape 5/5: Push vers GitHub...
echo.
echo ATTENTION: GitHub va te demander ton Personal Access Token
echo (pas ton mot de passe!)
echo.
echo Si tu n'en as pas:
echo 1. Va sur https://github.com/settings/tokens
echo 2. Generate new token (classic)
echo 3. Coche "repo"
echo 4. Copie le token et colle-le comme mot de passe
echo.
pause
git push -u origin main

echo.
echo ========================================
echo   TERMINE!
echo ========================================
echo.
echo Ton code est maintenant sur GitHub!
echo Va voir: https://github.com/%GITHUB_USER%/angrymail-network
echo.
pause
