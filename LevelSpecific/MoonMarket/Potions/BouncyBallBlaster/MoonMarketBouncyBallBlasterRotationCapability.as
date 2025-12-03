class UMoonMarketBouncyBallBlasterRotationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;
	UMoonMarketBouncyBallBlasterPotionComponent BallBlasterComp;

	FHazeAcceleratedRotator AccRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		BallBlasterComp = UMoonMarketBouncyBallBlasterPotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BallBlasterComp.BallBlaster == nullptr)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BallBlasterComp.TargetRotation = BallBlasterComp.BallBlaster.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccRot.SpringTo(BallBlasterComp.TargetRotation, 700, 0.5, DeltaTime);
		BallBlasterComp.BallBlaster.SetActorRotation(AccRot.Value);

		if(!BallBlasterComp.bIsShooting && !MoveComp.HorizontalVelocity.IsNearlyZero())
		{
			float Yaw = MoveComp.Velocity.ToOrientationRotator().Yaw;
			BallBlasterComp.TargetRotation = FRotator(0, Yaw, 0.0);
		}
	}
};