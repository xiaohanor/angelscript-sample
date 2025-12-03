class UTundraPlayerFairyLeapActiveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(PlayerMovementTags::AirJump);
	default CapabilityTags.Add(TundraShapeshiftingTags::TundraLeap);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);

	UTundraPlayerFairyComponent FairyComp;
	UPlayerMovementComponent MoveComp;
	UTundraPlayerFairySettings Settings;
	UCameraUserComponent CameraUser;
	FHazeAcceleratedFloat AccTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!FairyComp.bIsLeaping)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!FairyComp.bIsLeaping)
			return true;

		if(!FairyComp.bIsActive)
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UTundraPlayerFairyEffectHandler::Trigger_OnStartLeapSession(FairyComp.FairyActor);

		Player.ApplyCameraSettings(FairyComp.CameraSettingsInLeap, 0.5, FairyComp, SubPriority = 61);
		FairyComp.bResetLeapSession = false;
		AccTime.SnapTo(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UTundraPlayerFairyEffectHandler::Trigger_OnEndLeapSession(FairyComp.FairyActor);
		FairyComp.bIsLeaping = false;
		FairyComp.LeapAirControlVelocity = FVector::ZeroVector;
		FairyComp.LeapDirection = FVector::ZeroVector;
		FairyComp.LastLeapSessionHeight = FairyComp.HeightOfLeapSession;

		Player.ClearCameraSettingsByInstigator(FairyComp, 0.5);

		UCameraSettings::GetSettings(Player).WorldPivotOffset.Clear(this, 0.3);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CurrentOffset = FairyComp.HeightOfLeapSession - Player.ActorLocation.Z;

		float TargetTime = 1.0;
		if(CurrentOffset < 0.0)
		{
			FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
			FHitResult Hit = Trace.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation + FVector::UpVector * CurrentOffset);
			if(Hit.bBlockingHit)
				TargetTime = Hit.Time;
		}
		AccTime.AccelerateTo(TargetTime, 0.5, DeltaTime);

#if !RELEASE
		TEMPORAL_LOG(this).Value("Current Offset", CurrentOffset);
		TEMPORAL_LOG(this).Value("TargetTime", TargetTime);
		TEMPORAL_LOG(this).Value("AccTime", AccTime.Value);
#endif

		UCameraSettings::GetSettings(Player).WorldPivotOffset.ApplyAsAdditive(FVector::UpVector * (CurrentOffset * AccTime.Value), this);
		FairyComp.LeapSessionDuration += DeltaTime;
	}
}