# sample3.py - classes, inheritance, and error handling

class Animal:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def speak(self):
        return "..."

    def __repr__(self):
        return f"{self.__class__.__name__}(name={self.name!r}, age={self.age})"


class Dog(Animal):
    def __init__(self, name, age, breed):
        super().__init__(name, age)
        self.breed = breed

    def speak(self):
        return "Woof!"

    def fetch(self, item):
        return f"{self.name} fetched the {item}!"


class Cat(Animal):
    def __init__(self, name, age, indoor=True):
        super().__init__(name, age)
        self.indoor = indoor

    def speak(self):
        return "Meow!"


# --- simple stack ---

class Stack:
    def __init__(self):
        self._items = []

    def push(self, item):
        self._items.append(item)

    def pop(self):
        if self.is_empty():
            raise IndexError("pop from empty stack")
        return self._items.pop()

    def peek(self):
        if self.is_empty():
            raise IndexError("peek at empty stack")
        return self._items[-1]

    def is_empty(self):
        return len(self._items) == 0

    def __len__(self):
        return len(self._items)


# --- error handling ---

def divide(a, b):
    try:
        result = a / b
    except ZeroDivisionError:
        print("Error: cannot divide by zero")
        return None
    else:
        return result
    finally:
        print(f"divide({a}, {b}) called")


def read_positive(value):
    if not isinstance(value, (int, float)):
        raise TypeError(f"expected a number, got {type(value).__name__}")
    if value < 0:
        raise ValueError(f"value must be positive, got {value}")
    return value


# --- main ---

if __name__ == "__main__":
    # animals
    dog = Dog("Rex", 3, "Labrador")
    cat = Cat("Whiskers", 5)

    animals = [dog, cat]
    for animal in animals:
        print(f"{animal.name} says: {animal.speak()}")

    print(dog.fetch("ball"))
    print(dog)

    # stack demo
    stack = Stack()
    for item in ["a", "b", "c"]:
        stack.push(item)

    print("\nStack size:", len(stack))
    print("Top item:", stack.peek())
    print("Popped:", stack.pop())
    print("Stack size after pop:", len(stack))

    # error handling demo
    print()
    divide(10, 2)
    divide(5, 0)

    try:
        read_positive(-3)
    except ValueError as e:
        print("Caught:", e)

    # some literals for the lexer to pick up
    HEX = 0xDEAD
    BIN = 0b11001100
    OCTAL = 0o777
    COMPLEX = 2 + 3j
    print(f"\nhex={HEX}, bin={BIN}, octal={OCTAL}, complex={COMPLEX}")
