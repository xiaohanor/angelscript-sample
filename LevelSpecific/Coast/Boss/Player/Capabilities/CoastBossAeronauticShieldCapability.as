class UCoastBossAeronauticShieldCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	UCoastBossAeronauticComponent AeroComp;

	ACoastBossActorReferences References;
	UPlayerHealthComponent PlayerHealthComp;
	FHazeAcceleratedVector AccShieldScale;
	ECoastBossPlayerDroneShield CurrentShieldMaterial;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AeroComp = UCoastBossAeronauticComponent::Get(Player);
		CoastBossDevToggles::PlayersInvulnerable.MakeVisible();
		PlayerHealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// if (!HasControl())
		// 	return false;
		if (References != nullptr && References.Boss.bDead)
			return false;

		if (Player.IsPlayerDead())
			return false;

		if (AeroComp.AttachedToShip == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (References != nullptr && References.Boss.bDead)
			return true;

		if (Player.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AeroComp.AttachedToShip.InvulnerableShield.SetVisibility(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AeroComp.AttachedToShip.InvulnerableShield.SetVisibility(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bIsDamaged = PlayerHealthComp.Health.CurrentHealth < 1.0 - KINDA_SMALL_NUMBER;
		if (AeroComp.bPlayerInvulnerable)
		{
			const float WobblyAlpha = Math::Wrap(ActiveDuration, 0.0, 0.3) / 0.3;
			const float Target = WobblyAlpha < 0.5 ? 1 : 1.3;
			AccShieldScale.SpringTo(AeroComp.AttachedToShip.OGScale * Target, 100.0, 0.7, DeltaTime);
		}
		else if (bIsDamaged || !AeroComp.bHasShield)
			AccShieldScale.SpringTo(FVector(0.01), 50.0, 0.2, DeltaTime);
		else
			AccShieldScale.SpringTo(AeroComp.AttachedToShip.OGScale, 200.0, 0.7, DeltaTime);

	
		ECoastBossPlayerDroneShield DesiredShieldMaterial = ECoastBossPlayerDroneShield::Normal;
		if (bIsDamaged)
			DesiredShieldMaterial = ECoastBossPlayerDroneShield::Hurt;
		else if (AeroComp.bPlayerInvulnerable)
			DesiredShieldMaterial = ECoastBossPlayerDroneShield::Invincible;

		if (CurrentShieldMaterial != DesiredShieldMaterial)
		{
			AeroComp.AttachedToShip.BP_ChangeShieldMaterial(DesiredShieldMaterial);
			CurrentShieldMaterial = DesiredShieldMaterial;

			FCoastBossAeuronauticPlayerShieldData Data;
			Data.State = CurrentShieldMaterial;
			UCoastBossAeuronauticPlayerEventHandler::Trigger_ShieldChangeState(Player, Data);
		}

		FVector ClampedScale = AccShieldScale.Value;
		ClampedScale = FVector(ClampScaleValue(ClampedScale.X), ClampScaleValue(ClampedScale.Y), ClampScaleValue(ClampedScale.Z));
		AeroComp.AttachedToShip.InvulnerableShield.RelativeScale3D = ClampedScale;
	}

	float ClampScaleValue(float Value) const
	{
		return Math::Clamp(Value, 0.01, 10.0);
	}
};