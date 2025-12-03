
/**
 * A struct to simplify tracking health, including recently taken damage,
 * regeneration and healing.
 */
struct FHealthValue
{
	// Current health the player has at this time
	float CurrentHealth = 1.0;

	// Amount of health that has been lost recently
	float RecentlyLostHealth = 0.0;
	float GameTimeAtMostRecentDamage = -1.0;
	bool bStartedDamageCharge = false;

	// Amount of health that has been healed recently
	float RecentlyHealedHealth = 0.0;
	float GameTimeAtMostRecentHeal = -1.0;
	bool bStartedHealCharge = false;

	// Amount of health that has been regenerated recently
	//  Regeneration is different from heal in how it is displayed
	float RecentlyRegeneratedHealth = 0.0;
	float TotalRegeneratingHealth = 0.0;
	
	// Duration and delay timers that indicate how fast health and damage show visually
	float RecentDelayAfterDamage = 0.5;
	float RecentDamageDecayRate = 0.5;
	float RecentDelayAfterHeal = 0.5;
	float RecentHealDecayRate = 0.5;
	float RegenerateDuration = 1.0;

	/**
	 * Get the amount of health to display as the 'current health.'
	 * 
	 * This is different from 'Current Health' because it excludes heals that
	 * have already happened but are still visually displaying.
	 * 
	 * This also does *not* include any health that has already been damaged but is still visually showing.
	 */
	float GetDisplayHealth() const
	{
		return CurrentHealth - RecentlyHealedHealth - RecentlyRegeneratedHealth;
	}

	/**
	 * Get how much 'regenerating' health to show *above* the display health.
	 */
	float GetDisplayRegenerationAmount() const
	{
		return RecentlyRegeneratedHealth;
	}

	/**
	 * Get how much 'healing' health to show *above* of the display health.
	 */
	float GetDisplayHealingAmount() const
	{
		return RecentlyHealedHealth;
	}

	/**
	 * Get how much 'damaged' health to show *above* the current display health amount.
	 */
	float GetDisplayDamageAmount() const
	{
		return RecentlyLostHealth;
	}

	bool HasFullHealth() const
	{
		return CurrentHealth > 1.0 - SMALL_NUMBER;
	}

	bool IsDamaged() const
	{
		return !HasFullHealth();
	}

	/**
	 * Deal damage to the health bar.
	 * 
	 * Returns whether the health is below zero after the damage.
	 */
	bool Damage(float Amount)
	{
		float PreviousHealth = CurrentHealth;
		CurrentHealth = Math::Clamp(CurrentHealth - Amount, 0.0, 1.0);

		// If we healed this damage recently, remove the recent heal
		float DamagedHealth = Math::Min(PreviousHealth, Amount);
		float TakeFromHeal = Math::Min(DamagedHealth, RecentlyHealedHealth);
		if (TakeFromHeal > 0.0)
			RecentlyHealedHealth -= TakeFromHeal;
		float TakeFromRegeneration = Math::Min(DamagedHealth - TakeFromHeal, RecentlyRegeneratedHealth);
		if (TakeFromRegeneration > 0.0)
		{
			RecentlyRegeneratedHealth -= TakeFromRegeneration;
			TotalRegeneratingHealth -= TakeFromRegeneration;
		}

		RecentlyLostHealth += DamagedHealth;
		GameTimeAtMostRecentDamage = Time::GetGameTimeSeconds();

		return Math::IsNearlyZero(CurrentHealth, KINDA_SMALL_NUMBER);
	}

	/**
	 * Heal the health for the specified amount.
	 */
	void Heal(float Amount)
	{
		float PreviousHealth = CurrentHealth;
		CurrentHealth = Math::Clamp(CurrentHealth + Amount, 0.0, 1.0);

		// If we took the damage we healed recently, remove the recent damage
		float HealedHealth = Math::Min(1.0 - PreviousHealth, Amount);
		if (HealedHealth > 0.0)
		{
			RecentlyLostHealth = Math::Max(0.0, RecentlyLostHealth - HealedHealth);
			RecentlyHealedHealth += HealedHealth;
			GameTimeAtMostRecentHeal = Time::GetGameTimeSeconds();
		}
	}

	/**
	 * Trigger a regeneration that shows the bar filling up over the next time.
	 */
	void Regenerate()
	{
		float PreviousHealth = CurrentHealth;
		CurrentHealth = 1.0;

		// If we took the damage we healed recently, remove the recent damage
		float RegeneratedHealth = (1.0 - PreviousHealth);
		if (RegeneratedHealth > 0.0)
		{
			RecentlyLostHealth = Math::Max(0.0, RecentlyLostHealth - RegeneratedHealth);
			RecentlyRegeneratedHealth += RegeneratedHealth;
			TotalRegeneratingHealth += RegeneratedHealth;
		}
	}

	/**
	 * Reset the health to its initial full state immediately.
	 */
	void Reset()
	{
		CurrentHealth = 1.0;
		RecentlyLostHealth = 0.0;
		GameTimeAtMostRecentDamage = -1.0;
		RecentlyHealedHealth = 0.0;
		bStartedDamageCharge = false;
		GameTimeAtMostRecentHeal = -1.0;
		RecentlyRegeneratedHealth = 0.0;
		TotalRegeneratingHealth = 0.0;
		bStartedHealCharge = false;
	}

	/**
	 * Update the damage and heal bars with the specified delta time.
	 */
	void Update(float DeltaTime)
	{
		float GameTime = Time::GetGameTimeSeconds();

		// Decay the recently lost health counter
		if (RecentlyLostHealth > 0.0)
		{
			if (GameTime > GameTimeAtMostRecentDamage + RecentDelayAfterDamage)
				bStartedDamageCharge = true;

			if (bStartedDamageCharge)
				RecentlyLostHealth = Math::Max(0.0, RecentlyLostHealth - DeltaTime * RecentDamageDecayRate);
		}
		else
		{
			bStartedDamageCharge = false;
		}

		// Decay the recently healed health counter
		if (RecentlyHealedHealth > 0.0)
		{
			if (GameTime > GameTimeAtMostRecentHeal + RecentDelayAfterHeal)
				bStartedHealCharge = true;
			
			if (bStartedHealCharge)
				RecentlyHealedHealth = Math::Max(0.0, RecentlyHealedHealth - DeltaTime * RecentHealDecayRate);
		}
		else
		{
			bStartedHealCharge = false;
		}

		// Decay the recently regenerated health counter
		if (RecentlyRegeneratedHealth > 0.0)
		{
			RecentlyRegeneratedHealth = Math::Max(0.0, RecentlyRegeneratedHealth - (DeltaTime / RegenerateDuration));
		}
		else
		{
			TotalRegeneratingHealth = 0.0;
		}
	}
};