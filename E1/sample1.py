# sample1.py - basic data structures and sorting

# --- linked list ---

class Node:
    def __init__(self, value):
        self.value = value
        self.next = None

class LinkedList:
    def __init__(self):
        self.head = None

    def append(self, value):
        new_node = Node(value)
        if self.head is None:
            self.head = new_node
            return
        current = self.head
        while current.next is not None:
            current = current.next
        current.next = new_node

    def to_list(self):
        result = []
        current = self.head
        while current is not None:
            result.append(current.value)
            current = current.next
        return result

    def __len__(self):
        count = 0
        current = self.head
        while current is not None:
            count += 1
            current = current.next
        return count


# --- sorting ---

def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
    return arr


def binary_search(arr, target):
    left = 0
    right = len(arr) - 1
    while left <= right:
        mid = (left + right) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1


# --- main ---

if __name__ == "__main__":
    # linked list demo
    ll = LinkedList()
    for v in [10, 20, 30, 40, 50]:
        ll.append(v)
    print("Linked list:", ll.to_list())
    print("Length:", len(ll))

    # sorting demo
    numbers = [64, 34, 25, 12, 22, 11, 90]
    print("\nBefore sort:", numbers)
    sorted_numbers = bubble_sort(numbers[:])
    print("After sort:", sorted_numbers)

    # binary search demo
    idx = binary_search(sorted_numbers, 25)
    print("Index of 25:", idx)

    # some numeric literals
    hex_val = 0xFF
    bin_val = 0b1010
    float_val = 3.14
    print(f"\nhex: {hex_val}, binary: {bin_val}, float: {float_val}")
