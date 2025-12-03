class USolarFlarePlayerBlackHoleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASolarFlarePlayerBlackHoleManager BlackholeManager;
	USolarFlarePlayerBlackHoleComponent UserComp;

	FHazeAcceleratedFloat AccelFloat;

	FVector Direction;
	
	float TargetSpeed = 8000.0; 
	float TargetFOV = 35.0;
	float CurrentFOV;
	float TargetIdealDistance = -12000;
	float CurrentIdealDistance;
	float ShakeAlpha;
	float RumbleAlpha;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USolarFlarePlayerBlackHoleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bIsEnabled)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bIsEnabled)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (BlackholeManager == nullptr)
			BlackholeManager = TListedActors<ASolarFlarePlayerBlackHoleManager>().GetSingle();

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		AccelFloat.SnapTo(0.0);
		Direction = (UserComp.FallTarget.ActorLocation - Player.ActorLocation).GetSafeNormal();

		FHazeSlotAnimSettings Settings;
		Settings.BlendTime = 0.5;
		Settings.bLoop = true;
		Player.PlaySlotAnimation(UserComp.AnimBlackHoleFalling[Player], Settings);

		RumbleAlpha = 0.0;
		ShakeAlpha = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.StopAllSlotAnimations(0.3);
		Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ShakeAlpha = Math::FInterpConstantTo(ShakeAlpha, 1.0, DeltaTime, 0.25);
		RumbleAlpha = Math::FInterpConstantTo(ShakeAlpha, 1.0, DeltaTime, 0.25);

		AccelFloat.AccelerateTo(TargetSpeed, 4.0, DeltaTime);
		Player.ActorLocation += Direction * AccelFloat.Value * DeltaTime;

		CurrentFOV = Math::FInterpConstantTo(CurrentFOV, TargetFOV, DeltaTime, TargetFOV / 3.0);
		CurrentIdealDistance = Math::FInterpConstantTo(CurrentIdealDistance, TargetIdealDistance, DeltaTime, -TargetIdealDistance / 3);

		UCameraSettings::GetSettings(Player).CameraOffset.ApplyAsAdditive(FVector(CurrentIdealDistance, 0, 0), this);
		FVector Value = UCameraSettings::GetSettings(Player).CameraOffset.Value;
		
		Player.PlayCameraShake(UserComp.CameraShake, this, ShakeAlpha);

		FHazeFrameForceFeedback ForceFeedback;
		ForceFeedback.LeftMotor = RumbleAlpha;
		ForceFeedback.RightMotor = RumbleAlpha;
		ForceFeedback.LeftTrigger = RumbleAlpha;
		ForceFeedback.RightTrigger = RumbleAlpha;

		Player.SetFrameForceFeedback(ForceFeedback);
	}
};