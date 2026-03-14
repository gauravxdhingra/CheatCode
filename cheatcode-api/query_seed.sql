-- STEP 1: Core tables

create extension if not exists "uuid-ossp";

create table users (
  id uuid primary key default uuid_generate_v4(),
  email text unique not null,
  role text not null default 'student' check (role in ('student', 'professional', 'competitive')),
  streak int not null default 0,
  solved_today int not null default 0,
  last_active_date date,
  interview_date date,
  created_at timestamptz not null default now()
);

create table patterns (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  description text,
  related_problems jsonb default '[]',
  created_at timestamptz not null default now()
);

create table problems (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  company text not null,
  company_badge text not null,
  pattern text not null,
  pattern_id uuid references patterns(id),
  difficulty int not null check (difficulty in (1, 2, 3)),
  code_lines jsonb not null default '[]',
  hints jsonb not null default '[]',
  explanation text not null,
  brute_force text not null,
  optimised text not null,
  brute_complexity text not null,
  optimised_complexity text not null,
  related_patterns jsonb default '[]',
  active bool not null default true,
  created_at timestamptz not null default now()
);

create table user_problem_state (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users(id) on delete cascade,
  problem_id uuid references problems(id) on delete cascade,
  status text not null default 'unseen' check (status in ('unseen','skipped','attempted','solved','vaulted')),
  attempts int not null default 0,
  hints_used int not null default 0,
  time_to_solve int, -- seconds
  solved_at timestamptz,
  created_at timestamptz not null default now(),
  unique(user_id, problem_id)
);

create table user_pattern_progress (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users(id) on delete cascade,
  pattern_id uuid references patterns(id) on delete cascade,
  times_encountered int not null default 0,
  times_solved int not null default 0,
  owned bool not null default false,
  last_seen_at date,
  unique(user_id, pattern_id)
);


-- STEP 2: Indexes for performance

create index idx_user_problem_state_user on user_problem_state(user_id);
create index idx_user_problem_state_status on user_problem_state(user_id, status);
create index idx_user_pattern_progress_user on user_pattern_progress(user_id);
create index idx_problems_active_difficulty on problems(active, difficulty);


-- STEP 3: Seed patterns

insert into patterns (id, name, description) values
  ('a1b2c3d4-0000-0000-0000-000000000001', 'Sliding Window', 'Maintain a window that slides across the data. Add incoming element, remove outgoing element. Avoids recomputation.'),
  ('a1b2c3d4-0000-0000-0000-000000000002', 'Two Pointer', 'Use two indices moving toward or away from each other to solve problems in O(n).'),
  ('a1b2c3d4-0000-0000-0000-000000000003', 'Fast and Slow Pointer', 'Two pointers at different speeds. Classic for cycle detection in linked lists.'),
  ('a1b2c3d4-0000-0000-0000-000000000004', 'Binary Search', 'Eliminate half the search space each step. Works on any monotonic condition.'),
  ('a1b2c3d4-0000-0000-0000-000000000005', 'Dynamic Programming', 'Break problem into overlapping subproblems. Store results to avoid recomputation.');


-- STEP 4: Seed problems

insert into problems (
  title, company, company_badge, pattern, pattern_id, difficulty,
  code_lines, hints, explanation,
  brute_force, optimised, brute_complexity, optimised_complexity,
  related_patterns
) values (
  'Max Sum Subarray of Size K',
  'Amazon',
  'Amazon SDE2',
  'Sliding Window',
  'a1b2c3d4-0000-0000-0000-000000000001',
  2,
  '[
    {"text": "function maxSum(nums, k) {", "is_blank": false},
    {"text": "  let sum = 0, max = 0", "is_blank": false},
    {"text": "", "is_blank": false},
    {"text": "  for (let i = 0; i < k; i++)", "is_blank": false},
    {"text": "    sum += nums[i]", "is_blank": false},
    {"text": "", "is_blank": false},
    {"text": "  max = sum", "is_blank": false},
    {"text": "", "is_blank": false},
    {"text": "  for (let i = k; i < nums.length; i++) {", "is_blank": false},
    {"text": "    sum = sum + nums[i] - ______", "is_blank": true, "blank_answer": "nums[i - k]"},
    {"text": "    max = Math.max(max, sum)", "is_blank": false},
    {"text": "  }", "is_blank": false},
    {"text": "  return max", "is_blank": false},
    {"text": "}", "is_blank": false}
  ]',
  '["Think about what changes between one window and the next.", "Only one element enters and one leaves each step.", "You want to remove nums[i - k] from your running sum."]',
  'When you slide the window right, add the incoming element (nums[i]) and remove the element that just left (nums[i - k]). No nested loop needed.',
  'function maxSum(nums, k) {
  let max = 0
  for (let i = 0; i <= nums.length - k; i++) {
    let sum = 0
    for (let j = i; j < i + k; j++) { sum += nums[j] }
    max = Math.max(max, sum)
  }
  return max
}',
  'function maxSum(nums, k) {
  let sum = 0
  for (let i = 0; i < k; i++) sum += nums[i]
  let max = sum
  for (let i = k; i < nums.length; i++) {
    sum = sum + nums[i] - nums[i - k]
    max = Math.max(max, sum)
  }
  return max
}',
  'O(n·k) time · O(1) space',
  'O(n) time · O(1) space',
  '["Longest substring without repeating chars", "Minimum window substring", "Maximum average subarray"]'
),
(
  'Longest Substring Without Repeating Chars',
  'Google',
  'Google L4',
  'Sliding Window',
  'a1b2c3d4-0000-0000-0000-000000000001',
  2,
  '[
    {"text": "function lengthOfLongestSubstring(s) {", "is_blank": false},
    {"text": "  let set = new Set()", "is_blank": false},
    {"text": "  let left = 0, max = 0", "is_blank": false},
    {"text": "", "is_blank": false},
    {"text": "  for (let right = 0; right < s.length; right++) {", "is_blank": false},
    {"text": "    while (set.has(s[right])) {", "is_blank": false},
    {"text": "      ______", "is_blank": true, "blank_answer": "set.delete(s[left++])"},
    {"text": "    }", "is_blank": false},
    {"text": "    set.add(s[right])", "is_blank": false},
    {"text": "    max = Math.max(max, right - left + 1)", "is_blank": false},
    {"text": "  }", "is_blank": false},
    {"text": "  return max", "is_blank": false},
    {"text": "}", "is_blank": false}
  ]',
  '["Use two pointers: left and right.", "When you see a duplicate at right, move left forward.", "Keep shrinking until the duplicate is gone from the window."]',
  'When a duplicate is found, shrink the window from the left until it is gone. The Set always reflects exactly what is inside the current window.',
  'function lengthOfLongestSubstring(s) {
  let max = 0
  for (let i = 0; i < s.length; i++) {
    let seen = new Set()
    for (let j = i; j < s.length; j++) {
      if (seen.has(s[j])) break
      seen.add(s[j])
      max = Math.max(max, j - i + 1)
    }
  }
  return max
}',
  'function lengthOfLongestSubstring(s) {
  let set = new Set()
  let left = 0, max = 0
  for (let right = 0; right < s.length; right++) {
    while (set.has(s[right])) set.delete(s[left++])
    set.add(s[right])
    max = Math.max(max, right - left + 1)
  }
  return max
}',
  'O(n²) time · O(n) space',
  'O(n) time · O(n) space',
  '["Max sum subarray of size K", "Minimum window substring", "Fruit into baskets"]'
),
(
  'Maximum Average Subarray I',
  'Meta',
  'Meta E4',
  'Sliding Window',
  'a1b2c3d4-0000-0000-0000-000000000001',
  1,
  '[
    {"text": "function findMaxAverage(nums, k) {", "is_blank": false},
    {"text": "  let sum = 0", "is_blank": false},
    {"text": "  for (let i = 0; i < k; i++) sum += nums[i]", "is_blank": false},
    {"text": "", "is_blank": false},
    {"text": "  let maxSum = sum", "is_blank": false},
    {"text": "", "is_blank": false},
    {"text": "  for (let i = k; i < nums.length; i++) {", "is_blank": false},
    {"text": "    sum += ______", "is_blank": true, "blank_answer": "nums[i] - nums[i - k]"},
    {"text": "    maxSum = Math.max(maxSum, sum)", "is_blank": false},
    {"text": "  }", "is_blank": false},
    {"text": "", "is_blank": false},
    {"text": "  return maxSum / k", "is_blank": false},
    {"text": "}", "is_blank": false}
  ]',
  '["The window size is fixed at k throughout.", "What two things change when you move the window one step right?", "Combine adding and removing into a single expression."]',
  'Instead of dividing every window sum by k, track the maximum sum and divide once at the end. The slide adds the new element and removes the oldest in one expression.',
  'function findMaxAverage(nums, k) {
  let max = -Infinity
  for (let i = 0; i <= nums.length - k; i++) {
    let sum = 0
    for (let j = i; j < i + k; j++) sum += nums[j]
    max = Math.max(max, sum / k)
  }
  return max
}',
  'function findMaxAverage(nums, k) {
  let sum = 0
  for (let i = 0; i < k; i++) sum += nums[i]
  let maxSum = sum
  for (let i = k; i < nums.length; i++) {
    sum += nums[i] - nums[i - k]
    maxSum = Math.max(maxSum, sum)
  }
  return maxSum / k
}',
  'O(n·k) time · O(1) space',
  'O(n) time · O(1) space',
  '["Max sum subarray of size K", "Find all anagrams in a string", "Permutation in string"]'
);