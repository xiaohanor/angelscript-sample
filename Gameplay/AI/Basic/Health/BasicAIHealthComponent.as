
event void FBasicAIHealthOnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType);
event void FBasicAIHealtChange();
event void FBasicAIHealthOnDie(AHazeActor ActorBeingKilled);
event void FBasicAIHealthPreDeath();


class UBasicAIHealthComponent : UActorComponent
{
	UPROPERTY()
	UBasicAIHealthSettings DefaultSettings;

    // Triggers when we take damage
	UPROPERTY(meta = (NotBlueprintCallable))
	FBasicAIHealthOnTakeDamage OnTakeDamage;

    // Triggers when health is changed for any reason
	UPROPERTY(meta = (NotBlueprintCallable))
	FBasicAIHealtChange OnHealthChange;

	// Triggers as soon as possible when death is inevitable (start of death anim etc)
	UPROPERTY(meta = (NotBlueprintCallable))
	FBasicAIHealthOnDie OnStartDying;

    // Triggers when we die
	UPROPERTY(meta = (NotBlueprintCallable))
	FBasicAIHealthOnDie OnDie;

	// Trigger when set to dead on remote side 
	FBasicAIHealthPreDeath OnRemotePreDeath;

	// How much damage we can take at maximum. We prefer to tweak how much damage is taken instead of tweaking this.
	UPROPERTY(EditAnywhere)
	float MaxHealth = 1.0;

	private AHazeActor HazeOwner = nullptr;

	private float CurHealth = 1.0;
	private float TakeDamageCooldownTime = 0.0;	
	private UBasicAIHealthSettings Settings;

	private float LatestDamage = 0.0;
	private EDamageType LatestDamageType = EDamageType::Invalid;
	private float LatestDamageTime = -BIG_NUMBER;
	private AHazeActor LatestAttacker = nullptr;
	private bool bHasReactedToDamage = false;
	private bool bIsStunned = false;
	private bool bIsInvulnerable = false;
	private bool bHasDiedOnRemote = false;
	private bool bHasStartedDying = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		if (DefaultSettings != nullptr)
			HazeOwner.ApplyDefaultSettings(DefaultSettings);
		Settings = UBasicAIHealthSettings::GetSettings(HazeOwner);
		Reset();
	}

	UFUNCTION()
	void Reset()
	{
		CurHealth = MaxHealth;
		LatestDamage = 0.0;
		LatestDamageType = EDamageType::Invalid;
		LatestDamageTime = -BIG_NUMBER;
		LatestAttacker = nullptr;
		bIsStunned = false;
		bHasDiedOnRemote = false;
		bHasStartedDying = false;
	}

	UFUNCTION(BlueprintPure)
	bool IsAlive() const
	{
		return (CurHealth > SMALL_NUMBER);
	}
	
	UFUNCTION(BlueprintPure)
	bool IsDead() const
	{
		return !IsAlive();
	}

	UFUNCTION(BlueprintPure)
	bool IsDying() const
	{
		return IsDead() || bHasStartedDying;
	}

	float GetLastDamage() const property
	{
		return LatestDamage;
	}

	EDamageType GetLastDamageType() const property
	{
		return LatestDamageType;
	}

	float GetLastDamageTime() const property
	{
		return LatestDamageTime;
	}

	AHazeActor GetLastAttacker() const property
	{
		return LatestAttacker;
	}

	UFUNCTION()
	void TakeDamage(float Damage, EDamageType DamageType, AHazeActor Instigator)
	{
		if (Time::GetGameTimeSeconds() < TakeDamageCooldownTime)
			return; // Can't be hurt again yet

		if (Instigator == nullptr)
		{
			// Vem var det som kasta?! <-- That guy is from västerås ;) / TYKO
			if (!HasControl())
				return;
		}
		else 
		{
			// Only take damage on instigator control side
			if (!Instigator.HasControl())
				return;
		}

		CrumbTakeDamage(Damage, DamageType, Instigator);
	}

    UFUNCTION(NotBlueprintCallable, CrumbFunction)
	private void CrumbTakeDamage(float Damage, EDamageType DamageType, AHazeActor Instigator)
	{
		TakeDamageCooldownTime = Time::GetGameTimeSeconds() + Settings.TakeDamageCooldown;
		if (CurHealth > 0)
			SetCurrentHealth(CurHealth - Damage);

		LatestDamageType = DamageType;
		LatestDamage = Damage;
		LatestDamageTime = Time::GameTimeSeconds;
		LatestAttacker = Instigator;
		bHasReactedToDamage = false;

		UBasicAIDamageEffectHandler::Trigger_OnDamage(HazeOwner);
		OnTakeDamage.Broadcast(Cast<AHazeActor>(Owner), Instigator, Damage, DamageType);

		if (CurHealth < SMALL_NUMBER)
			DieLocal();
	}

	UFUNCTION()
    void Die()
    {
		if(HasControl())
			CrumbDie();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
    private void CrumbDie()
    {
		DieLocal();
	}

	UFUNCTION(NotBlueprintCallable)
    void DieLocal()
    {
		if (Settings.bImmortal)
		{
			CurHealth = 0.001;
			OnHealthChange.Broadcast();
			return;
		}

		CurHealth = 0.0;
		OnHealthChange.Broadcast();

		// If we're on instigator remote side, it'll take a while before 
		// death capability kicks in, so let's do some visual stuff early
		if (!HasControl() && !bHasDiedOnRemote)
		{
			OnRemotePreDeath.Broadcast();
			bHasDiedOnRemote = true;
		}
    }

	UFUNCTION()
	void SetCurrentHealth(float NewHealth)
	{
		CurHealth = Math::Min(NewHealth, MaxHealth);
		if (Settings.bImmortal && CurHealth < 0.001)
			CurHealth = 0.001;
		OnHealthChange.Broadcast();
	}

	void SetMaxHealth(float NewMaxHealth, bool bRetainFraction = false)
	{
		float CurrentFraction = GetHealthFraction();
		MaxHealth = NewMaxHealth;
		if (bRetainFraction)
			SetCurrentHealth(MaxHealth * CurrentFraction);
	}

	void RemoteDie()
	{
		if (!HasControl())
			SetCurrentHealth(0.0);
	}

	float GetCurrentHealth() const property
	{
		return CurHealth;
	}

	UFUNCTION(BlueprintPure)
	float GetHealthFraction() const
	{
		if (MaxHealth == 0)
			return 1.0;
		return CurHealth / MaxHealth;
	}

	bool ShouldReactToDamage(TArray<EDamageType> DamageTypes, float IgnoreDamageAge) const
	{
		if (IsDead())
			return false;
		if (bHasReactedToDamage)
			return false;
		if (Time::GetGameTimeSince(LastDamageTime) > IgnoreDamageAge)
			return false;
		// Check damage types. If empty, any damage type will cause a reaction.
		if ((DamageTypes.Num() > 0) && !DamageTypes.Contains(LastDamageType))
			return false;
		return true;
	}

	void SetStunned()
	{
		bHasReactedToDamage = true;
		bIsStunned = true;
	}

	void ClearStunned()
	{
		bIsStunned = false;
	}

	bool IsStunned() const
	{
		return bIsStunned;
	}

	bool IsInvulnerable() const
	{
		return bIsInvulnerable;
	}

	bool HasStartedDying()
	{
		return bHasStartedDying;
	}

	void TriggerStartDying()
	{
		if (!bHasStartedDying)
		{
			bHasStartedDying = true;
			OnStartDying.Broadcast(HazeOwner);
		}
	}

	void SetInvulnerable()
	{
		TakeDamageCooldownTime = BIG_NUMBER;
		bIsInvulnerable = true;
	}

	void RemoveInvulnerable()
	{
		TakeDamageCooldownTime = 0;
		bIsInvulnerable = false;
	}
}
