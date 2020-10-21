hugo --theme=hyde --buildDrafts --baseUrl="https://hlcooll.github.io/public/"

git add -A

git commit -m "updates $(date)"

git push origin master