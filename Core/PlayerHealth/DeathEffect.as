struct FRespawnLocationEventData
{
	UPROPERTY()
	FTransform RespawnTransform;
	UPROPERTY()
	USceneComponent RespawnRelativeTo;
	UPROPERTY()
	ARespawnPoint RespawnPoint;
};

enum EDeathEffectType
{
	Generic,
	ProjectilesSmall,
	ProjectilesLarge,
	FireSoft,
	FireImpact,
	Lava,
	ElectricitySoft,
	ElectricityImpact,
	ObjectSmall,
	ObjectLarge,
	ObjectSharp,
	LaserSoft,
	LaserHeavy,
	Water,
	Poison,
	GroundImpact,
	Explosion,
	FallingInAir,
	Ghost,
	ForceField,
	Eaten,
	Suffocate
}

class UDeathEffect : UHazeEffectEventHandler
{
	// How long the death effect should last before the player finishes dying
	UPROPERTY(EditDefaultsOnly)
	float DeathEffectDuration = 0.5;

	UPROPERTY()
	bool bStaticCameraDeath = false;
	bool bUseDeathCamera = true;

	// Capability tags blocked while the death effect is playing
	UPROPERTY(EditDefaultsOnly)
	TArray<FName> TagsBlockedDuringDeath;
	default TagsBlockedDuringDeath.Add(CapabilityTags::Movement);
	default TagsBlockedDuringDeath.Add(CapabilityTags::GameplayAction);
	default TagsBlockedDuringDeath.Add(CapabilityTags::Visibility);
	default TagsBlockedDuringDeath.Add(n"ContextualMoves");

	// Capability tags blocked after the death effect is finished
	UPROPERTY(EditDefaultsOnly)
	TArray<FName> TagsBlockedUntilRespawn;
	default TagsBlockedUntilRespawn.Add(CapabilityTags::Movement);
	default TagsBlockedUntilRespawn.Add(CapabilityTags::GameplayAction);
	default TagsBlockedUntilRespawn.Add(CapabilityTags::Visibility);
	default TagsBlockedUntilRespawn.Add(CapabilityTags::Collision);
	default TagsBlockedUntilRespawn.Add(n"ContextualMoves");

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference VOSoundDef;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference EffectSoundDef;

	UPROPERTY(EditDefaultsOnly)
	EDeathEffectType DeathEffectType;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FPlayerDeathDamageParams DeathDamageParams;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> DeathCameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect DeathForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	bool bUseGlitchParticles = true;

	// Whether to reset movement when the death effect triggers
	UPROPERTY(EditDefaultsOnly)
	bool bResetMovement = true;

	// Whether the player died from damage or not
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bDiedFromDamage = false;

	// Impulse that the player had pending when they died
	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector DeathImpulse;

	// Player that died and caused this effect
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UDeathRespawnEffectSettings EffectSettings;

    UPROPERTY(EditAnywhere)
    UNiagaraSystem DefaultDeathParticleEffect;

	UPROPERTY(Category = "Default Death Settings")
	float UnitOffset = 100.0;

	UPROPERTY(Category = "Default Death Settings")
	float SphereSize = 100.0;

	UFUNCTION(BlueprintOverride, Meta = (AutoCreateBPNode))
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		EffectSettings = UDeathRespawnEffectSettings::GetSettings(Player);
		
		auto DeathAudioComp = UPlayerDeathDamageAudioComponent::GetOrCreate(Player);
		if (DeathAudioComp != nullptr)
		{
			DeathAudioComp.AttachSoundDef(this, VOSoundDef);
			DeathAudioComp.AttachSoundDef(this, EffectSoundDef);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		auto DeathAudioComp = UPlayerDeathDamageAudioComponent::GetOrCreate(Player);
		if (DeathAudioComp != nullptr)
		{
			DeathAudioComp.RemoveSoundDef(this, VOSoundDef);
			DeathAudioComp.RemoveSoundDef(this, EffectSoundDef);
		}
	}

	/**
	 * The player has just died right now.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Died() {}

	/**
	 * The player finished dying, the duration of the death effect has expired.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishedDying() {}


	/**
	 * The player's respawn has started.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RespawnStarted() {}

	/**
	 * The player's respawn has finished, and the player can now move again.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RespawnTriggered() {}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	private void DeathAndRespawnCycleCompleted()
	{
		// Unregister ourselves after the entire death cycle is finished
		Player.UnregisterEffectEventHandler(this);
	}

	/**
	 * The widget pulses during respawn due to mash
	*/
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawnPulseMash() {}

	UFUNCTION()
	void PlayCameraShakeAndRumble()
	{
		if (!SceneView::IsFullScreen())
			Player.PlayCameraShake(DeathCameraShake, this);

		Player.PlayForceFeedback(DeathForceFeedback, false, true,  this);
	}

	UFUNCTION(BlueprintPure)
	FVector GetDeathForceLocation(FVector Direction, float CurrentUnitOffset = 50.0)
	{
		auto Settings = UDeathRespawnEffectSettings::GetSettings(Player);
		FVector PlayerCenterLocation = Player.ActorCenterLocation;
		PlayerCenterLocation += Settings.PlayerCenterLocationOffset;

		if (Direction.Size() == 0.0)
		{
#if EDITOR
			if (Settings.bDebugDrawCenterPositionOnDeath)
			{
				PrintToScreen(f"{this} is debug drawing death location for {Player}", 10, FLinearColor::Green);
				Debug::DrawDebugSphere(PlayerCenterLocation, 25.0, 12, FLinearColor::Green, 5.0, 10.0);
			}
#endif
			return PlayerCenterLocation;
		}
		else
		{
#if EDITOR
			if (Settings.bDebugDrawCenterPositionOnDeath)
			{
				PrintToScreen(f"{this} is debug drawing death location for {Player}", 10, FLinearColor::Green);
				Debug::DrawDebugSphere(PlayerCenterLocation - (Direction * CurrentUnitOffset), 25.0, 12, FLinearColor::Green, 5.0, 10.0);
			}
#endif
			return PlayerCenterLocation - (Direction * CurrentUnitOffset);
		}
	}

	UFUNCTION(BlueprintPure)
	UNiagaraSystem GetCharacterDeathEffect()
	{
		if (Game::IsPlatformSage())
			return EffectSettings.DeathParticleEffectOverride != nullptr ? EffectSettings.DeathParticleEffectOverride : EffectSettings.DeathParticleEffect;
		else
			return EffectSettings.DeathParticleEffect;
	}
};