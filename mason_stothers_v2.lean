-- the to be Mason-Stother formalization
-- Authors Johannes & Jens

--Defining the gcd
import poly
--import euclidean_domain 
--Need to fix an admit in UFD, for the ...multiset lemma
import unique_factorization_domain
import data.finsupp
import algebraically_closed_field
import poly_over_UFD


noncomputable theory
local infix ^ := monoid.pow
local notation `d[`a`]` := polynomial.derivative a
local notation Σ := finset.sume
local notation Π := finset.prod
local notation `Π₀` := finsupp.prod
local notation `~`a:=polynomial a

open polynomial
open classical
local attribute [instance] prop_decidable


-- TODO: there is some problem with the module instances for module.to_add_comm_group ...
-- force ring.to_add_comm_group to be stronger
attribute [instance] ring.to_add_comm_group

universe u

attribute [instance] field.to_unique_factorization_domain --correct?


variable {β : Type u}
variables [field β]


def polynomial.c_fac (p : polynomial β) : β := some (polynomial_fac p)

def polynomial.factors (p : polynomial β) : multiset (~β) :=
classical.some (some_spec $ polynomial_fac p)

lemma polynomial.factors_irred (p : polynomial β) : ∀x ∈ (p.factors), irreducible x :=
assume x h, ((some_spec $ some_spec $ polynomial_fac p).2 x h).1

lemma polynomial.factors_monic (p : polynomial β) : ∀x ∈ (p.factors), monic x :=
λx h, ((some_spec $ some_spec $ polynomial_fac p).2 x h).2

lemma polynomial.factors_eq (p : polynomial β) : p = C (p.c_fac) * p.factors.prod :=
(some_spec (some_spec ( polynomial_fac p))).1


open classical multiset
section mason_stothers

--It might be good to remove the attribute to domain of integral domain?
def rad (p : polynomial β) : polynomial β :=
p.factors.erase_dup.prod

lemma c_fac_ne_zero_of_ne_zero (f : polynomial β) (h : f ≠ 0) : f.c_fac ≠ 0 :=
begin
  by_contradiction h1,
  simp at h1,
  rw f.factors_eq at h,
  simp * at *,
end

lemma rad_ne_zero {p : polynomial β} : rad p ≠ 0 :=
begin
  rw [rad],
  apply multiset.prod_ne_zero_of_forall_mem_ne_zero,
  intros x h1,
  have h2 : irreducible x,
  {
    rw mem_erase_dup at h1,
    exact p.factors_irred x h1,
  },
  exact h2.1,
end

--naming --Where do we use this?
lemma degree_rad_eq_sum_support_degree {f : polynomial β} :
  degree (rad f) = sum (map degree f.factors.erase_dup) :=
begin 
  rw rad,
  have h1 : finset.prod (to_finset (polynomial.factors f)) id ≠ 0,
    {
      apply polynomial.prod_ne_zero_of_forall_mem_ne_zero,
      intros x h1,
      have : irreducible x,
        {
          rw mem_to_finset at h1,
          exact f.factors_irred x h1,
        },
      exact and.elim_left this,
    },
  rw ←to_finset_val f.factors,
  exact calc degree (prod ((to_finset (polynomial.factors f)).val)) = 
    degree (prod (map id (to_finset (polynomial.factors f)).val)) : by rw map_id_eq
    ... = sum (map degree ((to_finset (polynomial.factors f)).val)) : degree_prod_eq_sum_degree_of_prod_ne_zero h1,
end

private lemma mem_factors_of_mem_factors_sub_factors_erase_dup (f : polynomial β) (x : polynomial β) (h : x ∈ (f.factors)-(f.factors.erase_dup)) :   x ∈ f.factors :=
begin
  have : ((f.factors)-(f.factors.erase_dup)) ≤ f.factors,
    from multiset.sub_le_self _ _,
  exact mem_of_le this h,
end

--naming
lemma prod_pow_min_on_ne_zero {f : polynomial β} :
  ((f.factors)-(f.factors.erase_dup)).prod ≠ 0 :=
begin
  apply multiset.prod_ne_zero_of_forall_mem_ne_zero,
  intros x h,
  have h1 : x ∈ f.factors,
    from mem_factors_of_mem_factors_sub_factors_erase_dup f x h,
  have : irreducible x,
    from f.factors_irred x h1,
  exact this.1,
end


lemma degree_factors_prod_eq_degree_factors_sub_erase_dup_add_degree_rad {f : polynomial β} : 
  degree (f.factors.prod) = degree ((f.factors)-(f.factors.erase_dup)).prod + degree (rad f) :=
begin
  rw [← sub_erase_dup_add_erase_dup_eq f.factors] {occs := occurrences.pos [1]},
  rw [←prod_mul_prod_eq_add_prod],
  apply degree_mul_eq_add_of_mul_ne_zero,
  exact mul_ne_zero prod_pow_min_on_ne_zero rad_ne_zero,
end

lemma ne_zero_of_dvd_ne_zero {γ : Type u}{a b : γ} [comm_semiring γ] (h1 : a ∣ b) (h2 : b ≠ 0) : a ≠ 0 :=
begin
  simp only [has_dvd.dvd] at h1,
  let c := some h1,
  have h3: b = a * c,
  from some_spec h1,
  by_contradiction h4,
  rw not_not at h4,
  rw h4 at h3,
  simp at h3,
  contradiction
end


open polynomial --Why here?

private lemma Mason_Stothers_lemma_aux_1 (f : polynomial β): 
  ∀x ∈ f.factors, x^(count x f.factors - 1) ∣ d[f.factors.prod] :=
begin
  rw [derivative_prod_multiset],
  intros x h,
  apply multiset.dvd_sum,
  intros y hy,
  rw multiset.mem_map at hy,
  rcases hy with ⟨z, hz⟩,
  have : y = d[z] * prod (erase (factors f) z),
    from hz.2.symm,
  subst this,
  apply dvd_mul_of_dvd_right,
  rcases (exists_cons_of_mem hz.1) with ⟨t, ht⟩,
  rw ht,
  by_cases h1 : x = z,
  {
    subst h1,
    simp,
    apply forall_pow_count_dvd_prod,
  },
  {
    simp [count_cons_of_ne h1],
    refine dvd_trans _ (forall_pow_count_dvd_prod t x),
    apply pow_count_sub_one_dvd_pow_count,
  },
end

private lemma count_factors_sub_one (f x : polynomial β) :  (count x f.factors - 1) = count x (factors f - erase_dup (factors f))  :=
begin
  rw count_sub,
  by_cases h1 : x ∈ f.factors,
  {
    have : count x (erase_dup (factors f)) = 1,
    {
      have h2: 0 < count x (erase_dup (factors f)),
      {
        rw [count_pos, mem_erase_dup],
        exact h1
      },
      have h3: count x (erase_dup (factors f)) ≤ 1,
      {
        have : nodup (erase_dup (factors f)),
          from nodup_erase_dup _,
        rw nodup_iff_count_le_one at this,
        exact this x,
      },
      have : 1 ≤ count x (erase_dup (factors f)),
        from h2,
      exact nat.le_antisymm h3 this,
    },
    rw this,
  },
  {
    rw ←count_eq_zero at h1,
    simp *,
  }
end

private lemma Mason_Stothers_lemma_aux_2 (f : polynomial β) (h_dvd : ∀x ∈ f.factors, x^(count x f.factors - 1) ∣ gcd f d[f]): 
  (f.factors - f.factors.erase_dup).prod ∣ gcd f d[f] :=
begin
  apply facs_to_pow_prod_dvd_multiset,
  intros x h,
  have h1 : x ∈ f.factors,
    from mem_factors_of_mem_factors_sub_factors_erase_dup f x h,  
  split,
  {
    exact f.factors_irred x h1,
  },
  split,
  {
    rw ←count_factors_sub_one,
    exact h_dvd x h1,
  },
  {
    intros y hy h2,
    have : y ∈ f.factors,
      from mem_factors_of_mem_factors_sub_factors_erase_dup f y hy,
    have h3: monic x,
      from f.factors_monic x h1,
    have h4: monic y,
      from f.factors_monic y this,   
    rw associated_iff_eq h3 h4, --naming not correct
    exact h2,
  }
end

private lemma degree_factors_prod (f : polynomial β) (h : f ≠ 0): degree (f.factors.prod) = degree f :=
begin
  rw [f.factors_eq] {occs := occurrences.pos [2]},
  rw [degree_mul_eq_add_of_mul_ne_zero, degree_C],
  simp,
  rw ←f.factors_eq,
  exact h,
end


lemma Mason_Stothers_lemma (f : polynomial β) :
  degree f ≤ degree (gcd f (derivative f )) + degree (rad f) := --I made degree radical from this one
begin
  by_cases hf : (f = 0),
  {
    simp [hf, nat.zero_le],
  },
  {
    have h_dvd_der : ∀x ∈ f.factors, x^(count x f.factors - 1) ∣ d[f],
    {
      rw [f.factors_eq] {occs := occurrences.pos [3]},
      rw [derivative_C_mul],
      intros x h,
      apply dvd_mul_of_dvd_right,
      exact Mason_Stothers_lemma_aux_1 f x h,
    },
    have h_dvd_f : ∀x ∈ f.factors, x^(count x f.factors - 1) ∣ f,
    {
      rw [f.factors_eq] {occs := occurrences.pos [3]},
      intros x hx, --We have intros x hx a lot here, duplicate?
      apply dvd_mul_of_dvd_right,
      refine dvd_trans _ (forall_pow_count_dvd_prod _ x), --Duplicate 2 lines with Mason_Stothers_lemma_aux_1
      apply pow_count_sub_one_dvd_pow_count,
    },
    have h_dvd_gcd_f_der : ∀x ∈ f.factors, x^(count x f.factors - 1) ∣ gcd f d[f],
    {
      intros x hx,
      exact gcd_min (h_dvd_f x hx) (h_dvd_der x hx),
    },
    have h_prod_dvd_gcd_f_der : (f.factors - f.factors.erase_dup).prod ∣ gcd f d[f],
      from Mason_Stothers_lemma_aux_2 _ h_dvd_gcd_f_der,
    have h_gcd : gcd f d[f] ≠ 0,
    {
      rw [ne.def, gcd_eq_zero_iff_eq_zero_and_eq_zero],
      simp [hf]
    },
    have h1 : degree ((f.factors - f.factors.erase_dup).prod) ≤ degree (gcd f d[f]),
      from degree_dvd h_prod_dvd_gcd_f_der h_gcd,
    have h2 : degree f = degree ((f.factors)-(f.factors.erase_dup)).prod + degree (rad f),
    {
      rw ←degree_factors_prod,
      exact degree_factors_prod_eq_degree_factors_sub_erase_dup_add_degree_rad,
      exact hf,
    },
    rw h2,
    apply add_le_add_right,
    exact h1,
  }  
end


lemma Mason_Stothers_lemma'
(f : polynomial β) : degree f - degree (gcd f (derivative f )) ≤  degree (rad f) := 
begin
  have h1 : degree f - degree (gcd f (derivative f )) ≤ degree (gcd f (derivative f )) + degree (rad f) - degree (gcd f (derivative f )),
  {
    apply nat.sub_le_sub_right,
    apply Mason_Stothers_lemma,
  },
  have h2 : degree (gcd f d[f]) + degree (rad f) - degree (gcd f d[f]) =  degree (rad f),
  {
    rw [add_comm _ (degree (rad f)), nat.add_sub_assoc, nat.sub_self, nat.add_zero],
    exact nat.le_refl _,
  },
  rw h2 at h1,
  exact h1,
end

lemma eq_zero_of_le_pred {n : ℕ} (h : n ≤ nat.pred n) : n = 0 :=
begin
  cases n,
    simp,
    simp at h,
    have h1 : nat.succ n = n,
    from le_antisymm h (nat.le_succ n),
    have h2 : nat.succ n ≠ n,
    from nat.succ_ne_self n,
    contradiction,
end

lemma derivative_eq_zero_of_dvd_derivative_self {a : polynomial β} (h : a ∣ d[a]) : d[a] = 0 :=
begin
  by_contradiction hc,
  have h1 : degree d[a] ≤ degree a - 1,
  from degree_derivative_le,
  have h2 : degree a ≤ degree d[a],
  from degree_dvd h hc,
  have h3 : degree a = 0,
  {
    have h3 : degree a ≤ degree a - 1,
    from le_trans h2 h1,
    exact eq_zero_of_le_pred h3,
  },
  rw ←is_constant_iff_degree_eq_zero at h3,
  have h5 : d[a] = 0,
  from derivative_eq_zero_of_is_constant h3,
  contradiction,
end

--In MS detailed I call this zero wronskian
lemma derivative_eq_zero_and_derivative_eq_zero_of_rel_prime_of_wron_eq_zero
{a b : polynomial β} 
(h1 : rel_prime a b)
(h2 : d[a] * b - a * d[b] = 0)
: d[a] = 0 ∧  d[b] = 0 := 
begin
  have h3 : d[a] * b = a * d[b],
  {
    exact calc d[a] * b = d[a] * b + (-a * d[b] + a * d[b]) : by simp
    ... = d[a] * b - (a * d[b]) + a * d[b] : by simp [add_assoc]
    ... = 0 + a * d[b] : by rw [h2]
    ... = _ : by simp
  },
  have h4 : a ∣ d[a] * b,
  from dvd.intro _ h3.symm,
  rw mul_comm at h4,
  have h5 : a ∣ d[a],
  exact dvd_of_dvd_mul_of_rel_prime h4 h1,
  have h6 : d[a] = 0,
  from derivative_eq_zero_of_dvd_derivative_self h5,

  --duplication
  rw mul_comm at h3,
  have h7 : b ∣ a * d[b],
  from dvd.intro _ h3,
  have h8 : b ∣ d[b],
  exact dvd_of_dvd_mul_of_rel_prime h7 (rel_prime_comm h1),
  have h9 : d[b] = 0,
  from derivative_eq_zero_of_dvd_derivative_self h8,
  exact ⟨h6, h9⟩,
end

lemma rel_prime_gcd_derivative_gcd_derivative_of_rel_prime {a b : polynomial β} (h : rel_prime a b) : rel_prime (gcd a d[a]) (gcd b d[b]) :=
sorry

lemma degree_gcd_derivative_le_degree {a : polynomial β}: degree (gcd a d[a]) ≤ degree a :=
begin
  by_cases h : (a = 0),
  {
    simp * at *,
  },
  {
    apply degree_gcd_le_left,
    exact h,
  }
end

lemma degree_gcd_derivative_lt_degree_of_degree_ne_zero {a : polynomial β} (h : degree a ≠ 0) (h_char : characteristic_zero β) : degree (gcd a d[a]) < degree a :=
begin
  have h1 : degree (gcd a d[a]) ≤ degree d[a],
  {
    apply degree_dvd,
    apply gcd_right,
    rw [ne.def, derivative_eq_zero_iff_is_constant, is_constant_iff_degree_eq_zero],
    exact h,
    exact h_char,
  },
  have h2 : ∃ n, degree a = nat.succ n,
  from nat.exists_eq_succ_of_ne_zero h,
  let n := some h2,
  have h3 : degree a = nat.succ n,
  from some_spec h2,
  exact calc degree (gcd a d[a]) ≤ degree d[a] : h1
  ... ≤ degree a - 1 : degree_derivative_le
  ... ≤ nat.succ n - 1 : by rw h3
  ... = n : rfl
  ... < nat.succ n : nat.lt_succ_self _
  ... = degree a : eq.symm h3,

end

--We will need extra conditions here
lemma degree_rad_add {a b c : polynomial β}: degree (rad a) + degree (rad b) + degree (rad c) ≤ degree (rad (a * b * c)) :=
begin
  admit,
end

lemma gt_zero_of_ne_zero {n : ℕ} (h : n ≠ 0) : n > 0 :=
begin
  have h1 : ∃ m : ℕ, n = nat.succ m,
  from nat.exists_eq_succ_of_ne_zero h,
  let m := some h1,
  have h2 : n = nat.succ m,
  from some_spec h1,
  rw h2,
  exact nat.zero_lt_succ _,
end

lemma MS_aux_1a {c : polynomial β} (h3 : ¬degree c = 0)(h_char : characteristic_zero β) : 1 ≤ (degree c - degree (gcd c d[c])) :=
begin
  have h4 : degree c - degree (gcd c d[c]) > 0,
  {
    rw [nat.pos_iff_ne_zero, ne.def, nat.sub_eq_zero_iff_le],
    simp,
    exact degree_gcd_derivative_lt_degree_of_degree_ne_zero h3 h_char,
  },
  exact h4,

end

--should be in poly
lemma MS_aux_1b {a b c : polynomial β} (h_char : characteristic_zero β) (h_add : a + b = c)
  (h_constant : ¬(is_constant a ∧ is_constant b ∧ is_constant c)) (h1 : is_constant b)
(h2 : ¬is_constant a) : ¬ is_constant c :=
begin
  rw [is_constant_iff_degree_eq_zero] at *,
  have h3 : c (degree a) ≠ 0,
  {
    rw ← h_add,
    simp,
    have h3 : b (degree a) = 0,
    {
      apply eq_zero_of_gt_degree,
      rw h1,
      exact gt_zero_of_ne_zero h2,
    },
    rw h3,
    simp,
    have h4 : leading_coeff a = 0 ↔ a = 0,
    from leading_coef_eq_zero_iff_eq_zero,
    rw leading_coeff at h4,
    rw h4,
    by_contradiction h5,
    rw h5 at h2,
    simp at h2,
    exact h2,
  },
  have h4 : degree a ≤ degree c,
  from le_degree h3,
  by_contradiction h5,
  rw h5 at h4,
  have : degree a = 0,
  from nat.eq_zero_of_le_zero h4,
  contradiction,     
end

lemma MS_aux_1 {a b c : polynomial β} (h_char : characteristic_zero β) (h_add : a + b = c)
  (h_constant : ¬(is_constant a ∧ is_constant b ∧ is_constant c)) :
  1 ≤ degree b - degree (gcd b d[b]) + (degree c - degree (gcd c d[c])) :=
begin
  by_cases h1 : (is_constant b),
  {
    by_cases h2 : (is_constant a),
    {
      have h3 : is_constant c,
      from is_constant_add h2 h1 h_add,
      simp * at *,
    },
    {
      have h3 : ¬ is_constant c,
      {
        exact MS_aux_1b h_char h_add h_constant h1 h2,
      },
      rw [is_constant_iff_degree_eq_zero] at h3,
      have h4 : 1 ≤ (degree c - degree (gcd c d[c])),
      from MS_aux_1a h3 h_char,
      apply nat.le_trans h4,
      simp,
      exact nat.zero_le _,
    }
  },
  {
    rw [is_constant_iff_degree_eq_zero] at h1,
    have h2 : 1 ≤ degree b - degree (gcd b d[b]),
    from MS_aux_1a h1 h_char,
    apply nat.le_trans h2,
    simp,
    exact nat.zero_le _,
  }

end

--Strong duplication with MS_aux_1
lemma MS_aux_2 {a b c : polynomial β} (h_char : characteristic_zero β) (h_add : a + b = c)
  (h_constant : ¬(is_constant a ∧ is_constant b ∧ is_constant c)) :
   1 ≤ degree (rad a) + (degree c - degree (gcd c d[c])) :=
begin
  by_cases h1 : is_constant b,
  {
    by_cases h2 : is_constant a,
    {
      have h3 : is_constant c,
      from is_constant_add h2 h1 h_add,
      simp * at *,
    },
    {
      have h3 : ¬ is_constant c,
      {
        rw [is_constant_iff_degree_eq_zero] at *,
        have h3 : c (degree a) ≠ 0,
        {
          rw ← h_add,
          simp,
          have h3 : b (degree a) = 0,
          {
            apply eq_zero_of_gt_degree,
            rw h1,
            exact gt_zero_of_ne_zero h2,
          },
          rw h3,
          simp,
          have h4 : leading_coeff a = 0 ↔ a = 0,
          from leading_coef_eq_zero_iff_eq_zero,
          rw leading_coeff at h4,
          rw h4,
          by_contradiction h5,
          rw h5 at h2,
          simp at h2,
          exact h2,
        },
        have h4 : degree a ≤ degree c,
        from le_degree h3,
        by_contradiction h5,
        rw h5 at h4,
        have : degree a = 0,
        from nat.eq_zero_of_le_zero h4,
        contradiction,
      }, 
      rw [is_constant_iff_degree_eq_zero] at h3,
      have h4 : 1 ≤ (degree c - degree (gcd c d[c])),
      from MS_aux_1a h3 h_char,
      apply nat.le_trans h4,
      simp,
      exact nat.zero_le _,   
    }
  },
  {
    by_cases h2 : (is_constant a),
    {
      rw add_comm at h_add,
      have h_constant' : ¬(is_constant b ∧ is_constant a ∧ is_constant c),
      {simp [*, and_comm]},
      have h3 : ¬is_constant c,
      from MS_aux_1b h_char h_add h_constant' h2 h1,
      rw [is_constant_iff_degree_eq_zero] at h3,
      have h4 : 1 ≤ (degree c - degree (gcd c d[c])),
      from MS_aux_1a h3 h_char,
      apply nat.le_trans h4,
      simp,
      exact nat.zero_le _,   
    },
    {
      admit --admit here

    }
  }
end

--h_deg_c_le_1
lemma rw_aux_1 [field β]
  --(h_char : characteristic_zero β)
  (a b c : polynomial β)
  --(h_rel_prime_ab : rel_prime a b)
  --(h_rel_prime_bc : rel_prime b c)
  --(h_rel_prime_ca : rel_prime c a)
  --(h_add : a + b = c)
  --(h_constant : ¬(is_constant a ∧ is_constant b ∧ is_constant c)) 
  (h_deg_add_le : degree (gcd a d[a]) + degree (gcd b d[b]) + degree (gcd c d[c]) ≤ degree a + degree b - 1) :
  degree c ≤
    (degree a - degree (gcd a d[a])) +
    (degree b - degree (gcd b d[b])) +
    (degree c - degree (gcd c d[c])) - 1 :=
have 1 ≤ degree a + degree b, from sorry,
have h : ∀p:polynomial β, degree (gcd p d[p]) ≤ degree p, from sorry,
have (degree (gcd a d[a]) : ℤ) + (degree (gcd b d[b]) : ℤ) + (degree (gcd c d[c]) : ℤ) ≤
    (degree a : ℤ) + (degree b : ℤ) - 1,
  by rwa [← int.coe_nat_add, ← int.coe_nat_add, ← int.coe_nat_add, ← int.coe_nat_one,
    ← int.coe_nat_sub this, int.coe_nat_le],
have (degree c : ℤ) ≤
    ((degree a : ℤ) - (degree (gcd a d[a]) : ℤ)) +
    ((degree b : ℤ) - (degree (gcd b d[b]) : ℤ)) +
    ((degree c : ℤ) - (degree (gcd c d[c]) : ℤ)) - 1,
  from calc (degree c : ℤ) ≤
    ((degree c : ℤ) + ((degree a : ℤ) + (degree b : ℤ) - 1)) -
      ((degree (gcd a d[a]) : ℤ) + (degree (gcd b d[b]) : ℤ) + (degree (gcd c d[c]) : ℤ)) : 
      le_sub_iff_add_le.mpr $ add_le_add_left this _
    ... = _ : by simp,
have 1 + (degree c : ℤ) ≤
    ((degree a : ℤ) - (degree (gcd a d[a]) : ℤ)) +
    ((degree b : ℤ) - (degree (gcd b d[b]) : ℤ)) +
    ((degree c : ℤ) - (degree (gcd c d[c]) : ℤ)),
  from add_le_of_le_sub_left this,
nat.le_sub_left_of_add_le $
  by rwa [← int.coe_nat_sub (h _), ← int.coe_nat_sub (h _), ← int.coe_nat_sub (h _),
      ← int.coe_nat_add, ← int.coe_nat_add, ← int.coe_nat_one, ← int.coe_nat_add, int.coe_nat_le] at this

/-
lemma Mason_Stothers_lemma
(f : polynomial β) : degree f ≤ degree (gcd f (derivative f )) + degree (rad f) -/
/-
lemma Mason_Stothers_lemma'
(f : polynomial β) : degree f - degree (gcd f (derivative f )) ≤  degree (rad f) := 
 -/
 /-
--We will need extra conditions here
lemma degree_rad_add {a b c : polynomial β}: degree (rad a) + degree (rad b) + degree (rad c) ≤ degree (rad (a * b * c)) :=
begin
  admit,
end-/

lemma nat.add_mono{a b c d : ℕ} (hab : a ≤ b) (hcd : c ≤ d) : a + c ≤ b + d :=
begin
  exact calc a + c ≤ a + d : nat.add_le_add_left hcd _
  ... ≤ b + d : nat.add_le_add_right hab _
end


--h_le_rad
lemma rw_aux_2 [field β] --We want to use the Mason Stothers lemmas here
  (a b c : polynomial β)
   : degree a - degree (gcd a d[a]) + (degree b - degree (gcd b d[b])) + (degree c - degree (gcd c d[c])) - 1 ≤
  degree (rad (a * b * c)) - 1:=
begin
  apply nat.sub_le_sub_right,
  have h_rad:  degree(rad(a))+degree(rad(b))+degree(rad(c)) ≤ degree(rad(a*b*c)),
    from sorry,
  refine nat.le_trans _ h_rad,
  apply nat.add_mono _ (Mason_Stothers_lemma' c),
  apply nat.add_mono (Mason_Stothers_lemma' a) (Mason_Stothers_lemma' b), 
end

private lemma h_dvd_wron_a 
(a b c : polynomial β): gcd a d[a] ∣ d[a] * b - a * d[b] :=
 begin
  have h1 : gcd a d[a] ∣ d[a] * b,
  {
    apply dvd_trans gcd_right,
    apply dvd_mul_of_dvd_left,
    simp
  },
  have h2 : gcd a d[a] ∣ a * d[b],
  {
    apply dvd_trans gcd_left,
    apply dvd_mul_of_dvd_left,
    simp
  },
  exact dvd_sub h1 h2,
end

private lemma h_dvd_wron_b 
(a b c : polynomial β): gcd b d[b] ∣ d[a] * b - a * d[b] :=
begin
  have h1 : gcd b d[b] ∣ d[a] * b,
  {
    apply dvd_trans gcd_left,
    apply dvd_mul_of_dvd_right,
    simp
  },
  have h2 : gcd b d[b] ∣ a * d[b],
  {
    apply dvd_trans gcd_right,
    apply dvd_mul_of_dvd_right,
    simp
  },
  exact dvd_sub h1 h2,
end
  
private lemma h_dvd_wron_c 
(a b c : polynomial β)
(h_wron : d[a] * b - a * d[b] = d[a] * c - a * d[c])
: gcd c d[c] ∣ d[a] * b - a * d[b] :=
begin
  rw h_wron,
  have h1 : gcd c d[c] ∣ a * d[c],
  {
    apply dvd_trans gcd_right,
    apply dvd_mul_of_dvd_right,
    simp
  },
  have h2 : gcd c d[c] ∣ d[a] * c,
  {
    apply dvd_trans gcd_left,
    apply dvd_mul_of_dvd_right,
    simp
  },
  exact dvd_sub h2 h1,
end




private lemma one_le_of_ne_zero {n : ℕ } (h : n ≠ 0) : 1 ≤ n := 
begin
  let m := some (nat.exists_eq_succ_of_ne_zero h),
  have h1 : n = nat.succ m,
  from some_spec (nat.exists_eq_succ_of_ne_zero h), 
  rw [h1, nat.succ_le_succ_iff],
  exact nat.zero_le _,
end

lemma degree_wron_le {a b : polynomial β} : degree (d[a] * b - a * d[b]) ≤ degree a + degree b - 1 :=
begin
  by_cases h1 : (a = 0),
  {
    simp *,
    exact nat.zero_le _,
  },
  {
    by_cases h2 : (degree a = 0),
    {

      by_cases h3 : (b = 0),
      {
        rw h3,
        simp,
        exact nat.zero_le _,
      },
      {
        simp [*],
        by_cases h4 : (degree b = 0),
        {
          simp *,
          rw [←is_constant_iff_degree_eq_zero] at *,
          have h5 : derivative a = 0,
          from derivative_eq_zero_of_is_constant h2,
          have h6 : derivative b = 0,
          from derivative_eq_zero_of_is_constant h4,
          simp *,          
        },
        {
          have h2a : degree a = 0,
          from h2,
          rw [←is_constant_iff_degree_eq_zero] at h2,
          have h5 : derivative a = 0,
          from derivative_eq_zero_of_is_constant h2,
          simp *,
          by_cases h6 : (derivative b = 0),
          {
            simp *,
            exact nat.zero_le _,
          },
          {
            rw [degree_neg],
            apply nat.le_trans degree_mul,
            simp *,
            exact degree_derivative_le,
          }
        },

      }
    },
    {
      by_cases h3 : (b = 0),
      {
        simp *,
        exact nat.zero_le _,
      },
      {
        by_cases h4 : (degree b = 0),
        {
          simp *,
          rw [←is_constant_iff_degree_eq_zero] at h4,
          have h5 : derivative b = 0,
          from derivative_eq_zero_of_is_constant h4,
          simp *,
          apply nat.le_trans degree_mul,
          rw [is_constant_iff_degree_eq_zero] at h4,
          simp *,
          exact degree_derivative_le,
        },
        {
          apply nat.le_trans degree_sub,
          have h5 : degree (d[a] * b) ≤ degree a + degree b - 1,
          {
            apply nat.le_trans degree_mul,
            rw [add_comm _ (degree b), add_comm _ (degree b), nat.add_sub_assoc],
            apply add_le_add_left,
            exact degree_derivative_le,
            exact polynomial.one_le_of_ne_zero h2, --Can I remove this from polynomial??
          },
          have h6 : (degree (a * d[b])) ≤ degree a + degree b - 1,
          {
            apply nat.le_trans degree_mul,
            rw [nat.add_sub_assoc],
            apply add_le_add_left,
            exact degree_derivative_le,
            exact polynomial.one_le_of_ne_zero h4,        
          },
          exact max_le h5 h6,
        }
      }
    }
  }
end

private lemma h_wron_ne_zero 
  (a b c : polynomial β)   
  (h_rel_prime_ab : rel_prime a b)
  (h_rel_prime_ca : rel_prime c a)
  (h_der_not_all_zero : ¬(d[a] = 0 ∧ d[b] = 0 ∧ d[c] = 0))
  (h_wron : d[a] * b - a * d[b] = d[a] * c - a * d[c]): 
  d[a] * b - a * d[b] ≠ 0 :=
begin
  by_contradiction h1,
  rw not_not at h1,
  have h_a_b : d[a] = 0 ∧ d[b] = 0,
  from derivative_eq_zero_and_derivative_eq_zero_of_rel_prime_of_wron_eq_zero h_rel_prime_ab h1,
  have h2 : d[a] * c - a * d[c] = 0,
  {rw [←h_wron, h1]},
  have h_a_c : d[a] = 0 ∧ d[c] = 0,
  from derivative_eq_zero_and_derivative_eq_zero_of_rel_prime_of_wron_eq_zero (rel_prime_comm h_rel_prime_ca) h2,
  have h3 : (d[a] = 0 ∧ d[b] = 0 ∧ d[c] = 0),
  exact ⟨and.elim_left h_a_b, and.elim_right h_a_b, and.elim_right h_a_c⟩,
  contradiction    
end

private lemma h_deg_add 
  (a b c : polynomial β)
  (h_wron_ne_zero : d[a] * b - a * d[b] ≠ 0)
  (h_gcds_dvd : (gcd a d[a]) * (gcd b d[b]) * (gcd c d[c]) ∣ d[a] * b - a * d[b]):
  degree (gcd a d[a] * gcd b d[b] * gcd c d[c]) = degree (gcd a d[a]) + degree (gcd b d[b]) + degree (gcd c d[c]) :=
begin
  have h1 : gcd a d[a] * gcd b d[b] * gcd c d[c] ≠ 0,
    from ne_zero_of_dvd_ne_zero h_gcds_dvd h_wron_ne_zero,
  have h2 : degree (gcd a d[a] * gcd b d[b] * gcd c d[c]) = degree (gcd a d[a] * gcd b d[b]) + degree (gcd c d[c]),
    from degree_mul_eq_add_of_mul_ne_zero h1,
  have h3 : gcd a d[a] * gcd b d[b] ≠ 0,
    from ne_zero_of_mul_ne_zero_right h1,
  have h4 : degree (gcd a d[a] * gcd b d[b]) = degree (gcd a d[a]) + degree (gcd b d[b]),
    from degree_mul_eq_add_of_mul_ne_zero h3,
  rw [h2, h4],
end

private lemma h_wron 
(a b c : polynomial β)
(h_add : a + b = c)
(h_der : d[a] + d[b] = d[c])
: d[a] * b - a * d[b] = d[a] * c - a * d[c] :=
begin
  have h1 : d[a] * a + d[a] * b = d[a] * c,
    exact calc d[a] * a + d[a] * b = d[a] * (a + b) : by rw [mul_add]
    ... = _ : by rw h_add,
  have h2 : a * d[a] + a * d[b] = a * d[c],
    exact calc a * d[a] + a * d[b] = a * (d[a] + d[b]) : by rw [mul_add]
    ... = _ : by rw h_der,
  have h3 : d[a] * b - a * d[b] = d[a] * c - a * d[c],
    exact calc d[a] * b - a * d[b] = d[a] * b + (d[a] * a - d[a] * a) - a * d[b] : by simp
    ... = d[a] * b + d[a] * a - d[a] * a - a * d[b] : by simp
    ... = d[a] * c - (d[a] * a +  a * d[b]) : by simp [h1]
    ... = d[a] * c - (a * d[a] +  a * d[b]) : by rw [mul_comm _ a]
    ... = _ : by rw h2,
  exact h3
end

private lemma h_gcds_dvd 
(a b c : polynomial β)
(h_rel_prime_ab : rel_prime a b)
(h_rel_prime_bc : rel_prime b c)
(h_rel_prime_ca : rel_prime c a)
(h_dvd_wron_a : gcd a d[a] ∣ d[a] * b - a * d[b])
(h_dvd_wron_b : gcd b d[b] ∣ d[a] * b - a * d[b])
(h_dvd_wron_c : gcd c d[c] ∣ d[a] * b - a * d[b]):
  (gcd a d[a]) * (gcd b d[b]) * (gcd c d[c]) ∣ d[a] * b - a * d[b] :=
begin 
  apply mul_dvd_of_dvd_of_dvd_of_rel_prime,
  apply rel_prime_mul_of_rel_prime_of_rel_prime_of_rel_prime,
  exact rel_prime_gcd_derivative_gcd_derivative_of_rel_prime (rel_prime_comm h_rel_prime_ca),
  exact rel_prime_gcd_derivative_gcd_derivative_of_rel_prime h_rel_prime_bc,
  apply mul_dvd_of_dvd_of_dvd_of_rel_prime,
  exact rel_prime_gcd_derivative_gcd_derivative_of_rel_prime h_rel_prime_ab,
  exact h_dvd_wron_a,
  exact h_dvd_wron_b,
  exact h_dvd_wron_c
end

theorem Mason_Stothers [field β]
  (h_char : characteristic_zero β)
  (a b c : polynomial β)
  (h_rel_prime_ab : rel_prime a b)
  (h_rel_prime_bc : rel_prime b c)
  (h_rel_prime_ca : rel_prime c a)
  (h_add : a + b = c)
  (h_constant : ¬(is_constant a ∧ is_constant b ∧ is_constant c)) :
  degree c ≤ degree ( rad (a*b*c)) - 1 :=

begin
  have h_der_not_all_zero : ¬(d[a] = 0 ∧ d[b] = 0 ∧ d[c] = 0),
  {
    rw [derivative_eq_zero_iff_is_constant h_char, derivative_eq_zero_iff_is_constant h_char, derivative_eq_zero_iff_is_constant h_char],
    exact h_constant,
  },
  have h_der : d[a] + d[b] = d[c],
  {
    rw [←h_add, derivative_add],
  },
  have h_wron : d[a] * b - a * d[b] = d[a] * c - a * d[c],
    from  h_wron a b c h_add h_der,
  have h_dvd_wron_a : gcd a d[a] ∣ d[a] * b - a * d[b],
    from h_dvd_wron_a a b c,
  have h_dvd_wron_b : gcd b d[b] ∣ d[a] * b - a * d[b],
    from h_dvd_wron_b a b c,   
  have h_dvd_wron_c : gcd c d[c] ∣ d[a] * b - a * d[b],
    from h_dvd_wron_c a b c h_wron,
  have h_gcds_dvd : (gcd a d[a]) * (gcd b d[b]) * (gcd c d[c]) ∣ d[a] * b - a * d[b],
    from h_gcds_dvd a b c h_rel_prime_ab h_rel_prime_bc h_rel_prime_ca h_dvd_wron_a h_dvd_wron_b h_dvd_wron_c,
  have h_wron_ne_zero : d[a] * b - a * d[b] ≠ 0,
    from h_wron_ne_zero a b c h_rel_prime_ab h_rel_prime_ca h_der_not_all_zero h_wron,
  have h_deg_add : degree (gcd a d[a] * gcd b d[b] * gcd c d[c]) = degree (gcd a d[a]) + degree (gcd b d[b]) + degree (gcd c d[c]),
    from h_deg_add a b c h_wron_ne_zero h_gcds_dvd,
  have h_deg_add_le : degree (gcd a d[a]) + degree (gcd b d[b]) + degree (gcd c d[c]) ≤ degree a + degree b - 1,
  {
    rw [←h_deg_add],
    have h1 : degree (gcd a d[a] * gcd b d[b] * gcd c d[c]) ≤ degree (d[a] * b - a * d[b]),
      from degree_dvd h_gcds_dvd h_wron_ne_zero,
    exact nat.le_trans h1 (degree_wron_le),
  },
  have h_deg_c_le_1 : degree c ≤ (degree a - degree (gcd a d[a])) + (degree b - degree (gcd b d[b])) + (degree c - degree (gcd c d[c])) - 1,
    from rw_aux_1 a b c h_deg_add_le,
  have h_le_rad : degree a - degree (gcd a d[a]) + (degree b - degree (gcd b d[b])) + (degree c - degree (gcd c d[c])) - 1 ≤
  degree (rad (a * b * c)) - 1,
    from rw_aux_2 a b c,
  exact nat.le_trans h_deg_c_le_1 h_le_rad,
end


end mason_stothers