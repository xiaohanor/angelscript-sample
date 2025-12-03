class UCoastBossAeronauticDamageFeedbackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerHealthComponent PlayerHealth;
	UNiagaraComponent SmokeVFX;
	UCoastBossAeronauticComponent AeroComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerHealth = UPlayerHealthComponent::Get(Player);
		AeroComp = UCoastBossAeronauticComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PlayerHealth.Health.IsDamaged())
			return false;
		if (Player.IsPlayerDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;
		if (PlayerHealth.Health.IsDamaged())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (AeroComp.GotImpactDamagedVFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAttached(AeroComp.GotImpactDamagedVFX, Player.MeshOffsetComponent);

		if (SmokeVFX == nullptr && AeroComp.DamagedVFX != nullptr)
			SmokeVFX = Niagara::SpawnLoopingNiagaraSystemAttached(AeroComp.DamagedVFX, Player.MeshOffsetComponent);
		
		if (SmokeVFX != nullptr)
		{
			SmokeVFX.Activate();
			SmokeVFX.SetWorldScale3D(FVector::OneVector * 3.0);
		}
		// if (AeroComp.IsDamagedFF != nullptr)
		// 	Player.PlayForceFeedback(AeroComp.IsDamagedFF, true, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (SmokeVFX != nullptr)
		{
			SmokeVFX.Deactivate();
			SmokeVFX.SetWorldScale3D(FVector::OneVector * KINDA_SMALL_NUMBER);
		}
			
		SmokeVFX = nullptr;
		// if (AeroComp.IsDamagedFF != nullptr)
		// 	Player.StopForceFeedback(this);
	}

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	Debug::DrawDebugString(Player.ActorLocation, "HP: " + PlayerHealth.Health.CurrentHealth + "/1.0", ColorDebug::Ruby);
	// }
};