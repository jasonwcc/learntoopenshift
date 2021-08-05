git checkout -b $1    
git add .
git commit -am "Updated `date +%D` | by J"

if [ $# -eq 0 ]
then
  echo "pushing to main"
  git push origin main 
else
  echo "pushing to $1 branch"
  git push -f origin $1
fi  

