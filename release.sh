set -xe
version=$(grep VERSION lib/version.rb| cut -d \" -f2)
git commit -am "$*" 
git push 
git tag $version 
git push --tags 
gem build term-slides.gemspec 
gem push term-slides-$version.gem
