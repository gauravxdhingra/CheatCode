-- Add problem_statement column
alter table problems add column if not exists problem_statement text default '';

-- Sliding Window
update problems set problem_statement = 'Given an array of integers and a number k, find the maximum sum of any contiguous subarray of size k.' where title = 'Max Sum Subarray of Size K';
update problems set problem_statement = 'Given a string s, find the length of the longest substring without repeating characters.' where title = 'Longest Substring Without Repeating Chars';
update problems set problem_statement = 'Given an integer array nums and integer k, find the contiguous subarray of length k with the maximum average value and return that value.' where title = 'Maximum Average Subarray I';
update problems set problem_statement = 'Given an array of positive integers nums and a positive integer target, return the minimal length of a subarray whose sum is greater than or equal to target. Return 0 if no such subarray exists.' where title = 'Minimum Size Subarray Sum';
update problems set problem_statement = 'Given a binary array nums, you may delete one element from it. Return the size of the longest non-empty subarray containing only 1s after the deletion.' where title = 'Longest Subarray with Ones after Deletion';
update problems set problem_statement = 'Given an array arr, an integer k, and a threshold, return the number of subarrays of size k and average greater than or equal to threshold.' where title = 'Number of Subarrays of Size K and Average >= Threshold';

-- Two Pointer
update problems set problem_statement = 'Given a 1-indexed sorted array of integers numbers, find two numbers that add up to target. Return their indices as [index1, index2]. Must use O(1) extra space.' where title = 'Two Sum II — Sorted Array';
update problems set problem_statement = 'A phrase is a palindrome if, after removing all non-alphanumeric characters and ignoring case, it reads the same forward and backward. Given a string s, return true if it is a palindrome.' where title = 'Valid Palindrome';
update problems set problem_statement = 'Given n non-negative integers representing heights of vertical lines, find two lines that together with the x-axis forms a container that holds the most water.' where title = 'Container With Most Water';
update problems set problem_statement = 'Given an integer array nums, return all triplets [nums[i], nums[j], nums[k]] such that i != j != k and nums[i] + nums[j] + nums[k] == 0. The solution set must not contain duplicate triplets.' where title = '3Sum';
update problems set problem_statement = 'Given an integer array nums, move all 0s to the end while maintaining the relative order of non-zero elements. Do this in-place.' where title = 'Move Zeroes';
update problems set problem_statement = 'Given n non-negative integers representing an elevation map where the width of each bar is 1, compute how much water it can trap after raining.' where title = 'Trapping Rain Water';

-- Binary Search
update problems set problem_statement = 'Given an array of integers nums sorted in ascending order and an integer target, write a function to search target in nums. Return the index if found, otherwise return -1.' where title = 'Binary Search';
update problems set problem_statement = 'Suppose an array of length n sorted in ascending order is rotated between 1 and n times. Given the rotated array nums, return the minimum element.' where title = 'Find Minimum in Rotated Sorted Array';
update problems set problem_statement = 'Given a sorted array rotated at some unknown pivot and an integer target, return the index of target if it is in the array, or -1 otherwise.' where title = 'Search in Rotated Sorted Array';
update problems set problem_statement = 'Koko loves eating bananas. Given piles of bananas and h hours, find the minimum integer eating speed k such that she can eat all bananas within h hours.' where title = 'Koko Eating Bananas';
update problems set problem_statement = 'You are a product manager with n products versioned 1 to n. You know that there is a first bad version which causes all following versions to be bad. Find the first bad version using minimum API calls.' where title = 'First Bad Version';
update problems set problem_statement = 'Write an efficient algorithm to search for a value target in an m x n integer matrix. The matrix has integers sorted left to right in each row, and each row starts with a value greater than the last row.' where title = 'Search a 2D Matrix';

-- Hash Map
update problems set problem_statement = 'Given an array of integers nums and a target integer, return the indices of the two numbers that add up to target. Assume exactly one solution exists.' where title = 'Two Sum';
update problems set problem_statement = 'Given two strings s and t, return true if t is an anagram of s and false otherwise. An anagram uses all the original letters exactly once.' where title = 'Valid Anagram';
update problems set problem_statement = 'Given an array of strings strs, group the anagrams together. You can return the answer in any order.' where title = 'Group Anagrams';
update problems set problem_statement = 'Given an unsorted array of integers nums, return the length of the longest consecutive elements sequence. Must run in O(n) time.' where title = 'Longest Consecutive Sequence';
update problems set problem_statement = 'Given an array of integers nums and an integer k, return the total number of subarrays whose sum equals k.' where title = 'Subarray Sum Equals K';
update problems set problem_statement = 'Given an integer array nums and an integer k, return the k most frequent elements. You may return the answer in any order.' where title = 'Top K Frequent Elements';

-- Dynamic Programming
update problems set problem_statement = 'You are climbing a staircase. It takes n steps to reach the top. Each time you can climb 1 or 2 steps. In how many distinct ways can you climb to the top?' where title = 'Climbing Stairs';
update problems set problem_statement = 'You are a robber planning to rob houses along a street. Adjacent houses have a security system. Given an integer array nums, return the maximum amount you can rob without alerting the police.' where title = 'House Robber';
update problems set problem_statement = 'You are given coins of different denominations and a total amount. Return the fewest number of coins needed to make up that amount, or -1 if it cannot be done.' where title = 'Coin Change';
update problems set problem_statement = 'Given an integer array nums, return the length of the longest strictly increasing subsequence.' where title = 'Longest Increasing Subsequence';
update problems set problem_statement = 'Given an integer array nums, find a contiguous subarray that has the largest product and return the product.' where title = 'Maximum Product Subarray';
update problems set problem_statement = 'Given a string s and a dictionary of strings wordDict, return true if s can be segmented into a space-separated sequence of one or more dictionary words.' where title = 'Word Break';
