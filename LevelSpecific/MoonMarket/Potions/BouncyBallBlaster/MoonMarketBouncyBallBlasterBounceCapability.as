class UMoonMarketBouncyBallBlasterBounceCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UHazeMovementComponent MoveComp;
	UMoonMarketBouncyBallBlasterPotionComponent BallBlasterComp;

	float AnimationDuration = 0.6;
	float JumpHeight = 50;

	float TimeScaledActiveDuration = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		BallBlasterComp = UMoonMarketBouncyBallBlasterPotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.HasGroundContact())
			return false;

		if(MoveComp.MovementInput.IsNearlyZero())
			return false;

		if(BallBlasterComp.BallBlaster == nullptr)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TimeScaledActiveDuration >= AnimationDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TimeScaledActiveDuration = 0;
		UMoonMarketBouncyBallBlasterEventHandler::Trigger_OnBounce(BallBlasterComp.BallBlaster);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TimeScaledActiveDuration += DeltaTime;

		const float Alpha = Math::Saturate(TimeScaledActiveDuration / AnimationDuration);

		const float MaxSpeed = 250;
		float Multiplier = 1;

		float ZScale = 1 + ((BallBlasterComp.ZScaleCurve.GetFloatValue(Alpha) - 1) * Multiplier);
		
		const float HorizontalSquashMultiplier = 0.5;
		float XYScale = 1 - ((BallBlasterComp.ZScaleCurve.GetFloatValue(Alpha) - 1) * Multiplier * HorizontalSquashMultiplier);

		BallBlasterComp.BallBlaster.MeshScaler.SetWorldScale3D(FVector(XYScale, XYScale, ZScale));

		float ZOffset = BallBlasterComp.JumpHeightCurve.GetFloatValue(Alpha) * JumpHeight * Multiplier;
		BallBlasterComp.BallBlaster.MeshScaler.SetRelativeLocation(FVector::UpVector * ZOffset);
	}
};