cd build/
git init
git checkout -b gh-pages
git add * 
git commit -m "new site"
git remote add origin https://github.com/bhalonen/SaunaModel.jl
git push --set-upstream --force origin gh-pages