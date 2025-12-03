event void FPlayerHealthComponentStartDyingSignature();
event void FPlayerHealthComponentFinishDyingSignature();
event void FOnPlayerTookDamage(AHazePlayerCharacter Player, float DamageAmount);

event void FPlayerCustomGameOver();

enum EGodMode
{
	Mortal,
	Jesus,
	God,
};

struct FPlayerInvulnerability
{
	FInstigator Instigator;
	float Timer = 0.0;
	bool bCausedByDamageHit = false;
};

struct FPlayerDeathDamageParams
{
	//Location force is applied from (In front of the players by default)
	UPROPERTY()
	FVector ImpactDirection = FVector(0);

	//Strength of force applied to particles 
	UPROPERTY()
	float ForceScale = 1.0;

	//If falling death, applies a specific type of force to the particles based on player fall direction
	UPROPERTY()
	bool bIsFallingDeath = false;

	UPROPERTY()
	bool bUseDeathCamera = true;

	//If static camera, stop duration will automatically be set to 0
	UPROPERTY()
	bool bApplyStaticCamera = false;

	//Set how long it takes for the camera to reach zero velocity after players die
	UPROPERTY()
	float CameraStopDuration = -1.0;
	
	FPlayerDeathDamageParams(FVector NewImpactDirection, float NewForceScale = 1.0, bool bFallingDeath = false, bool bCanUseDeathCamera = true, bool bStaticCamera = false, float NewCameraStopDuration = -1.0)
	{
		ImpactDirection = NewImpactDirection;
		ForceScale = NewForceScale;
		bIsFallingDeath = bFallingDeath;
		bUseDeathCamera = bCanUseDeathCamera;
		bApplyStaticCamera = bStaticCamera;
		CameraStopDuration = NewCameraStopDuration;
	}
}

class UPlayerHealthComponent : UActorComponent
{
	access DeathEffect = protected, UDeathEffect;

	UPROPERTY(Category = "Death and Damage")
	UDeathRespawnEffectSettings DeathRespawnSettings;

	UPROPERTY(Category = "Death and Damage")
	TSubclassOf<UDeathEffect> DefaultDeathEffect;

	UPROPERTY(Category = "Death and Damage")
	TSubclassOf<UDeathEffect> DefaultFallingDeathEffect;

	UPROPERTY(Category = "Death and Damage")
	TSubclassOf<UDamageEffect> DefaultDamageEffect;


	// UPROPERTY(Category = "Death and Damage Defaults")
	// TPerPlayer<UNiagaraSystem> DefaultRecieveDamageEffect;

	// UPROPERTY(Category = "Death and Damage Defaults")
	// UNiagaraSystem DefaultRespawnParticles;

	// UPROPERTY(Category = "Death and Damage Defaults")
	// UMaterialInterface DefaultRespawnOverlay;
	
	// UPROPERTY(Category = "Death and Damage Defaults")
	// UMaterialInterface DefaultDamageOveraly;


	UPROPERTY()
	TSubclassOf<UPlayerHealthOverlayWidget> HealthOverlayWidget;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> RespawnMashOverlayWidget;

	UPROPERTY()
	UMaterialInterface DamageScreenEffectMaterial;
	UPROPERTY()
	TSubclassOf<UPlayerDamageScreenEffectWidget> DamageScreenEffectWidget;

	FPlayerHealthComponentStartDyingSignature OnStartDying;
	FPlayerHealthComponentFinishDyingSignature OnFinishDying;

	FPlayerHealthComponentStartDyingSignature OnDeathTriggered;
	FPlayerHealthComponentFinishDyingSignature OnReviveTriggered;

	FPlayerCustomGameOver CustomGameOverOverride;
	FOnPlayerTookDamage OnPlayerTookDamage;

	AHazePlayerCharacter Player;
	UPlayerHealthSettings HealthSettings;
	FHealthValue Health;

	bool bIsDead = false;
	bool bIsGameOver = false;
	bool bIsRespawning = false;

	bool bHasStartedDying = false;
	bool bHasFinishedDying = false;
	float DeathEffectDuration = 0.0;

	bool bRespawnTimerActive = false;
	float RespawnTimer = 0.0;
	float GameTimeOfDeath = 0.0;
	TInstigated<bool> IsBossHealthBarVisible;

	float PendingBatchedDamage = 0.0;
	FPlayerDeathDamageParams PendingBatchDeathParams;
	float BatchedDamageTimer = 0.0;
	TSubclassOf<UDeathEffect> PendingBatchDeathEffect;
	TSubclassOf<UDamageEffect> PendingBatchDamageEffect;

	//Added so other scripts can read from it
	private FPlayerDeathDamageParams SavedDeathDamageParams;
	private bool bFlashInvulnerability = false;
	private FLinearColor FlashColor;
	private float FlashPulseDuration = 0.0;
	private float FlashPulseInterval = 0.0;
	private float FlashTimer = 0.0;
	private float NextFlash = 0.0;

	private float SecondChanceImmortalityTime = 0.0;
	private float AvoidedDamageCooldownTime = 0.0;

	EGodMode GodMode = EGodMode::Mortal;

	access:DeathEffect
	TArray<FName> TagsBlockedDuringDeath;
	access:DeathEffect
	TArray<FName> TagsBlockedUntilRespawn;
	
	TArray<FPlayerInvulnerability> DamageInvulnerabilities;
	TArray<UDamageEffect> DamageEffects;

	TInstigated<float> DamageTakenMultiplier(1.0);

	const FLinearColor FlashColor_Damage(1.0, 0.0, 0.0);
	const FLinearColor FlashColor_Respawn(1.0, 0.664, 0.051333);

	FPlayerDeathDamageParams DeathImpactData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Player);
		Player.ApplySettings(DeathRespawnSettings, this, EHazeSettingsPriority::Defaults);

		// Register the dev input for toggling godmode
		FHazeDevInputInfo ToggleInputInfo;
		ToggleInputInfo.Name = n"God Mode";
		ToggleInputInfo.Category = n"Default";
		ToggleInputInfo.OnTriggered.BindUFunction(this, n"HandleToggleGodMode");
		ToggleInputInfo.OnStatus.BindUFunction(this, n"GetGodModeStatus");
		ToggleInputInfo.AddKey(EKeys::Gamepad_LeftShoulder);
		ToggleInputInfo.AddKey(EKeys::J);

		Player.RegisterDevInput(ToggleInputInfo);

		DevTogglesPlayerHealth::ZoeGodmodeCategory.MakeVisible();
		DevTogglesPlayerHealth::MioGodmodeCategory.MakeVisible();
	}

	UFUNCTION()
	private void GetGodModeStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		if (HasGodMode())
		{
			OutColor = FLinearColor::Red;
			OutDescription = "[ God Mode Active ]";
		}
		else if (HasJesusMode())
		{
			OutColor = FLinearColor(0.83, 0.13, 1.00);
			OutDescription = "[ Jesus Mode Active ]";
		}
	}

	UFUNCTION()
	private void HandleToggleGodMode()
	{
		GodMode = EGodMode(Math::WrapIndex(int(GodMode) + 1, 0, 3));

		// Also set godmode to the same value on the other player
		auto OtherHealthComp = UPlayerHealthComponent::Get(Player.OtherPlayer);
		OtherHealthComp.GodMode = GodMode;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Health.Update(DeltaSeconds);

		// Update active damage invulnerabilities
		for (int i = DamageInvulnerabilities.Num() - 1; i >= 0; --i)
		{
			FPlayerInvulnerability& Invuln = DamageInvulnerabilities[i];

			// Remove invulnerabilities that have expired
			if (Invuln.Timer > 0.0)
			{
				Invuln.Timer -= DeltaSeconds;
				if (Invuln.Timer <= 0.0)
					DamageInvulnerabilities.RemoveAt(i);
			}
		}

		// Update active damage effects
		for (int i = DamageEffects.Num() - 1; i >= 0; --i)
		{
			UDamageEffect Effect = DamageEffects[i];
			if (!Effect.bActive)
			{
				DamageEffects.RemoveAt(i);
				continue;
			}

			Effect.ActiveTimer += DeltaSeconds;
			if (Effect.ActiveTimer >= Effect.MaximumDuration)
			{
				Effect.Deactivate();
				DamageEffects.RemoveAt(i);
				continue;
			}
		}

		// Deal with damage that gets batched into multiple damage ticks per second
		if (HasControl())
		{
			BatchedDamageTimer += DeltaSeconds;
			if (BatchedDamageTimer > 0.15)
			{
				if (PendingBatchedDamage > 0.0)
				{
					DamagePlayer(PendingBatchedDamage, PendingBatchDamageEffect, PendingBatchDeathEffect, false, PendingBatchDeathParams);
					PendingBatchedDamage = 0.0;
				}
				BatchedDamageTimer = 0.0;
			}
		}

		// Handle invulnerability flashes
		//Removed temp damage flashes, using new EBP instead. 
		if (bFlashInvulnerability)
		{
			if (!HealthSettings.bDisplayHealth || DamageInvulnerabilities.Num() == 0 || Player.bIsControlledByCutscene)
			{
				bFlashInvulnerability = false;
				//if (Player.bIsControlledByCutscene)
					//DamageFlash::ClearPlayerFlash(Player);
			}
			else
			{
				FlashTimer += DeltaSeconds;
				if (FlashTimer >= NextFlash)
				{
					//if (!Player.IsCapabilityTagBlocked(n"DamageFlash"))
						//DamageFlash::DamageFlashPlayer(Player, FlashPulseDuration, FlashColor);
					NextFlash += FlashPulseInterval;
				}
			}
		}
		
		// If the player is dead but in a cutscene, revive them instantly so they appear in the cutscene
		if (bIsDead && Player.bIsControlledByCutscene)
			Revive(false);

		if ((SecondChanceImmortalityTime > 0.0) && Health.HasFullHealth())
			SecondChanceImmortalityTime = 0.0;

#if !RELEASE
		if (HasGodMode())
		{
			// if (Player == Game::FirstLocalPlayer)
			FString PlayerName = Player.IsMio() ? "MIO" : "ZOE";
			PrintToScreen(f"GOD MODE ACTIVE - "+ PlayerName);
		}
		else if (HasJesusMode())
		{
			// if (Player == Game::FirstLocalPlayer)
			FString PlayerName = Player.IsMio() ? "MIO" : "ZOE";
			PrintToScreen(f"JESUS MODE ACTIVE - " + PlayerName);
		}

		FString PlayerName = Player.IsMio() ? "Mio" : "Zoe";
		TEMPORAL_LOG(Player, "Health")
			.Value(f"Current Health", Health.CurrentHealth)
			.Value(f"Game Time Most Recent Damage", Health.GameTimeAtMostRecentDamage)
			.Value(f"{PlayerName} Time of Death", GameTimeOfDeath)
			.Value(f"{PlayerName} Is Dead", bIsDead)
			.Value(f"{PlayerName} Is Respawning", bIsRespawning)
			.Value(f"{PlayerName} Is Game Over", bIsGameOver)
		;
#endif
	}

	private bool HasGodMode() const
	{
		if (GodMode == EGodMode::God)
			return true;
		if (Player.IsMio() && DevTogglesPlayerHealth::MioGodmode.IsEnabled())
			return true;
		if (Player.IsZoe() && DevTogglesPlayerHealth::ZoeGodmode.IsEnabled())
			return true;
		return false;
	}
	
	private bool HasJesusMode() const
	{
		if (GodMode == EGodMode::Jesus)
			return true;
		if (Player.IsMio() && DevTogglesPlayerHealth::MioJesusmode.IsEnabled())
			return true;
		if (Player.IsZoe() && DevTogglesPlayerHealth::ZoeJesusmode.IsEnabled())
			return true;
		return false;
	}

	void AddDamageInvulnerability(FInstigator Instigator, float MaxDuration, bool bCausedByDamageHit = false)
	{
		for (int i = DamageInvulnerabilities.Num() - 1; i >= 0; --i)
		{
			FPlayerInvulnerability& Invuln = DamageInvulnerabilities[i];
			if (Invuln.Instigator == Instigator)
			{
				if (MaxDuration <= 0.0)
					Invuln.Timer = 0.0;
				else
					Invuln.Timer = Math::Max(Invuln.Timer, MaxDuration);
				return;
			}
		}

		FPlayerInvulnerability Invuln;
		Invuln.Instigator = Instigator;
		Invuln.Timer = MaxDuration;
		Invuln.bCausedByDamageHit = bCausedByDamageHit;
		DamageInvulnerabilities.Add(Invuln);
	}

	void FlashInvulnerability(FLinearColor Color, float PulseDuration, float PulseInterval = -1.0)
	{
		bFlashInvulnerability = true;
		FlashColor = Color;
		FlashPulseDuration = PulseDuration;
		if (PulseInterval == -1.0)
			FlashPulseInterval = MAX_flt;
		else
			FlashPulseInterval = PulseInterval;
		FlashTimer = 0.0;
		NextFlash = 0.0;
	}

	void RemoveDamageInvulnerability(FInstigator Instigator)
	{
		for (int i = DamageInvulnerabilities.Num() - 1; i >= 0; --i)
		{
			FPlayerInvulnerability& Invuln = DamageInvulnerabilities[i];
			if (Invuln.Instigator == Instigator)
				DamageInvulnerabilities.RemoveAt(i);
		}
	}

	void Revive(bool bNaturalRespawn)
	{
		if (bHasFinishedDying)
		{
			for (FName Tag : TagsBlockedUntilRespawn)
				Player.UnblockCapabilities(Tag, this);
		}
		else
		{
			for (FName Tag : TagsBlockedDuringDeath)
				Player.UnblockCapabilities(Tag, this);

			if (bHasStartedDying)
			{
				UDeathEffect::Trigger_FinishedDying(Player);
				OnFinishDying.Broadcast();
			}
		}

		bIsDead = false;
		bHasStartedDying = false;
		bHasFinishedDying = false;
		DeathEffectDuration = 0.0;
		Health.Reset();
		bRespawnTimerActive = false;
		SecondChanceImmortalityTime = 0.0;		

		TagsBlockedDuringDeath.Reset();
		TagsBlockedUntilRespawn.Reset();

		Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::AcceleratedFast);
		OnReviveTriggered.Broadcast();

		if (HealthSettings.InvulnerabilityDurationAfterRespawning > 0.0)
		{
			AddDamageInvulnerability(n"Respawn", HealthSettings.InvulnerabilityDurationAfterRespawning, false);
			FlashInvulnerability(FlashColor_Respawn, 2.0);
		}

		UPlayerDamageEffectHandler::Trigger_PlayerRevived(Player);
		BroadcastHealthUpdated();

		// If we aren't in the process of respawning (eg this is a forced respawn not a normal one)
		// We need to trigger all the death effect events that aren't going to happen naturally
		if (!bNaturalRespawn)
		{
			if (!bIsRespawning)
				UDeathEffect::Trigger_RespawnStarted(Player);

			UDeathEffect::Trigger_RespawnTriggered(Player);
			UPlayerRespawnComponent::Get(Player).OnPlayerRespawned.Broadcast(Player);

			if (!bIsRespawning)
				UDeathEffect::Trigger_DeathAndRespawnCycleCompleted(Player);
		}
	}

	void BroadcastHealthUpdated()
	{
		FPlayerHealthUpdatedParams Params;
		Params.NewHealth = Health.CurrentHealth;
		Params.bIsDead = bIsDead;
		UPlayerDamageEffectHandler::Trigger_HealthUpdated(Player, Params);
	}

	void TriggerRespawn(bool bInstant)
	{
		if (HasControl() && bIsDead)
			CrumbTriggerRespawn(bInstant);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTriggerRespawn(bool bInstant)
	{
		if (bInstant)
		{
			if (bIsDead)
				Revive(false);
		}
		else
		{
			RespawnTimer = MAX_flt;
		}
	}

	void StartDying()
	{
		OnStartDying.Broadcast();
		RespawnTimer = 0.0;

		if (HealthSettings.RespawnTimer > 0.0
			&& HealthSettings.bEnableRespawnTimer
			&& HealthSettings.bReduceViewSizeForDeadPlayer
#if EDITOR
			// Editor single screen networking should not change the viewsize here, because it is annoying
			&& !Editor::EditorPlayModeIsNetSingleScreen
#endif
		)
		{
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Small, EHazeViewPointBlendSpeed::AcceleratedNormal, Priority = EHazeViewPointPriority::Medium);
		}
	}

	void FinishDying()
	{
		if (!bIsDead)
			return;

		bHasFinishedDying = true;
		bHasStartedDying = true;
		bRespawnTimerActive = true;

		for (FName Tag : TagsBlockedDuringDeath)
			Player.UnblockCapabilities(Tag, this);
		for (FName Tag : TagsBlockedUntilRespawn)
			Player.BlockCapabilities(Tag, this);

		OnFinishDying.Broadcast();
	}

	bool CanDie() const
	{
		if (bIsDead)
			return false;
		if (Player.IsCapabilityTagBlocked(n"Death"))
			return false;
		if (HasGodMode())
			return false;
		if (Player.bIsControlledByCutscene)
			return false;
		return true;
	}

	bool CanTakeDamage(bool bIsOneShot = false) const
	{
		if (bIsDead)
			return false;
		if (HasGodMode())
			return false;

		for (auto Invuln : DamageInvulnerabilities)
		{
			// If the invulnerability was caused by the player taking damage, we still
			// allow oneshots to deal damage to the player even while invulnerable.
			// This is so you can't avoid a boss attack that oneshots the player by taking
			// a small amount of damage right before it.
			if (bIsOneShot && Invuln.bCausedByDamageHit)
				continue;
			return false;
		}

		if (Player.bIsControlledByCutscene)
			return false;
		return true;
	}

	float GetDamageMultiplier() const
	{
		return DamageTakenMultiplier.Get();
	}

	bool WouldDieFromDamage(float Amount, bool bAllowInvulnerability)
	{
		if (HasJesusMode())
			return false;

		float RealDamage = Amount * GetDamageMultiplier();
		if (RealDamage == 0.0)
			return false;
		if ((Health.CurrentHealth - RealDamage) >= KINDA_SMALL_NUMBER)
			return false;
		if (GetCombatModifier(Player) == ECombatModifier::InfiniteHealth)
			return false;

		if (bAllowInvulnerability)
		{
			if ((HealthSettings.SecondChanceWhenKilledDuration > 0.0) && (SecondChanceImmortalityTime == 0.0))
				return false;
			if (Time::GameTimeSeconds < SecondChanceImmortalityTime)
				return false; // Already in grace period 
		}

		if (!CanDie())
			return false;

		return true;
	}

	TSubclassOf<UDeathEffect> GetUsedDeathEffect(TSubclassOf<UDeathEffect> DeathEffect, bool bFallingDeath)
	{
		if (DeathEffect.IsValid())
			return DeathEffect;
		if (bFallingDeath)
			return DefaultFallingDeathEffect;
		if (HealthSettings.DefaultDeathEffect.IsValid())
			return HealthSettings.DefaultDeathEffect;
		if (DefaultDeathEffect.IsValid())
			return DefaultDeathEffect;
		return UDeathEffect;
	}

	void KillPlayer(FPlayerDeathDamageParams DeathParams, TSubclassOf<UDeathEffect> DeathEffect)
	{
		if (HasControl())	
		{
			if (CanDie())
				CrumbKillPlayer(GetUsedDeathEffect(DeathEffect, DeathParams.bIsFallingDeath), DeathImpactParams = DeathParams);
		}
	}

	void TriggerDeathEffectCompleted()
	{
		DeathEffectDuration = 0.0;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbKillPlayer(TSubclassOf<UDeathEffect> DeathEffect, bool bDiedFromDamage = false, float DamageAmount = 0.0, FVector DeathImpulse = FVector::ZeroVector, FPlayerDeathDamageParams DeathImpactParams = FPlayerDeathDamageParams())
	{
		devCheck(!bIsDead);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(Player, "Health");
		TemporalLog.Event("CrumbKillPlayer");

		TArray<FString> Callstack = GetAngelscriptCallstack();
		for(int i = 0; i < Callstack.Num(); i++)
		{
			TemporalLog.Value(f"CrumbKillPlayer Callstack [{i}]", Callstack[i]);
		}
#endif
		bIsDead = true;
		GameTimeOfDeath = Time::GetGameTimeSeconds();

		if (bDiedFromDamage)
		{
			Health.Damage(Health.CurrentHealth);
			BroadcastHealthUpdated();

			// Broadcast damage taken if we died because of damage
			FPlayerDamageTakenEffectParams Params;
			Params.DamageAmount = DamageAmount;
			UPlayerDamageEffectHandler::Trigger_DamageTaken(Player, Params);
		}

		SavedDeathDamageParams = DeathImpactParams;

		if (DeathEffect.IsValid())
		{
			UDeathEffect Handler = NewObject(this, DeathEffect);
			Handler.DeathDamageParams = DeathImpactParams;
			Handler.bStaticCameraDeath = DeathImpactParams.bApplyStaticCamera;
			Handler.bDiedFromDamage = bDiedFromDamage;
			Handler.bUseDeathCamera = DeathImpactParams.bUseDeathCamera;
			// PrintScaled("" + Handler.Name, 5.0, FLinearColor::Red, 2.5);
			Player.RegisterEffectEventHandler(Handler);

			DeathEffectDuration = Handler.DeathEffectDuration;
			TagsBlockedDuringDeath = Handler.TagsBlockedDuringDeath;
			TagsBlockedUntilRespawn = Handler.TagsBlockedUntilRespawn;

			TagsBlockedDuringDeath.Add(n"BlockedWhileDead");
			TagsBlockedUntilRespawn.Add(n"BlockedWhileDead");

			for (FName Tag : TagsBlockedDuringDeath)
				Player.BlockCapabilities(Tag, this);

			if (Handler.bResetMovement)
				Player.ResetMovement();
		}

		DeathImpactData = DeathImpactParams;
		OnDeathTriggered.Broadcast();
	}

	TSubclassOf<UDamageEffect> GetUsedDamageEffect(TSubclassOf<UDamageEffect> DamageEffect)
	{
		if (DamageEffect.IsValid())
			return DamageEffect;
		if (HealthSettings.DefaultDamageEffect.IsValid())
			return HealthSettings.DefaultDamageEffect;
		if (DefaultDamageEffect.IsValid())
			return DefaultDamageEffect;
		return UDamageEffect;
	}

	void DamagePlayer(float DamageAmount, TSubclassOf<UDamageEffect> DamageEffect, TSubclassOf<UDeathEffect> DeathEffect, bool bApplyInvulnerability = true, FPlayerDeathDamageParams DeathDamageParams = FPlayerDeathDamageParams())
	{
		if (!HasControl())
			return;

		const bool bIsOneShot = (DamageAmount >= 1.0);
		if (!CanTakeDamage(bIsOneShot))
		{
			//Send an event if we avoided damage because of being invulnerable, this is rate limited so we can't spam network messages
			if (Time::GameTimeSeconds > AvoidedDamageCooldownTime)
			{
				AvoidedDamageCooldownTime = Time::GameTimeSeconds + 0.2;
				CrumbOnAvoidedDamageWithInvulnerability(DamageAmount, DamageEffect);
			}

			return;
		}

		if (WouldDieFromDamage(DamageAmount, bApplyInvulnerability))
		{
			// Damage was enough to kill the player
			check(CanDie());
			FVector DeathImpulse = UHazeMovementComponent::Get(Player).GetPendingImpulse();
			
			CrumbOnDeathAddDamageEffect(DamageEffect, DamageAmount);
			CrumbKillPlayer(GetUsedDeathEffect(DeathEffect, DeathDamageParams.bIsFallingDeath), bDiedFromDamage = true, DamageAmount = DamageAmount, DeathImpulse = DeathImpulse, DeathImpactParams = DeathDamageParams);
		}
		else
		{
			// Damage didn't kill the player
			CrumbDamagePlayer(DamageAmount, GetUsedDamageEffect(DamageEffect), DeathDamageParams, bApplyInvulnerability);
		}
	}

	void DealBatchedDamage(float DamageAmount, FPlayerDeathDamageParams DeathParams, TSubclassOf<UDamageEffect> DamageEffect = nullptr, TSubclassOf<UDeathEffect> DeathEffect = nullptr)
	{
		if (!HasControl())
			return;

		PendingBatchDeathParams = DeathParams;
		PendingBatchDamageEffect = DamageEffect;
		PendingBatchDeathEffect = DeathEffect;
		PendingBatchedDamage += DamageAmount;
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnDeathAddDamageEffect(TSubclassOf<UDamageEffect> DamageEffect, float DamageAmount)
	{
		FPlayerDamageTakenEffectParams Params;

		if (DamageEffect.IsValid())
		{
			Params.EffectSystem = DamageEffect.DefaultObject.OverrideRecieveDamageEffect[Player];
		}
	
		Params.DamageAmount = DamageAmount;
		UPlayerDamageEffectHandler::Trigger_DamageTaken(Player, Params);
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnAvoidedDamageWithInvulnerability(float DamageAmount, TSubclassOf<UDamageEffect> DamageEffect)
	{
		FPlayerDamageTakenEffectParams Params;

		if (DamageEffect.IsValid())
		{
			Params.EffectSystem = DamageEffect.DefaultObject.OverrideRecieveDamageEffect[Player];
			Params.EffectSoundDef = DamageEffect.DefaultObject.EffectSoundDef;
		}
	
		Params.DamageAmount = DamageAmount;
		UPlayerDamageEffectHandler::Trigger_AvoidedDamageByInvulnerable(Player, Params);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDamagePlayer(float DamageAmount, TSubclassOf<UDamageEffect> DamageEffect, FPlayerDeathDamageParams DeathDamageParams, bool bApplyInvulnerability = true)
	{
		Health.Damage(DamageAmount * GetDamageMultiplier());
		FPlayerDamageTakenEffectParams Params;
		UDamageEffect Effect = NewObject(this, DamageEffect);

		if (DamageEffect.IsValid())
		{
			// Show damage effect
			Effect.Activate();
			// PrintScaled("" + Effect.Name, 5.0, FLinearColor::Purple, 1.5);

			auto Settings = UDeathRespawnEffectSettings::GetSettings(Player);
			if (Effect.OverrideRecieveDamageEffect[Player] != nullptr)
				Params.EffectSystem = Effect.OverrideRecieveDamageEffect[Player];
			else
				Params.EffectSystem = Settings.DefaultRecieveDamageEffect[Player];

			Params.DeathDamageParams = DeathDamageParams;

			if (Effect.bActive)
				DamageEffects.Add(Effect);
		}

		Params.DamageAmount = DamageAmount;
		UPlayerDamageEffectHandler::Trigger_DamageTaken(Player, Params);
		Effect.DamageTaken(Params);

		BroadcastHealthUpdated();
		OnPlayerTookDamage.Broadcast(Player, DamageAmount);

		if (HealthSettings.InvulnerabilityDurationAfterTakingDamage > 0.0 && bApplyInvulnerability)
		{
			AddDamageInvulnerability(n"DamageTaken", HealthSettings.InvulnerabilityDurationAfterTakingDamage, true);
			FlashInvulnerability(FlashColor_Damage, 0.5, 0.3);
		}
		if ((HealthSettings.SecondChanceWhenKilledDuration > 0.0) && bApplyInvulnerability && 
			(SecondChanceImmortalityTime == 0.0) && (Health.CurrentHealth < SMALL_NUMBER))
		{
			SecondChanceImmortalityTime = Time::GameTimeSeconds + HealthSettings.SecondChanceWhenKilledDuration;
			FlashInvulnerability(FlashColor_Damage, 0.5, 0.3);
		}
	}

	void HealPlayer(float HealAmount)
	{
		if (Health.CurrentHealth >= 1.0)
			return;
		CrumbHealPlayer(HealAmount);
	}

	UFUNCTION(CrumbFunction)
	void CrumbHealPlayer(float HealAmount)
	{
		Health.Heal(HealAmount);

		FPlayerHealedEffectParams Params;
		Params.HealAmount = HealAmount;
		UPlayerDamageEffectHandler::Trigger_Healed(Player, Params);

		BroadcastHealthUpdated();
	}

	void TriggerGameOver()
	{
		if (!bIsGameOver)
			CrumbGameOver();
	}

	UFUNCTION(CrumbFunction)
	void CrumbGameOver()
	{
		bIsGameOver = true;

		auto OtherHealthComp = UPlayerHealthComponent::Get(Player.OtherPlayer);
		OtherHealthComp.bIsGameOver = true;
	}

	FPlayerDeathDamageParams GetSavedDeathDamageParams()
	{
		return SavedDeathDamageParams;
	}
};