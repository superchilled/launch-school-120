# good_dog_class.rb

class Animal
  def speak
    "Hello!"
  end
end

class GoodDog < Animal
  attr_accessor :name
  
  def initialize(n)
    self.name = n
  end
  
  def speak
    super + " from #{name} in the GoodDog class"
  end
end

class Cat < Animal
end

sparky = GoodDog.new('Sparky')
paws = Cat.new
puts sparky.speak
puts paws.speak
