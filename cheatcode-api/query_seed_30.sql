-- ─────────────────────────────────────────────────────────────────────────────
-- CHEATCODE — 30 PROBLEM SEED
-- Run in Supabase SQL Editor
-- ─────────────────────────────────────────────────────────────────────────────

-- First add missing patterns
insert into patterns (id, name, description) values
  ('a1b2c3d4-0000-0000-0000-000000000006', 'Two Pointer', 'Two indices moving toward or away from each other. Eliminates nested loops. O(n) instead of O(n²).'),
  ('a1b2c3d4-0000-0000-0000-000000000007', 'Binary Search', 'Eliminate half the search space each step. Requires sorted input or monotonic condition. O(log n).'),
  ('a1b2c3d4-0000-0000-0000-000000000008', 'Dynamic Programming', 'Break into overlapping subproblems. Store results to avoid recomputation. Top-down or bottom-up.'),
  ('a1b2c3d4-0000-0000-0000-000000000009', 'Hash Map', 'Trade space for time. O(1) lookup instead of O(n) search. Classic complement/frequency patterns.')
on conflict (name) do nothing;


-- ─────────────────────────────────────────────────────────────────────────────
-- SLIDING WINDOW (3 more — already have 3)
-- ─────────────────────────────────────────────────────────────────────────────

insert into problems (title, company, company_badge, pattern, pattern_id, difficulty, code_lines, hints, explanation, brute_force, optimised, brute_complexity, optimised_complexity, related_patterns) values

('Minimum Size Subarray Sum', 'Amazon', 'Amazon L4', 'Sliding Window', 'a1b2c3d4-0000-0000-0000-000000000001', 2,
'[
  {"text": "function minSubArrayLen(target, nums) {", "is_blank": false},
  {"text": "  let left = 0, sum = 0", "is_blank": false},
  {"text": "  let min = Infinity", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let right = 0; right < nums.length; right++) {", "is_blank": false},
  {"text": "    sum += nums[right]", "is_blank": false},
  {"text": "    while (sum >= target) {", "is_blank": false},
  {"text": "      min = Math.min(min, right - left + 1)", "is_blank": false},
  {"text": "      ______", "is_blank": true, "blank_answer": "sum -= nums[left++]"},
  {"text": "    }", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return min === Infinity ? 0 : min", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["This is a dynamic sliding window — size changes based on condition.", "When sum >= target, try to shrink the window from the left.", "Shrinking means subtracting the leftmost element and moving left pointer."]',
'When the window sum meets the target, record its size then shrink from the left. Subtracting nums[left++] does both: removes the leftmost element and advances the pointer.',
'function minSubArrayLen(target, nums) {
  let min = Infinity
  for (let i = 0; i < nums.length; i++) {
    let sum = 0
    for (let j = i; j < nums.length; j++) {
      sum += nums[j]
      if (sum >= target) {
        min = Math.min(min, j - i + 1)
        break
      }
    }
  }
  return min === Infinity ? 0 : min
}',
'function minSubArrayLen(target, nums) {
  let left = 0, sum = 0, min = Infinity
  for (let right = 0; right < nums.length; right++) {
    sum += nums[right]
    while (sum >= target) {
      min = Math.min(min, right - left + 1)
      sum -= nums[left++]
    }
  }
  return min === Infinity ? 0 : min
}',
'O(n²) time · O(1) space', 'O(n) time · O(1) space',
'["Maximum sum subarray", "Longest substring without repeating chars", "Fruit into baskets"]'),

('Longest Subarray with Ones after Deletion', 'Microsoft', 'Microsoft L62', 'Sliding Window', 'a1b2c3d4-0000-0000-0000-000000000001', 2,
'[
  {"text": "function longestSubarray(nums) {", "is_blank": false},
  {"text": "  let left = 0, zeros = 0, max = 0", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let right = 0; right < nums.length; right++) {", "is_blank": false},
  {"text": "    if (nums[right] === 0) zeros++", "is_blank": false},
  {"text": "    while (zeros > 1) {", "is_blank": false},
  {"text": "      ______", "is_blank": true, "blank_answer": "if (nums[left++] === 0) zeros--"},
  {"text": "    }", "is_blank": false},
  {"text": "    max = Math.max(max, right - left)", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return max", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["You can delete exactly one element — so allow at most one zero in your window.", "When zeros exceed 1, shrink from the left.", "If the element you remove is a zero, decrement the zeros counter."]',
'The window can contain at most one zero (the element to delete). When it exceeds one zero, shrink left. Note: we return right - left (not + 1) because one element is always deleted.',
'function longestSubarray(nums) {
  let max = 0
  for (let i = 0; i < nums.length; i++) {
    let zeros = 0, len = 0
    for (let j = i; j < nums.length; j++) {
      if (nums[j] === 0) zeros++
      if (zeros > 1) break
      len++
    }
    max = Math.max(max, len - 1)
  }
  return max
}',
'function longestSubarray(nums) {
  let left = 0, zeros = 0, max = 0
  for (let right = 0; right < nums.length; right++) {
    if (nums[right] === 0) zeros++
    while (zeros > 1) {
      if (nums[left++] === 0) zeros--
    }
    max = Math.max(max, right - left)
  }
  return max
}',
'O(n²) time · O(1) space', 'O(n) time · O(1) space',
'["Longest substring without repeating chars", "Max consecutive ones III", "Minimum size subarray sum"]'),

('Number of Subarrays of Size K and Average >= Threshold', 'Google', 'Google L4', 'Sliding Window', 'a1b2c3d4-0000-0000-0000-000000000001', 2,
'[
  {"text": "function numOfSubarrays(arr, k, threshold) {", "is_blank": false},
  {"text": "  let sum = 0, count = 0", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let i = 0; i < k; i++) sum += arr[i]", "is_blank": false},
  {"text": "  if (sum / k >= threshold) count++", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let i = k; i < arr.length; i++) {", "is_blank": false},
  {"text": "    sum += ______", "is_blank": true, "blank_answer": "arr[i] - arr[i - k]"},
  {"text": "    if (sum / k >= threshold) count++", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return count", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Fixed window of size k — same pattern as max sum subarray.", "Slide by adding the new element and removing the oldest.", "Check the average condition after each slide."]',
'Fixed window size k. Initialize with first k elements, then slide: add arr[i] and remove arr[i-k]. Check average condition after each slide.',
'function numOfSubarrays(arr, k, threshold) {
  let count = 0
  for (let i = 0; i <= arr.length - k; i++) {
    let sum = 0
    for (let j = i; j < i + k; j++) sum += arr[j]
    if (sum / k >= threshold) count++
  }
  return count
}',
'function numOfSubarrays(arr, k, threshold) {
  let sum = 0, count = 0
  for (let i = 0; i < k; i++) sum += arr[i]
  if (sum / k >= threshold) count++
  for (let i = k; i < arr.length; i++) {
    sum += arr[i] - arr[i - k]
    if (sum / k >= threshold) count++
  }
  return count
}',
'O(n·k) time · O(1) space', 'O(n) time · O(1) space',
'["Max sum subarray of size K", "Maximum average subarray", "Find all anagrams"]');


-- ─────────────────────────────────────────────────────────────────────────────
-- TWO POINTER (6 problems)
-- ─────────────────────────────────────────────────────────────────────────────

insert into problems (title, company, company_badge, pattern, pattern_id, difficulty, code_lines, hints, explanation, brute_force, optimised, brute_complexity, optimised_complexity, related_patterns) values

('Two Sum II — Sorted Array', 'Amazon', 'Amazon SDE2', 'Two Pointer', 'a1b2c3d4-0000-0000-0000-000000000006', 1,
'[
  {"text": "function twoSum(numbers, target) {", "is_blank": false},
  {"text": "  let left = 0, right = numbers.length - 1", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  while (left < right) {", "is_blank": false},
  {"text": "    const sum = numbers[left] + numbers[right]", "is_blank": false},
  {"text": "    if (sum === target) return [left + 1, right + 1]", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "else if (sum < target) left++"},
  {"text": "    else right--", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Array is sorted — use that property.", "If sum is too small, which pointer should move?", "Moving left pointer increases the sum. Moving right decreases it."]',
'If sum < target we need a bigger sum, so move left pointer right. If sum > target we need smaller, so move right pointer left. Sorted array makes this work.',
'function twoSum(numbers, target) {
  for (let i = 0; i < numbers.length; i++)
    for (let j = i + 1; j < numbers.length; j++)
      if (numbers[i] + numbers[j] === target)
        return [i + 1, j + 1]
}',
'function twoSum(numbers, target) {
  let left = 0, right = numbers.length - 1
  while (left < right) {
    const sum = numbers[left] + numbers[right]
    if (sum === target) return [left + 1, right + 1]
    else if (sum < target) left++
    else right--
  }
}',
'O(n²) time · O(1) space', 'O(n) time · O(1) space',
'["3Sum", "Container with most water", "Valid palindrome"]'),

('Valid Palindrome', 'Meta', 'Meta E4', 'Two Pointer', 'a1b2c3d4-0000-0000-0000-000000000006', 1,
'[
  {"text": "function isPalindrome(s) {", "is_blank": false},
  {"text": "  let left = 0, right = s.length - 1", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  while (left < right) {", "is_blank": false},
  {"text": "    while (left < right && !isAlphaNum(s[left])) left++", "is_blank": false},
  {"text": "    while (left < right && !isAlphaNum(s[right])) right--", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "if (s[left++].toLowerCase() !== s[right--].toLowerCase()) return false"},
  {"text": "  }", "is_blank": false},
  {"text": "  return true", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Skip non-alphanumeric characters first.", "Compare characters case-insensitively.", "If mismatch found, immediately return false. Also advance both pointers."]',
'Skip non-alphanumeric chars by advancing pointers inward. Then compare both characters case-insensitively. If they differ, it is not a palindrome. Advance both pointers in the same statement.',
'function isPalindrome(s) {
  const cleaned = s.toLowerCase().replace(/[^a-z0-9]/g, "")
  return cleaned === cleaned.split("").reverse().join("")
}',
'function isPalindrome(s) {
  let left = 0, right = s.length - 1
  while (left < right) {
    while (left < right && !isAlphaNum(s[left])) left++
    while (left < right && !isAlphaNum(s[right])) right--
    if (s[left++].toLowerCase() !== s[right--].toLowerCase()) return false
  }
  return true
}',
'O(n) time · O(n) space', 'O(n) time · O(1) space',
'["Two Sum II", "Reverse string", "3Sum"]'),

('Container With Most Water', 'Google', 'Google L4', 'Two Pointer', 'a1b2c3d4-0000-0000-0000-000000000006', 2,
'[
  {"text": "function maxArea(height) {", "is_blank": false},
  {"text": "  let left = 0, right = height.length - 1", "is_blank": false},
  {"text": "  let max = 0", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  while (left < right) {", "is_blank": false},
  {"text": "    const area = Math.min(height[left], height[right]) * (right - left)", "is_blank": false},
  {"text": "    max = Math.max(max, area)", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "height[left] < height[right] ? left++ : right--"},
  {"text": "  }", "is_blank": false},
  {"text": "  return max", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Area is limited by the shorter bar.", "Moving the taller bar inward can only decrease area.", "Always move the pointer pointing to the shorter bar."]',
'Area is constrained by the shorter bar. Moving the taller bar inward cannot increase area (width decreases, height stays limited). So always move the shorter bar inward.',
'function maxArea(height) {
  let max = 0
  for (let i = 0; i < height.length; i++)
    for (let j = i + 1; j < height.length; j++)
      max = Math.max(max, Math.min(height[i], height[j]) * (j - i))
  return max
}',
'function maxArea(height) {
  let left = 0, right = height.length - 1, max = 0
  while (left < right) {
    max = Math.max(max, Math.min(height[left], height[right]) * (right - left))
    height[left] < height[right] ? left++ : right--
  }
  return max
}',
'O(n²) time · O(1) space', 'O(n) time · O(1) space',
'["Trapping rain water", "Two Sum II", "3Sum"]'),

('3Sum', 'Meta', 'Meta E5', 'Two Pointer', 'a1b2c3d4-0000-0000-0000-000000000006', 2,
'[
  {"text": "function threeSum(nums) {", "is_blank": false},
  {"text": "  nums.sort((a, b) => a - b)", "is_blank": false},
  {"text": "  const result = []", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let i = 0; i < nums.length - 2; i++) {", "is_blank": false},
  {"text": "    if (i > 0 && nums[i] === nums[i-1]) continue", "is_blank": false},
  {"text": "    let left = i + 1, right = nums.length - 1", "is_blank": false},
  {"text": "    while (left < right) {", "is_blank": false},
  {"text": "      const sum = nums[i] + nums[left] + nums[right]", "is_blank": false},
  {"text": "      if (sum === 0) {", "is_blank": false},
  {"text": "        result.push([nums[i], nums[left], nums[right]])", "is_blank": false},
  {"text": "        ______", "is_blank": true, "blank_answer": "while (left < right && nums[left] === nums[++left]);"},
  {"text": "      } else if (sum < 0) left++", "is_blank": false},
  {"text": "      else right--", "is_blank": false},
  {"text": "    }", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return result", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Sort first — enables two pointer and duplicate skipping.", "Fix one element (i), use two pointer for the other two.", "After finding a triplet, skip duplicates on the left pointer."]',
'Sort the array. Fix the first element with i, then use two pointers for the remaining pair. After a match, advance left and skip any duplicates to avoid repeating triplets.',
'function threeSum(nums) {
  const result = []
  for (let i = 0; i < nums.length; i++)
    for (let j = i + 1; j < nums.length; j++)
      for (let k = j + 1; k < nums.length; k++)
        if (nums[i] + nums[j] + nums[k] === 0)
          result.push([nums[i], nums[j], nums[k]])
  return result // has duplicates
}',
'function threeSum(nums) {
  nums.sort((a, b) => a - b)
  const result = []
  for (let i = 0; i < nums.length - 2; i++) {
    if (i > 0 && nums[i] === nums[i-1]) continue
    let left = i + 1, right = nums.length - 1
    while (left < right) {
      const sum = nums[i] + nums[left] + nums[right]
      if (sum === 0) {
        result.push([nums[i], nums[left], nums[right]])
        while (left < right && nums[left] === nums[++left]);
      } else if (sum < 0) left++
      else right--
    }
  }
  return result
}',
'O(n³) time · O(1) space', 'O(n²) time · O(1) space',
'["Two Sum II", "Container with most water", "4Sum"]'),

('Move Zeroes', 'Facebook', 'Meta E3', 'Two Pointer', 'a1b2c3d4-0000-0000-0000-000000000006', 1,
'[
  {"text": "function moveZeroes(nums) {", "is_blank": false},
  {"text": "  let left = 0", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let right = 0; right < nums.length; right++) {", "is_blank": false},
  {"text": "    if (nums[right] !== 0) {", "is_blank": false},
  {"text": "      ______", "is_blank": true, "blank_answer": "[nums[left], nums[right]] = [nums[right], nums[left]]"},
  {"text": "      left++", "is_blank": false},
  {"text": "    }", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Left pointer tracks where the next non-zero should go.", "Right pointer scans for non-zero elements.", "When non-zero found, swap with left position."]',
'Left pointer marks the next position for a non-zero element. When right finds a non-zero, swap it to the left position. Zeroes naturally bubble to the end.',
'function moveZeroes(nums) {
  const nonZero = nums.filter(n => n !== 0)
  const zeros = nums.filter(n => n === 0)
  const result = [...nonZero, ...zeros]
  for (let i = 0; i < nums.length; i++) nums[i] = result[i]
}',
'function moveZeroes(nums) {
  let left = 0
  for (let right = 0; right < nums.length; right++) {
    if (nums[right] !== 0) {
      [nums[left], nums[right]] = [nums[right], nums[left]]
      left++
    }
  }
}',
'O(n) time · O(n) space', 'O(n) time · O(1) space',
'["Remove duplicates from sorted array", "Sort colors", "Two Sum II"]'),

('Trapping Rain Water', 'Amazon', 'Amazon L5', 'Two Pointer', 'a1b2c3d4-0000-0000-0000-000000000006', 3,
'[
  {"text": "function trap(height) {", "is_blank": false},
  {"text": "  let left = 0, right = height.length - 1", "is_blank": false},
  {"text": "  let leftMax = 0, rightMax = 0, water = 0", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  while (left < right) {", "is_blank": false},
  {"text": "    if (height[left] < height[right]) {", "is_blank": false},
  {"text": "      ______", "is_blank": true, "blank_answer": "height[left] >= leftMax ? leftMax = height[left] : water += leftMax - height[left]"},
  {"text": "      left++", "is_blank": false},
  {"text": "    } else {", "is_blank": false},
  {"text": "      height[right] >= rightMax ? rightMax = height[right] : water += rightMax - height[right]", "is_blank": false},
  {"text": "      right--", "is_blank": false},
  {"text": "    }", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return water", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Water trapped at any bar = min(leftMax, rightMax) - height[bar].", "Process the side with the smaller max first.", "If current bar is taller than leftMax, update leftMax. Otherwise add the trapped water."]',
'Water at any position is limited by the smaller of the two walls. Process whichever side has the smaller max — you know exactly how much water it can hold. Update max if bar is taller, else accumulate water.',
'function trap(height) {
  let water = 0
  for (let i = 1; i < height.length - 1; i++) {
    const leftMax = Math.max(...height.slice(0, i + 1))
    const rightMax = Math.max(...height.slice(i))
    water += Math.min(leftMax, rightMax) - height[i]
  }
  return water
}',
'function trap(height) {
  let left = 0, right = height.length - 1
  let leftMax = 0, rightMax = 0, water = 0
  while (left < right) {
    if (height[left] < height[right]) {
      height[left] >= leftMax ? leftMax = height[left] : water += leftMax - height[left]
      left++
    } else {
      height[right] >= rightMax ? rightMax = height[right] : water += rightMax - height[right]
      right--
    }
  }
  return water
}',
'O(n²) time · O(1) space', 'O(n) time · O(1) space',
'["Container with most water", "Product of array except self", "3Sum"]');


-- ─────────────────────────────────────────────────────────────────────────────
-- BINARY SEARCH (6 problems)
-- ─────────────────────────────────────────────────────────────────────────────

insert into problems (title, company, company_badge, pattern, pattern_id, difficulty, code_lines, hints, explanation, brute_force, optimised, brute_complexity, optimised_complexity, related_patterns) values

('Binary Search', 'Google', 'Google L3', 'Binary Search', 'a1b2c3d4-0000-0000-0000-000000000007', 1,
'[
  {"text": "function search(nums, target) {", "is_blank": false},
  {"text": "  let left = 0, right = nums.length - 1", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  while (left <= right) {", "is_blank": false},
  {"text": "    const mid = Math.floor((left + right) / 2)", "is_blank": false},
  {"text": "    if (nums[mid] === target) return mid", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "else if (nums[mid] < target) left = mid + 1"},
  {"text": "    else right = mid - 1", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return -1", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["If mid is too small, the target must be to the right.", "Move left to mid + 1 to eliminate the left half.", "If mid is too large, move right to mid - 1."]',
'If nums[mid] < target the answer lies in the right half so move left to mid + 1. If nums[mid] > target it lies in the left half so move right to mid - 1.',
'function search(nums, target) {
  return nums.indexOf(target)
}',
'function search(nums, target) {
  let left = 0, right = nums.length - 1
  while (left <= right) {
    const mid = Math.floor((left + right) / 2)
    if (nums[mid] === target) return mid
    else if (nums[mid] < target) left = mid + 1
    else right = mid - 1
  }
  return -1
}',
'O(n) time · O(1) space', 'O(log n) time · O(1) space',
'["Search in rotated sorted array", "Find minimum in rotated array", "Search a 2D matrix"]'),

('Find Minimum in Rotated Sorted Array', 'Amazon', 'Amazon L4', 'Binary Search', 'a1b2c3d4-0000-0000-0000-000000000007', 2,
'[
  {"text": "function findMin(nums) {", "is_blank": false},
  {"text": "  let left = 0, right = nums.length - 1", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  while (left < right) {", "is_blank": false},
  {"text": "    const mid = Math.floor((left + right) / 2)", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "if (nums[mid] > nums[right]) left = mid + 1"},
  {"text": "    else right = mid", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return nums[left]", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["The minimum is always in the unsorted half.", "If nums[mid] > nums[right], the rotation point (minimum) is in the right half.", "Otherwise the minimum is in the left half including mid."]',
'If mid value is greater than right value, the array is rotated and the minimum lies in the right half. Otherwise the minimum is in the left half including mid itself.',
'function findMin(nums) {
  return Math.min(...nums)
}',
'function findMin(nums) {
  let left = 0, right = nums.length - 1
  while (left < right) {
    const mid = Math.floor((left + right) / 2)
    if (nums[mid] > nums[right]) left = mid + 1
    else right = mid
  }
  return nums[left]
}',
'O(n) time · O(1) space', 'O(log n) time · O(1) space',
'["Binary search", "Search in rotated sorted array", "Find peak element"]'),

('Search in Rotated Sorted Array', 'Meta', 'Meta E5', 'Binary Search', 'a1b2c3d4-0000-0000-0000-000000000007', 2,
'[
  {"text": "function search(nums, target) {", "is_blank": false},
  {"text": "  let left = 0, right = nums.length - 1", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  while (left <= right) {", "is_blank": false},
  {"text": "    const mid = Math.floor((left + right) / 2)", "is_blank": false},
  {"text": "    if (nums[mid] === target) return mid", "is_blank": false},
  {"text": "    if (nums[left] <= nums[mid]) {", "is_blank": false},
  {"text": "      ______", "is_blank": true, "blank_answer": "if (target >= nums[left] && target < nums[mid]) right = mid - 1"},
  {"text": "      else left = mid + 1", "is_blank": false},
  {"text": "    } else {", "is_blank": false},
  {"text": "      if (target > nums[mid] && target <= nums[right]) left = mid + 1", "is_blank": false},
  {"text": "      else right = mid - 1", "is_blank": false},
  {"text": "    }", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return -1", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["One half is always sorted, even in a rotated array.", "Identify which half is sorted using nums[left] <= nums[mid].", "Check if target falls in the sorted half. If yes search there, otherwise search the other half."]',
'One half is always sorted. If left half is sorted (nums[left] <= nums[mid]) check if target is in that range. If so, search left. Otherwise search right. Same logic applies to right half.',
'function search(nums, target) {
  return nums.indexOf(target)
}',
'function search(nums, target) {
  let left = 0, right = nums.length - 1
  while (left <= right) {
    const mid = Math.floor((left + right) / 2)
    if (nums[mid] === target) return mid
    if (nums[left] <= nums[mid]) {
      if (target >= nums[left] && target < nums[mid]) right = mid - 1
      else left = mid + 1
    } else {
      if (target > nums[mid] && target <= nums[right]) left = mid + 1
      else right = mid - 1
    }
  }
  return -1
}',
'O(n) time · O(1) space', 'O(log n) time · O(1) space',
'["Find minimum in rotated array", "Binary search", "Find peak element"]'),

('Koko Eating Bananas', 'Google', 'Google L5', 'Binary Search', 'a1b2c3d4-0000-0000-0000-000000000007', 2,
'[
  {"text": "function minEatingSpeed(piles, h) {", "is_blank": false},
  {"text": "  let left = 1, right = Math.max(...piles)", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  while (left < right) {", "is_blank": false},
  {"text": "    const mid = Math.floor((left + right) / 2)", "is_blank": false},
  {"text": "    const hours = piles.reduce((s, p) => s + Math.ceil(p / mid), 0)", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "if (hours <= h) right = mid"},
  {"text": "    else left = mid + 1", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return left", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Binary search on the answer — search speed values not the array.", "If Koko can finish at speed mid, maybe she can go slower. Search left.", "If she cannot finish, she must go faster. Search right."]',
'Binary search on the speed value. If mid speed is enough (hours <= h), the answer could be mid or smaller so set right = mid. Otherwise we need a faster speed so set left = mid + 1.',
'function minEatingSpeed(piles, h) {
  for (let k = 1; k <= Math.max(...piles); k++) {
    const hours = piles.reduce((s, p) => s + Math.ceil(p / k), 0)
    if (hours <= h) return k
  }
}',
'function minEatingSpeed(piles, h) {
  let left = 1, right = Math.max(...piles)
  while (left < right) {
    const mid = Math.floor((left + right) / 2)
    const hours = piles.reduce((s, p) => s + Math.ceil(p / mid), 0)
    if (hours <= h) right = mid
    else left = mid + 1
  }
  return left
}',
'O(n · max(piles)) time · O(1) space', 'O(n log m) time · O(1) space',
'["Find minimum in rotated array", "Capacity to ship packages", "Split array largest sum"]'),

('First Bad Version', 'Meta', 'Meta E3', 'Binary Search', 'a1b2c3d4-0000-0000-0000-000000000007', 1,
'[
  {"text": "function solution(isBadVersion) {", "is_blank": false},
  {"text": "  return function(n) {", "is_blank": false},
  {"text": "    let left = 1, right = n", "is_blank": false},
  {"text": "    while (left < right) {", "is_blank": false},
  {"text": "      const mid = Math.floor((left + right) / 2)", "is_blank": false},
  {"text": "      ______", "is_blank": true, "blank_answer": "if (isBadVersion(mid)) right = mid"},
  {"text": "      else left = mid + 1", "is_blank": false},
  {"text": "    }", "is_blank": false},
  {"text": "    return left", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["If mid is bad, the first bad version is mid or earlier.", "If mid is good, the first bad version must be after mid.", "We want the leftmost bad version — set right = mid (not mid - 1) to keep it in range."]',
'If mid is bad, the first bad could be mid itself or earlier, so right = mid. If mid is good, first bad must be after, so left = mid + 1. Loop ends when left === right — that is the first bad version.',
'function solution(isBadVersion) {
  return function(n) {
    for (let i = 1; i <= n; i++)
      if (isBadVersion(i)) return i
  }
}',
'function solution(isBadVersion) {
  return function(n) {
    let left = 1, right = n
    while (left < right) {
      const mid = Math.floor((left + right) / 2)
      if (isBadVersion(mid)) right = mid
      else left = mid + 1
    }
    return left
  }
}',
'O(n) time · O(1) space', 'O(log n) time · O(1) space',
'["Binary search", "Search insert position", "Find peak element"]'),

('Search a 2D Matrix', 'Amazon', 'Amazon SDE2', 'Binary Search', 'a1b2c3d4-0000-0000-0000-000000000007', 2,
'[
  {"text": "function searchMatrix(matrix, target) {", "is_blank": false},
  {"text": "  const m = matrix.length, n = matrix[0].length", "is_blank": false},
  {"text": "  let left = 0, right = m * n - 1", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  while (left <= right) {", "is_blank": false},
  {"text": "    const mid = Math.floor((left + right) / 2)", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "const val = matrix[Math.floor(mid / n)][mid % n]"},
  {"text": "    if (val === target) return true", "is_blank": false},
  {"text": "    else if (val < target) left = mid + 1", "is_blank": false},
  {"text": "    else right = mid - 1", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return false", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Treat the 2D matrix as a 1D sorted array.", "Map 1D index to 2D: row = mid / n, col = mid % n.", "Then apply standard binary search."]',
'Flatten the 2D matrix conceptually into 1D. Index mid maps to row = Math.floor(mid / n) and col = mid % n. Then standard binary search applies.',
'function searchMatrix(matrix, target) {
  for (const row of matrix)
    if (row.includes(target)) return true
  return false
}',
'function searchMatrix(matrix, target) {
  const m = matrix.length, n = matrix[0].length
  let left = 0, right = m * n - 1
  while (left <= right) {
    const mid = Math.floor((left + right) / 2)
    const val = matrix[Math.floor(mid / n)][mid % n]
    if (val === target) return true
    else if (val < target) left = mid + 1
    else right = mid - 1
  }
  return false
}',
'O(m·n) time · O(1) space', 'O(log(m·n)) time · O(1) space',
'["Binary search", "Search in rotated sorted array", "Find minimum in rotated array"]');


-- ─────────────────────────────────────────────────────────────────────────────
-- HASH MAP (6 problems)
-- ─────────────────────────────────────────────────────────────────────────────

insert into problems (title, company, company_badge, pattern, pattern_id, difficulty, code_lines, hints, explanation, brute_force, optimised, brute_complexity, optimised_complexity, related_patterns) values

('Two Sum', 'Google', 'Google L3', 'Hash Map', 'a1b2c3d4-0000-0000-0000-000000000009', 1,
'[
  {"text": "function twoSum(nums, target) {", "is_blank": false},
  {"text": "  const map = {}", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let i = 0; i < nums.length; i++) {", "is_blank": false},
  {"text": "    const complement = target - nums[i]", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "if (complement in map) return [map[complement], i]"},
  {"text": "    map[nums[i]] = i", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["For each element, you need its complement (target - nums[i]).", "Check if the complement was already seen.", "If found, return both indices. Otherwise store current element."]',
'For each element compute its complement. Check the map for the complement before storing the current element. This ensures we never pair an element with itself.',
'function twoSum(nums, target) {
  for (let i = 0; i < nums.length; i++)
    for (let j = i + 1; j < nums.length; j++)
      if (nums[i] + nums[j] === target) return [i, j]
}',
'function twoSum(nums, target) {
  const map = {}
  for (let i = 0; i < nums.length; i++) {
    const complement = target - nums[i]
    if (complement in map) return [map[complement], i]
    map[nums[i]] = i
  }
}',
'O(n²) time · O(1) space', 'O(n) time · O(n) space',
'["Two Sum II", "3Sum", "Subarray sum equals K"]'),

('Valid Anagram', 'Amazon', 'Amazon SDE1', 'Hash Map', 'a1b2c3d4-0000-0000-0000-000000000009', 1,
'[
  {"text": "function isAnagram(s, t) {", "is_blank": false},
  {"text": "  if (s.length !== t.length) return false", "is_blank": false},
  {"text": "  const count = {}", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (const c of s) count[c] = (count[c] || 0) + 1", "is_blank": false},
  {"text": "  for (const c of t) {", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "if (!count[c]) return false"},
  {"text": "    count[c]--", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return true", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Count character frequencies in s.", "Decrement counts for characters in t.", "If a character in t is not in s (count is 0 or missing), return false immediately."]',
'Count all characters in s. Then for each character in t, check it exists in the count map before decrementing. If count is 0 or missing, t has a character not in s — not an anagram.',
'function isAnagram(s, t) {
  return s.split("").sort().join("") === t.split("").sort().join("")
}',
'function isAnagram(s, t) {
  if (s.length !== t.length) return false
  const count = {}
  for (const c of s) count[c] = (count[c] || 0) + 1
  for (const c of t) {
    if (!count[c]) return false
    count[c]--
  }
  return true
}',
'O(n log n) time · O(1) space', 'O(n) time · O(n) space',
'["Group anagrams", "Find all anagrams in string", "Two Sum"]'),

('Group Anagrams', 'Meta', 'Meta E4', 'Hash Map', 'a1b2c3d4-0000-0000-0000-000000000009', 2,
'[
  {"text": "function groupAnagrams(strs) {", "is_blank": false},
  {"text": "  const map = new Map()", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (const str of strs) {", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "const key = str.split(\"\").sort().join(\"\")"},
  {"text": "    if (!map.has(key)) map.set(key, [])", "is_blank": false},
  {"text": "    map.get(key).push(str)", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  return [...map.values()]", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Anagrams have the same characters — use that as a key.", "Sorting a string gives a canonical form for all its anagrams.", "Use the sorted string as the map key, group original strings under it."]',
'Sort each string to get a canonical key shared by all its anagrams. Use that sorted string as the map key and collect original strings in a list under it.',
'function groupAnagrams(strs) {
  const result = []
  const used = new Set()
  for (let i = 0; i < strs.length; i++) {
    if (used.has(i)) continue
    const group = [strs[i]]
    for (let j = i + 1; j < strs.length; j++) {
      if (strs[i].split("").sort().join("") === strs[j].split("").sort().join("")) {
        group.push(strs[j])
        used.add(j)
      }
    }
    result.push(group)
  }
  return result
}',
'function groupAnagrams(strs) {
  const map = new Map()
  for (const str of strs) {
    const key = str.split("").sort().join("")
    if (!map.has(key)) map.set(key, [])
    map.get(key).push(str)
  }
  return [...map.values()]
}',
'O(n² · k log k) time', 'O(n · k log k) time · O(n) space',
'["Valid anagram", "Find all anagrams in string", "Minimum window substring"]'),

('Longest Consecutive Sequence', 'Google', 'Google L5', 'Hash Map', 'a1b2c3d4-0000-0000-0000-000000000009', 2,
'[
  {"text": "function longestConsecutive(nums) {", "is_blank": false},
  {"text": "  const set = new Set(nums)", "is_blank": false},
  {"text": "  let max = 0", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (const num of set) {", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "if (!set.has(num - 1)) {"},
  {"text": "      let curr = num, len = 1", "is_blank": false},
  {"text": "      while (set.has(curr + 1)) { curr++; len++ }", "is_blank": false},
  {"text": "      max = Math.max(max, len)", "is_blank": false},
  {"text": "    }", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return max", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Only start counting from the beginning of a sequence.", "A sequence start has no num - 1 in the set.", "This avoids recounting sequences we already counted."]',
'Only start expanding a sequence when num - 1 is not in the set — this is the sequence start. Expanding from every number would give O(n²). Starting only from sequence beginnings gives O(n).',
'function longestConsecutive(nums) {
  nums.sort((a, b) => a - b)
  let max = 1, curr = 1
  for (let i = 1; i < nums.length; i++) {
    if (nums[i] === nums[i-1] + 1) max = Math.max(max, ++curr)
    else if (nums[i] !== nums[i-1]) curr = 1
  }
  return max
}',
'function longestConsecutive(nums) {
  const set = new Set(nums)
  let max = 0
  for (const num of set) {
    if (!set.has(num - 1)) {
      let curr = num, len = 1
      while (set.has(curr + 1)) { curr++; len++ }
      max = Math.max(max, len)
    }
  }
  return max
}',
'O(n log n) time · O(1) space', 'O(n) time · O(n) space',
'["Two Sum", "Missing number", "Find all duplicates"]'),

('Subarray Sum Equals K', 'Meta', 'Meta E5', 'Hash Map', 'a1b2c3d4-0000-0000-0000-000000000009', 3,
'[
  {"text": "function subarraySum(nums, k) {", "is_blank": false},
  {"text": "  const map = {0: 1}", "is_blank": false},
  {"text": "  let sum = 0, count = 0", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (const num of nums) {", "is_blank": false},
  {"text": "    sum += num", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "count += map[sum - k] || 0"},
  {"text": "    map[sum] = (map[sum] || 0) + 1", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return count", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Use prefix sums. Sum of subarray [i+1..j] = prefixSum[j] - prefixSum[i].", "If prefixSum[j] - k exists in the map, we found a valid subarray.", "Add map[sum - k] to count before updating the map."]',
'If current prefix sum minus k was seen before, the subarray between that earlier index and current index sums to k. Count how many times that prefix sum appeared — each occurrence is a valid subarray.',
'function subarraySum(nums, k) {
  let count = 0
  for (let i = 0; i < nums.length; i++) {
    let sum = 0
    for (let j = i; j < nums.length; j++) {
      sum += nums[j]
      if (sum === k) count++
    }
  }
  return count
}',
'function subarraySum(nums, k) {
  const map = {0: 1}
  let sum = 0, count = 0
  for (const num of nums) {
    sum += num
    count += map[sum - k] || 0
    map[sum] = (map[sum] || 0) + 1
  }
  return count
}',
'O(n²) time · O(1) space', 'O(n) time · O(n) space',
'["Two Sum", "Longest consecutive sequence", "Continuous subarray sum"]'),

('Top K Frequent Elements', 'Amazon', 'Amazon L4', 'Hash Map', 'a1b2c3d4-0000-0000-0000-000000000009', 2,
'[
  {"text": "function topKFrequent(nums, k) {", "is_blank": false},
  {"text": "  const freq = {}", "is_blank": false},
  {"text": "  const bucket = Array.from({length: nums.length + 1}, () => [])", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (const n of nums) freq[n] = (freq[n] || 0) + 1", "is_blank": false},
  {"text": "  for (const [num, count] of Object.entries(freq)) {", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "bucket[count].push(Number(num))"},
  {"text": "  }", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  const result = []", "is_blank": false},
  {"text": "  for (let i = bucket.length - 1; i >= 0 && result.length < k; i--) {", "is_blank": false},
  {"text": "    result.push(...bucket[i])", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return result.slice(0, k)", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Bucket sort by frequency — frequency cannot exceed nums.length.", "Create buckets indexed by frequency.", "Iterate buckets from highest frequency down, collect until you have k elements."]',
'Bucket sort by frequency. Since max frequency is nums.length, create that many buckets. Place each number in the bucket matching its frequency. Read from highest bucket down to get top k.',
'function topKFrequent(nums, k) {
  const freq = {}
  for (const n of nums) freq[n] = (freq[n] || 0) + 1
  return Object.entries(freq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, k)
    .map(e => Number(e[0]))
}',
'function topKFrequent(nums, k) {
  const freq = {}
  const bucket = Array.from({length: nums.length + 1}, () => [])
  for (const n of nums) freq[n] = (freq[n] || 0) + 1
  for (const [num, count] of Object.entries(freq)) bucket[count].push(Number(num))
  const result = []
  for (let i = bucket.length - 1; i >= 0 && result.length < k; i--) result.push(...bucket[i])
  return result.slice(0, k)
}',
'O(n log n) time · O(n) space', 'O(n) time · O(n) space',
'["Two Sum", "Sort characters by frequency", "Kth largest element"]');


-- ─────────────────────────────────────────────────────────────────────────────
-- DYNAMIC PROGRAMMING (6 problems)
-- ─────────────────────────────────────────────────────────────────────────────

insert into problems (title, company, company_badge, pattern, pattern_id, difficulty, code_lines, hints, explanation, brute_force, optimised, brute_complexity, optimised_complexity, related_patterns) values

('Climbing Stairs', 'Amazon', 'Amazon SDE1', 'Dynamic Programming', 'a1b2c3d4-0000-0000-0000-000000000008', 1,
'[
  {"text": "function climbStairs(n) {", "is_blank": false},
  {"text": "  if (n <= 2) return n", "is_blank": false},
  {"text": "  let prev = 1, curr = 2", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let i = 3; i <= n; i++) {", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "[prev, curr] = [curr, prev + curr]"},
  {"text": "  }", "is_blank": false},
  {"text": "  return curr", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["Ways to reach step n = ways to reach step n-1 + ways to reach step n-2.", "This is Fibonacci. You only need the last two values.", "Update both in one destructuring assignment."]',
'To reach step n you can come from n-1 (one step) or n-2 (two steps). This recurrence is exactly Fibonacci. Only store the last two values — no array needed.',
'function climbStairs(n) {
  if (n <= 1) return 1
  return climbStairs(n - 1) + climbStairs(n - 2)
}',
'function climbStairs(n) {
  if (n <= 2) return n
  let prev = 1, curr = 2
  for (let i = 3; i <= n; i++) {
    [prev, curr] = [curr, prev + curr]
  }
  return curr
}',
'O(2ⁿ) time · O(n) space', 'O(n) time · O(1) space',
'["House robber", "Min cost climbing stairs", "Fibonacci number"]'),

('House Robber', 'Amazon', 'Amazon SDE2', 'Dynamic Programming', 'a1b2c3d4-0000-0000-0000-000000000008', 2,
'[
  {"text": "function rob(nums) {", "is_blank": false},
  {"text": "  let prev = 0, curr = 0", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (const num of nums) {", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "[prev, curr] = [curr, Math.max(curr, prev + num)]"},
  {"text": "  }", "is_blank": false},
  {"text": "  return curr", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["At each house: rob it (prev + num) or skip it (curr).", "Take the max of those two options.", "Only need last two values — no array needed."]',
'At each house the best you can do is max(skip this house = curr, rob this house = prev + num). Roll forward: prev becomes the old curr, curr becomes the new max.',
'function rob(nums) {
  const memo = {}
  function dp(i) {
    if (i >= nums.length) return 0
    if (i in memo) return memo[i]
    return memo[i] = Math.max(dp(i + 1), nums[i] + dp(i + 2))
  }
  return dp(0)
}',
'function rob(nums) {
  let prev = 0, curr = 0
  for (const num of nums) {
    [prev, curr] = [curr, Math.max(curr, prev + num)]
  }
  return curr
}',
'O(n) time · O(n) space', 'O(n) time · O(1) space',
'["Climbing stairs", "House robber II", "Delete and earn"]'),

('Coin Change', 'Amazon', 'Amazon L5', 'Dynamic Programming', 'a1b2c3d4-0000-0000-0000-000000000008', 2,
'[
  {"text": "function coinChange(coins, amount) {", "is_blank": false},
  {"text": "  const dp = new Array(amount + 1).fill(Infinity)", "is_blank": false},
  {"text": "  dp[0] = 0", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let i = 1; i <= amount; i++) {", "is_blank": false},
  {"text": "    for (const coin of coins) {", "is_blank": false},
  {"text": "      ______", "is_blank": true, "blank_answer": "if (i >= coin) dp[i] = Math.min(dp[i], dp[i - coin] + 1)"},
  {"text": "    }", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return dp[amount] === Infinity ? -1 : dp[amount]", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["dp[i] = minimum coins to make amount i.", "For each coin, if i >= coin we can use it: dp[i] = min(dp[i], dp[i - coin] + 1).", "Initialize dp[0] = 0, rest Infinity. Guard with i >= coin check."]',
'Build up from dp[0] = 0. For each amount i and each coin, if the coin fits (i >= coin), check if using that coin gives fewer total coins than current best. Guard prevents negative index access.',
'function coinChange(coins, amount) {
  function dp(rem) {
    if (rem < 0) return -1
    if (rem === 0) return 0
    let min = Infinity
    for (const coin of coins) {
      const res = dp(rem - coin)
      if (res >= 0) min = Math.min(min, res + 1)
    }
    return min === Infinity ? -1 : min
  }
  return dp(amount)
}',
'function coinChange(coins, amount) {
  const dp = new Array(amount + 1).fill(Infinity)
  dp[0] = 0
  for (let i = 1; i <= amount; i++)
    for (const coin of coins)
      if (i >= coin) dp[i] = Math.min(dp[i], dp[i - coin] + 1)
  return dp[amount] === Infinity ? -1 : dp[amount]
}',
'O(Sⁿ) time exponential', 'O(S·n) time · O(S) space',
'["Climbing stairs", "Perfect squares", "Minimum cost for tickets"]'),

('Longest Increasing Subsequence', 'Google', 'Google L5', 'Dynamic Programming', 'a1b2c3d4-0000-0000-0000-000000000008', 2,
'[
  {"text": "function lengthOfLIS(nums) {", "is_blank": false},
  {"text": "  const dp = new Array(nums.length).fill(1)", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let i = 1; i < nums.length; i++) {", "is_blank": false},
  {"text": "    for (let j = 0; j < i; j++) {", "is_blank": false},
  {"text": "      ______", "is_blank": true, "blank_answer": "if (nums[j] < nums[i]) dp[i] = Math.max(dp[i], dp[j] + 1)"},
  {"text": "    }", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  return Math.max(...dp)", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["dp[i] = length of longest increasing subsequence ending at index i.", "For each j < i, if nums[j] < nums[i], we can extend the subsequence ending at j.", "dp[i] = max(dp[i], dp[j] + 1) for all valid j."]',
'dp[i] is the LIS ending at index i. For every j before i where nums[j] < nums[i], we can extend the subsequence ending at j by appending nums[i]. Take the maximum.',
'function lengthOfLIS(nums) {
  function dp(i, prev) {
    if (i === nums.length) return 0
    let skip = dp(i + 1, prev)
    let take = nums[i] > prev ? 1 + dp(i + 1, nums[i]) : 0
    return Math.max(skip, take)
  }
  return dp(0, -Infinity)
}',
'function lengthOfLIS(nums) {
  const dp = new Array(nums.length).fill(1)
  for (let i = 1; i < nums.length; i++)
    for (let j = 0; j < i; j++)
      if (nums[j] < nums[i]) dp[i] = Math.max(dp[i], dp[j] + 1)
  return Math.max(...dp)
}',
'O(2ⁿ) time exponential', 'O(n²) time · O(n) space',
'["Longest common subsequence", "Russian doll envelopes", "Number of LIS"]'),

('Maximum Product Subarray', 'Amazon', 'Amazon L4', 'Dynamic Programming', 'a1b2c3d4-0000-0000-0000-000000000008', 2,
'[
  {"text": "function maxProduct(nums) {", "is_blank": false},
  {"text": "  let max = nums[0], min = nums[0], result = nums[0]", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let i = 1; i < nums.length; i++) {", "is_blank": false},
  {"text": "    const temp = max", "is_blank": false},
  {"text": "    ______", "is_blank": true, "blank_answer": "max = Math.max(nums[i], max * nums[i], min * nums[i])"},
  {"text": "    min = Math.min(nums[i], temp * nums[i], min * nums[i])", "is_blank": false},
  {"text": "    result = Math.max(result, max)", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return result", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["A negative times a negative becomes positive — track both max and min.", "At each step: new max = max of (num alone, max*num, min*num).", "Use temp to save old max before overwriting it for min calculation."]',
'Track both running max and min because a large negative * negative = large positive. At each step consider starting fresh (nums[i] alone), extending max product, or extending min product (two negatives).',
'function maxProduct(nums) {
  let result = nums[0]
  for (let i = 0; i < nums.length; i++) {
    let prod = 1
    for (let j = i; j < nums.length; j++) {
      prod *= nums[j]
      result = Math.max(result, prod)
    }
  }
  return result
}',
'function maxProduct(nums) {
  let max = nums[0], min = nums[0], result = nums[0]
  for (let i = 1; i < nums.length; i++) {
    const temp = max
    max = Math.max(nums[i], max * nums[i], min * nums[i])
    min = Math.min(nums[i], temp * nums[i], min * nums[i])
    result = Math.max(result, max)
  }
  return result
}',
'O(n²) time · O(1) space', 'O(n) time · O(1) space',
'["Maximum subarray", "House robber", "Coin change"]'),

('Word Break', 'Google', 'Google L4', 'Dynamic Programming', 'a1b2c3d4-0000-0000-0000-000000000008', 3,
'[
  {"text": "function wordBreak(s, wordDict) {", "is_blank": false},
  {"text": "  const set = new Set(wordDict)", "is_blank": false},
  {"text": "  const dp = new Array(s.length + 1).fill(false)", "is_blank": false},
  {"text": "  dp[0] = true", "is_blank": false},
  {"text": "", "is_blank": false},
  {"text": "  for (let i = 1; i <= s.length; i++) {", "is_blank": false},
  {"text": "    for (let j = 0; j < i; j++) {", "is_blank": false},
  {"text": "      ______", "is_blank": true, "blank_answer": "if (dp[j] && set.has(s.slice(j, i))) { dp[i] = true; break }"},
  {"text": "    }", "is_blank": false},
  {"text": "  }", "is_blank": false},
  {"text": "  return dp[s.length]", "is_blank": false},
  {"text": "}", "is_blank": false}
]',
'["dp[i] = can string s[0..i] be segmented using wordDict.", "For each i, check all j < i: if dp[j] is true and s[j..i] is a word, then dp[i] is true.", "Break early once dp[i] is set to true."]',
'dp[i] means s[0..i] can be segmented. For each position i, scan all j before it. If dp[j] is true (s[0..j] is valid) and s[j..i] is in the dictionary, then dp[i] is also true.',
'function wordBreak(s, wordDict) {
  const set = new Set(wordDict)
  function dp(i) {
    if (i === s.length) return true
    for (let j = i + 1; j <= s.length; j++)
      if (set.has(s.slice(i, j)) && dp(j)) return true
    return false
  }
  return dp(0)
}',
'function wordBreak(s, wordDict) {
  const set = new Set(wordDict)
  const dp = new Array(s.length + 1).fill(false)
  dp[0] = true
  for (let i = 1; i <= s.length; i++)
    for (let j = 0; j < i; j++)
      if (dp[j] && set.has(s.slice(j, i))) { dp[i] = true; break }
  return dp[s.length]
}',
'O(2ⁿ) time exponential', 'O(n²) time · O(n) space',
'["Coin change", "Longest increasing subsequence", "Palindrome partitioning"]');
