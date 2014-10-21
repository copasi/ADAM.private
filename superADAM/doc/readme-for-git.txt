git add filename
git commit -m "description of changes"
git push

if git push fails, it's probably because of conflicts from someone else making changes
then do
git fetch
git rebase
(or git pull --rebase)
if successful, do
git push

to see the status, try
git status
git diff
