class UAdultDragonChaseBoundaryCapability : UHazePlayerCapability
{
	// NOT SURE IF THIS IS USED SO I COMMENTED OUT EVERYTHING
	// FREDRIK

	// default CapabilityTags.Add(n"AdultDragonChaseBoundaryCapability");

	// default TickGroup = EHazeTickGroup::AfterGameplay;

	// UPlayerAdultDragonComponent DragonComp;
	// UAdultDragonChaseStrafeComponent ChaseStrafeComp;
	// UPlayerMovementComponent MoveComp;
	// FVector TowardsCenter;
	// float SteeringWeight;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	DragonComp = UPlayerAdultDragonComponent::Get(Player);
	// 	ChaseStrafeComp = UAdultDragonChaseStrafeComponent::Get(Player);
	// 	MoveComp = UPlayerMovementComponent::Get(Player);
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if(AdultDragon.CurrentChaseBoundary == nullptr)
	// 		return false;

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if(AdultDragon.CurrentChaseBoundary == nullptr)
	// 		return true;

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {
	// 	TowardsCenter = AdultDragon.CurrentChaseBoundary.ActorForwardVector;
	// 	ChaseStrafeComp.bCanChaseStrafe = false;
	// 	// Print("TowardsCenter: " + TowardsCenter);
	// 	SteeringWeight = AdultDragon.CurrentChaseBoundary.SteeringWeight;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	ChaseStrafeComp.ForwardDirection = TowardsCenter;

	// 	if (!ChaseStrafeComp.bShouldExitStrafe)
	// 		ChaseStrafeComp.bCanChaseStrafe = true;
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	FQuat RotToCenter = FRotator::MakeFromXZ(TowardsCenter, Player.ActorUpVector).Quaternion();
		
	// 	FVector MovementInput = MoveComp.MovementInput;
	// 	FRotator SteeringRotator;
	// 	SteeringRotator.Yaw = MovementInput.Y;
	// 	SteeringRotator.Pitch = MovementInput.X;

	// 	FQuat SteeringWorldSpace = Player.ActorTransform.TransformRotation(SteeringRotator.Quaternion());
	// 	SteeringWorldSpace = Math::QInterpConstantTo(SteeringWorldSpace, RotToCenter, DeltaTime, SteeringWeight);

	// 	FQuat InfluencedSteeringLocalSpace = Player.ActorTransform.InverseTransformRotation(SteeringWorldSpace);
	// 	SteeringRotator = InfluencedSteeringLocalSpace.Rotator().Normalized;

	// 	MovementInput.Y = SteeringRotator.Yaw;
	// 	MovementInput.X = SteeringRotator.Pitch;

	// 	Player.ApplyMovementInput(MovementInput, this, EInstigatePriority::High);

	// 	DragonComp.AnimParams.Pitching = MovementInput.X;
	// 	DragonComp.AnimParams.Banking = MovementInput.Y;
		
	// 	float Dot = AdultDragon.ActorForwardVector.DotProduct(TowardsCenter);

	// 	if (Dot > 0.95)
	// 		AdultDragon.RemoveChaseBoundary();
	// }
}