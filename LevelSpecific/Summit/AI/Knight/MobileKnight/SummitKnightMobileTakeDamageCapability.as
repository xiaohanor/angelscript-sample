class USummitKnightMobileTakeDamageCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"Damage");

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	float RollHitCooldown = -BIG_NUMBER;

	float AcidHitBatchCooldown;
	float AcidBatchDamage;
	float TailDragonHitCameraSettingsClearTime = BIG_NUMBER;

	UBasicAIHealthComponent HealthComp;
	UTeenDragonTailAttackResponseComponent SmashResponseComp;
	UAcidResponseComponent AcidResponseComp;
	USummitKnightComponent KnightComp;
	USummitKnightMobileCrystalBottom CrystalBottom;
	USummitKnightHelmetComponent Helmet;
	UHazeSkeletalMeshComponentBase Mesh;
	USummitKnightSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		CrystalBottom = USummitKnightMobileCrystalBottom::Get(Owner);
		Helmet = USummitKnightHelmetComponent::Get(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		AcidResponseComp = UAcidResponseComponent::Get(Owner);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		SmashResponseComp = UTeenDragonTailAttackResponseComponent::Get(Owner);
		SmashResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		Settings = USummitKnightSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!IsActive())
			return; // Damage is blocked

		// TODO: Replace by proper effect
		DamageFlash::DamageFlashActor(Owner, 0.2, FLinearColor::White * 0.5);
		KnockBackTailDragon();
		USummitKnightEventHandler::Trigger_OnHitByRoll(Owner);

		if (KnightComp.TailDragonImpactCameraSettings != nullptr)
		{
			Game::Zoe.ApplyCameraSettings(KnightComp.TailDragonImpactCameraSettings, Settings.TailDragonHitCamSettingsBlendInTime, this, EHazeCameraPriority::VeryHigh);
			TailDragonHitCameraSettingsClearTime = Time::GameTimeSeconds + Settings.TailDragonHitCamSettingsDuration;
		}

		if (!KnightComp.bCanBeStunned.Get())
			return;
		if (Time::GameTimeSeconds < RollHitCooldown)
			return;

		RollHitCooldown = Time::GameTimeSeconds + 0.5;
		float Damage = Settings.SmashCrystalDamage;
		if (!KnightComp.bCanDie.Get() && (Damage > HealthComp.CurrentHealth))
			Damage = (HealthComp.CurrentHealth * 0.5) - 0.0001;
		HealthComp.TakeDamage(Damage, EDamageType::MeleeBlunt, Params.PlayerInstigator);
		HealthComp.SetStunned();
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (!IsActive())
			return; // Damage is blocked

		if (Game::Mio.HasControl())
		{
			if (ActiveDuration < AcidHitBatchCooldown)
			{
				// Delay damage until ready to network send another batch of damage
				AcidBatchDamage += Hit.Damage * Settings.AcidDamageFactor;
			}
			else
			{
				// Deal damage immediately, but then don't deal damage again until next batch interval
				float Damage = AcidBatchDamage + Hit.Damage * Settings.AcidDamageFactor;
				if (!KnightComp.bCanDie.Get() && (Damage > HealthComp.CurrentHealth))
					Damage = (HealthComp.CurrentHealth * 0.5) - 0.0001;
				HealthComp.TakeDamage(Damage, EDamageType::Acid, Game::Mio);
				AcidBatchDamage = 0.0;
				AcidHitBatchCooldown = ActiveDuration + 0.1;
			}
		}

		if (HealthComp.CurrentHealth < Settings.HealthThresholdMainToEndCircling)
		{
			USummitKnightSettings::SetMeltHelmetRegenerationCooldown(Owner, BIG_NUMBER, this);
			Helmet.TakeDamage(1.0);
		}

		// Green damage flash on body and head, but NOT sword
		FLinearColor FlashColor = FLinearColor(0.4, 1.0, 0.0) * 0.05;
		DamageFlash::DamageFlash(Mesh, 0.1, FlashColor);
		DamageFlash::DamageFlash(Helmet, 0.1, FlashColor);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if ((AcidBatchDamage > 0.0) && Game::Mio.HasControl())
		{
			if (Game::Mio.IsPlayerDead())
			{
				AcidBatchDamage = 0.0; // No posthumous damage
			}
			else if ((ActiveDuration > AcidHitBatchCooldown) || !IsActive()) 
			{
				HealthComp.TakeDamage(AcidBatchDamage, EDamageType::Acid, Game::Mio);
				AcidBatchDamage = 0.0;
				AcidHitBatchCooldown = ActiveDuration + 0.1;
			}
		}
		if (Time::GameTimeSeconds > TailDragonHitCameraSettingsClearTime)
		{
			TailDragonHitCameraSettingsClearTime = BIG_NUMBER;
			Game::Zoe.ClearCameraSettingsByInstigator(this, Settings.TailDragonHitCamSettingsBlendOutTime);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Game::Zoe.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Active when damage is allowed 
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	void KnockBackTailDragon()
	{
		if (!ensure(KnightComp.Arena != nullptr))
			return; // No arena yet, skip knockback

		AHazeActor Player = Game::Zoe;
		FVector PlayerLoc = KnightComp.Arena.GetAtArenaHeight(Player.ActorLocation);
		FVector KnightLoc = KnightComp.Arena.GetAtArenaHeight(Owner.ActorLocation);
		FVector Away = (PlayerLoc - KnightLoc).GetNormalized2DWithFallback(-Player.ActorForwardVector);
		FVector KnockbackDest = KnightComp.Arena.GetClampedToArena(PlayerLoc + Away * Settings.SmashCrystalPlayerStumbleDistance, 400.0);
		if (KnockbackDest.IsWithinDist2D(KnightLoc, Settings.SmashCrystalPlayerStumbleDistance * 0.75))
		{
			// Nudge towards arena center
			FVector NudgedDir = (((KnockbackDest + KnightComp.Arena.ActorLocation) * 0.5) - PlayerLoc).GetNormalized2DWithFallback(-Player.ActorForwardVector);
			KnockbackDest = KnightComp.Arena.GetClampedToArena(PlayerLoc + NudgedDir * Settings.SmashCrystalPlayerStumbleDistance, 400.0);
		}

		FTeenDragonStumble Stumble;
		Stumble.Move = KnockbackDest - PlayerLoc;
		Stumble.Duration = Settings.SmashCrystalPlayerStumbleDuration;
		Stumble.ArcHeight = Stumble.Move.Size() * 0.25;
		Stumble.Apply(Player);
	}
};