
UCLASS(Abstract)
class UGameplay_Character_Creature_Sanctuary_Companion_DarkPortal_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void CompanionRecallStarted(){}

	UFUNCTION(BlueprintEvent)
	void CompanionLaunchStopped(){}

	UFUNCTION(BlueprintEvent)
	void Launched(){}

	UFUNCTION(BlueprintEvent)
	void PlayerAimStart(){}

	UFUNCTION(BlueprintEvent)
	void PlayerAimStop(){}

	UFUNCTION(BlueprintEvent)
	void GrabActivated(){}

	UFUNCTION(BlueprintEvent)
	void GrabDeactivated(){}

	/* END OF AUTO-GENERATED CODE */

	AAISanctuaryDarkPortalCompanion DarkPortal;
	UDarkPortalUserComponent DarkPortalUser;
	USanctuaryDarkPortalCompanionSettings DarkPortalSettings;

	private FVector LastDarkPortalLocation;
	private FVector LastDarkPortalPlayerLocation;
	private FVector CachedDarkPortalVelo;
	private FVector PreviousTailLocation;
	private FVector PreviousDarkPortalHandLocation;
	private FVector PreviousDarkPortalHandForward;

	private float CachedDarkPortalSpeed;
	private float CachedDarkPortalTailSpeed;
	private float CachedDarkPortalTailSpeedDelta;
	private float CachedDarkPortalPlayerHandSpeed;
	private float CachedDarkPortalPlayerHandSpeedDelta;
	private float CachedDarkPortalPlayerHandRotationDot;

	const float MAX_TAIL_RELATIVE_SPEED = 750.0;
	const float MAX_TAIL_RELATIVE_SPEED_DELTA = 100.0;

	UPROPERTY(BlueprintReadWrite, Category = "Attenuation")
	float DarkPortalMaxDistanceAttenuationPadding = 3000.0;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter PlayerDarkPortalHandEmitter;

	FVector GetDarkPortalTailLocation() const property
	{
		return DarkPortal.Mesh.GetSocketLocation(n"TailFin2");
	}

	FVector GetDarkPortalLocation() const property
	{
		return DarkPortal.Mesh.WorldLocation;
	}

	AHazePlayerCharacter GetDarkPortalPlayer() const property
	{
		return DarkPortal.CompanionComp.Player;
	}

	FVector GetDarkPortalPlayerHandLocation() const property
	{
		return DarkPortalPlayer.Mesh.GetSocketLocation(n"RightHandVFXAttach");
	}

	FVector GetDarkPortalPlayerHandForward() const property
	{
		return DarkPortalPlayer.Mesh.GetSocketRotation(n"RightHandVFXAttach").ForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkPortal = Cast<AAISanctuaryDarkPortalCompanion>(HazeOwner);
		DarkPortalUser = UDarkPortalUserComponent::Get(DarkPortalPlayer);
		DarkPortalSettings = USanctuaryDarkPortalCompanionSettings::GetSettings(HazeOwner);

		DefaultEmitter.SetPlayerPanning(DarkPortalPlayer);
		DefaultEmitter.SetAttenuationScaling(DarkPortalSettings.AutoRecallRange + DarkPortalMaxDistanceAttenuationPadding);

		PlayerDarkPortalHandEmitter.SetPlayerPanning(DarkPortalPlayer);
		PlayerDarkPortalHandEmitter.AudioComponent.AttachToComponent(DarkPortalPlayer.Mesh, n"RightHandVFXAttach");
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"PlayerDarkPortalHandEmitter")
		{	
			bUseAttach = false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DarkPortalUser.bCompanionEnabled)
			return false;

		if (DarkPortalUser.bIsIntroducing)
			return false;

		// if(DarkPortalUser.Portal.IsSettled())
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DarkPortalUser.bCompanionEnabled)
			return true;

		if (DarkPortalUser.bIsIntroducing)
			return true;

		// if(DarkPortalUser.Portal.IsSettled())
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ProxyEmitterSoundDef::LinkToActor(this, DarkPortalPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		auto CurrentLocation = DarkPortalLocation;
		auto CurrentDarkPortalPlayerLocation = DarkPortalPlayer.ActorLocation;
		auto DarkPortalPlayerVelo = CurrentDarkPortalPlayerLocation - LastDarkPortalPlayerLocation;

		CachedDarkPortalVelo = CurrentLocation - LastDarkPortalLocation;
		CachedDarkPortalSpeed = CachedDarkPortalVelo.Size() / DeltaSeconds;

		auto CurrentTailRotation = DarkPortalTailLocation;
		auto TailVelo = CurrentTailRotation - PreviousTailLocation;

		auto CurrentTailSpeed = (TailVelo - CachedDarkPortalVelo).Size() / DeltaSeconds;
		CachedDarkPortalTailSpeedDelta = CurrentTailSpeed - CachedDarkPortalTailSpeed;
		CachedDarkPortalTailSpeed = CurrentTailSpeed;

		auto CurrentPlayerHandLocation = DarkPortalPlayerHandLocation;
		auto HandVelo = CurrentPlayerHandLocation - PreviousDarkPortalHandLocation;
		auto HandSpeed = (HandVelo - DarkPortalPlayerVelo).Size() / DeltaSeconds;

		auto CurrentPlayerHandForward = DarkPortalPlayerHandForward;
		CachedDarkPortalPlayerHandRotationDot = Math::DotToDegrees(CurrentPlayerHandForward.DotProduct(PreviousDarkPortalHandForward));
		auto RotationSign = Math::Sign(CurrentPlayerHandLocation.DotProduct(DarkPortalPlayer.ActorRightVector));
		

		CachedDarkPortalPlayerHandSpeedDelta = HandSpeed - CachedDarkPortalPlayerHandSpeed;
		CachedDarkPortalPlayerHandSpeed = HandSpeed;
		PreviousDarkPortalHandForward = CurrentPlayerHandForward;

		PreviousTailLocation = CurrentTailRotation;		
		LastDarkPortalLocation = CurrentLocation;
		PreviousDarkPortalHandLocation = CurrentPlayerHandLocation;
		LastDarkPortalPlayerLocation = CurrentDarkPortalPlayerLocation;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Dark Portal Speed"))
	float GetPortalSpeed()
	{
		return CachedDarkPortalSpeed;
	}

	UFUNCTION(BlueprintPure)
	void GetPortalTailSpeed(float&out Speed, float&out Delta)
	{
		Speed = Math::Min(1, CachedDarkPortalTailSpeed / MAX_TAIL_RELATIVE_SPEED);
		Delta = Math::Clamp(CachedDarkPortalTailSpeedDelta / MAX_TAIL_RELATIVE_SPEED_DELTA, -1, 1);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Dark Portal Launch Alpha"))
	float GetPortalLaunchAlpha()
	{
		return DarkPortal.AudioComp.LaunchDistanceAlpha;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Dark Portal Recall Alpha"))
	float GetPortalRecallAlpha()
	{
		return DarkPortal.AudioComp.RecallDistanceAlpha;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Dark Portal State"))
	EDarkPortalCompanionState GetDarkPortalState()
	{
		return DarkPortal.CompanionComp.State;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Dark Portal Max Launch Speed"))
	float GetMaxLaunchSpeed()
	{
		return DarkPortal::Launch::MaximumSpeed;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Dark Portal Launch Acceleration Time"))
	float GetTimeToLaunchMaxSpeed()
	{
		return DarkPortalSettings.LaunchAccelerationDuration;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Dark Portal Max Recall Speed"))
	float GetMaxRecallSpeed()
	{
		return DarkPortal::Recall::MaximumSpeed;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Dark Portal Max Recall Range"))
	float GetMaxRecallRange()
	{
		return DarkPortal::Grab::Range;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Dark Portal Max Aim Range"))
	float GetMaxAimRange()
	{
		return DarkPortal::Aim::Range;
	}

	UFUNCTION(BlueprintPure)
	void GetDarkPortalPlayerHandEmitterMovement(float&out Delta, float&out RotationDot)
	{
		Delta = CachedDarkPortalPlayerHandSpeedDelta;
		RotationDot = CachedDarkPortalPlayerHandRotationDot;
	}

}