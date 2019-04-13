set -xe
version=$(grep VERSION lib/version.rb| cut -d \" -f2)
git commit -am "$*" 
git push 
git tag $version 
git push --tags 
gem build term-images.gemspec 
gem push term-images-$version.gem
