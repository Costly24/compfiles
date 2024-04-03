/-
Copyright (c) 2024 The Compfiles Contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: David Renshaw
-/

import Mathlib.Tactic

import ProblemExtraction

problem_file { tags := [.Combinatorics] }

/-!
# International Mathematical Olympiad 1972, Problem 1

Prove that from a set of ten distinct two-digit numbers (in
decimal), it is possible to select two disjoint subsets whose
members have the same sum.
-/

namespace Imo1972P1

open scoped BigOperators

problem imo1972_p1 (S : Finset ℕ)
    (Scard : S.card = 10)
    (Sdigits : ∀ n ∈ S, (Nat.digits 10 n).length = 2) :
    ∃ S1 S2 : Finset ℕ, S1 ⊆ S ∧ S2 ⊆ S ∧
       Disjoint S1 S2 ∧ ∑ n in S1, n = ∑ n in S2, n := by
  -- https://prase.cz/kalva/imo/isoln/isoln721.html
  replace Sdigits : S ⊆ Finset.Ico 10 100 := by
    have one_lt_ten : 1 < 10 := by norm_num
    intro n hn
    have h2 := Sdigits n hn
    have h3 : n < 10 ^ ((Nat.digits 10 n).length) :=
      Nat.lt_base_pow_length_digits one_lt_ten

    have h4 : n ≠ 0 := by rintro rfl; norm_num at h2
    have h5 := Nat.base_pow_length_digits_le _ n one_lt_ten h4
    rw [h2] at h3 h5
    rw [sq] at h5
    have h6 : 10 ≤ n := by omega
    rw [Finset.mem_Ico]
    exact ⟨h6, h3⟩
  have h2 := Finset.card_powerset S
  rw [Scard] at h2
  have h3 : ∀ s ∈ Finset.powerset S, ∑ n in s, n ∈ Finset.range 991 := by
    intro s hs
    have h4 : ∀ n ∈ s, n ≤ 99 := by
      intro n hn
      have h5 : n ∈ Finset.Ico 10 100 := by
        rw [Finset.mem_powerset] at hs
        exact Sdigits (hs hn)
      rw [Finset.mem_Ico] at h5
      omega

    have h5 : ∑ n in s, n ≤ ∑ n in s, 99 := Finset.sum_le_sum h4
    simp only [Finset.sum_const, smul_eq_mul, Scard] at h5
    have h6 : s.card ≤ S.card := by
      rw [Finset.mem_powerset] at hs
      exact Finset.card_le_card hs
    rw [Finset.mem_range]
    omega
  let t : Finset ℕ := Finset.range 991
  have h7 : t.card = 991 := Finset.card_range _
  have h8 : t.card < S.powerset.card := by omega
  have h9 := Finset.exists_ne_map_eq_of_card_lt_of_maps_to h8 h3
  obtain ⟨A, hA, B, hB, hAB1, hAB2⟩ := h9
  let C := A ∩ B
  let A' := A \ C
  let B' := B \ C
  refine ⟨A', B', ?_, ?_, ?_, ?_⟩
  · have h10 : A' ⊆ A := Finset.sdiff_subset _ _
    have h11 : A ⊆ S := by
      intro a ha
      rw [Finset.mem_powerset] at hA
      exact hA ha
    exact h10.trans h11
  · have h10 : B' ⊆ B := Finset.sdiff_subset _ _
    have h11 : B ⊆ S := by
      intro b hb
      rw [Finset.mem_powerset] at hB
      exact hB hb
    exact h10.trans h11
  · rw[Finset.disjoint_iff_ne]
    intro a ha b hb
    aesop
  · have h12 : C ⊆ A := Finset.inter_subset_left _ _
    have h13 : C ⊆ B := Finset.inter_subset_right _ _
    have h14 := Finset.sum_sdiff (f := id) h12
    have h15 := Finset.sum_sdiff (f := id) h13
    unfold_let A' B'
    dsimp at h14 h15
    omega
