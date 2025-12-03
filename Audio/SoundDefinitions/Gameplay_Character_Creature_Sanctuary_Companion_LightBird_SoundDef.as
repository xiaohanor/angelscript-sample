
UCLASS(Abstract)
class UGameplay_Character_Creature_Sanctuary_Companion_LightBird_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnCompanionFollowCentipedeStop(){}

	UFUNCTION(BlueprintEvent)
	void OnCompanionFollowCentipedeStart(){}

	UFUNCTION(BlueprintEvent)
	void OnCompanionFollowSlidingDiscStop(){}

	UFUNCTION(BlueprintEvent)
	void OnCompanionFollowSlidingDiscStart(){}

	UFUNCTION(BlueprintEvent)
	void InvestigateAttachStopped(){}

	UFUNCTION(BlueprintEvent)
	void InvestigateAttachStarted(){}

	UFUNCTION(BlueprintEvent)
	void InvestigateStopped(){}

	UFUNCTION(BlueprintEvent)
	void InvestigateStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnCompanionIntroReachedPlayer(){}

	UFUNCTION(BlueprintEvent)
	void OnCompanionIntroStart(){}

	UFUNCTION(BlueprintEvent)
	void WatsonTeleport(){}

	UFUNCTION(BlueprintEvent)
	void Unilluminated(){}

	UFUNCTION(BlueprintEvent)
	void Illuminated(){}

	UFUNCTION(BlueprintEvent)
	void RecallReturned(){}

	UFUNCTION(BlueprintEvent)
	void RecallStopped(){}

	UFUNCTION(BlueprintEvent)
	void RecallStarted(){}

	UFUNCTION(BlueprintEvent)
	void AttachedTargetStopped(){}

	UFUNCTION(BlueprintEvent)
	void AttachedTarget(){}

	UFUNCTION(BlueprintEvent)
	void LaunchFailedToAttach(){}

	UFUNCTION(BlueprintEvent)
	void LaunchStopped(){}

	UFUNCTION(BlueprintEvent)
	void LaunchStarted(){}

	UFUNCTION(BlueprintEvent)
	void ReleaseStopped(){}

	UFUNCTION(BlueprintEvent)
	void ReleaseStarted(){}

	UFUNCTION(BlueprintEvent)
	void Absorbed(){}

	/* END OF AUTO-GENERATED CODE */

	AAISanctuaryLightBirdCompanion LightBird;
	ULightBirdUserComponent LightBirdUser;
	USanctuaryLightBirdCompanionSettings BirdSettings;

	private FVector LastBirdLocation;
	private FVector CachedBirdVelo;
	private float CachedBirdSpeed;

	UPROPERTY(BlueprintReadWrite, Category = "Attenuation")
	float LightBirdMaxDistanceAttenuationPadding = 3000.0;

	FVector GetBirdLocation() const property
	{
		return LightBird.Mesh.WorldLocation;
	}

	AHazePlayerCharacter GetBirdPlayer() const property
	{
		return LightBird.CompanionComp.Player;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		LightBird = Cast<AAISanctuaryLightBirdCompanion>(HazeOwner);
		LightBirdUser = ULightBirdUserComponent::Get(BirdPlayer);
		BirdSettings = USanctuaryLightBirdCompanionSettings::GetSettings(HazeOwner);

		DefaultEmitter.SetPlayerPanning(BirdPlayer);
		DefaultEmitter.SetAttenuationScaling(BirdSettings.AutoRecallRange + LightBirdMaxDistanceAttenuationPadding);

		auto PlayerMovementAudioComp = UHazeMovementAudioComponent::Get(BirdPlayer);
		PlayerMovementAudioComp.LinkMovementRequests(LightBird.AudioMoveComp);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (LightBirdUser.bIsIntroducing)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (LightBirdUser.bIsIntroducing)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ProxyEmitterSoundDef::LinkToActor(this, BirdPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		auto CurrentLocation = BirdLocation;

		CachedBirdVelo = CurrentLocation - LastBirdLocation;
		CachedBirdSpeed = CachedBirdVelo.Size() / DeltaSeconds;

		LastBirdLocation = CurrentLocation;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Bird Speed"))
	float GetBirdSpeed()
	{
		return CachedBirdSpeed;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Bird Launch Alpha"))
	float GetBirdLaunchAlpha()
	{
		return LightBird.AudioComp.LaunchDistanceAlpha;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Bird Recall Alpha"))
	float GetBirdRecallAlpha()
	{
		return LightBird.AudioComp.RecallDistanceAlpha;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Bird State"))
	ELightBirdCompanionState GetBirdState()
	{
		return LightBird.CompanionComp.State;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Bird Max Launch Speed"))
	float GetMaxLaunchSpeed()
	{
		return LightBird::Launch::MaximumSpeed;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Bird Launch Acceleration Time"))
	float GetTimeToLaunchMaxSpeed()
	{
		return BirdSettings.LaunchAccelerationDuration;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Bird Max Recall Speed"))
	float GetMaxRecallSpeed()
	{
		return LightBird::Recall::MaximumSpeed;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Bird Max Recall Range"))
	float GetMaxRecallRange()
	{
				// Keep in sync with default value set in ULightBirdTargetComponent;
		return 5000.0;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Bird Max Aim Range"))
	float GetMaxAimRange()
	{
		return LightBird::Aim::Range;
	}

}