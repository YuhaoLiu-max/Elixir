# sample2.py - functions, string handling, and file operations

import os
import math


# --- string utilities ---

def count_words(text):
    words = text.split()
    return len(words)


def reverse_string(s):
    return s[::-1]


def is_palindrome(s):
    cleaned = s.lower().replace(" ", "")
    return cleaned == cleaned[::-1]


def word_frequency(text):
    freq = {}
    for word in text.lower().split():
        if word in freq:
            freq[word] += 1
        else:
            freq[word] = 1
    return freq


# --- math helpers ---

def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(math.sqrt(n)) + 1):
        if n % i == 0:
            return False
    return True


def primes_up_to(limit):
    return [n for n in range(2, limit + 1) if is_prime(n)]


def factorial(n):
    if n == 0 or n == 1:
        return 1
    return n * factorial(n - 1)


# --- simple class ---

class Student:
    def __init__(self, name, grade):
        self.name = name
        self.grade = grade

    def passed(self):
        return self.grade >= 60

    def __repr__(self):
        status = "pass" if self.passed() else "fail"
        return f"{self.name}: {self.grade} ({status})"


# --- main ---

if __name__ == "__main__":
    # string demos
    sentence = "racecar is a palindrome"
    print("Word count:", count_words(sentence))
    print("Reversed:", reverse_string("hello"))
    print("Is palindrome:", is_palindrome("racecar"))

    freq = word_frequency("the cat sat on the mat the cat")
    print("Word frequency:", freq)

    # math demos
    print("\nPrimes up to 30:", primes_up_to(30))
    print("Factorial of 6:", factorial(6))

    # student demo
    students = [
        Student("Alice", 90),
        Student("Bob", 55),
        Student("Charlie", 73),
    ]
    for s in students:
        print(s)

    # list comprehension and lambda
    passing = list(filter(lambda s: s.passed(), students))
    print("\nPassing students:", [s.name for s in passing])
