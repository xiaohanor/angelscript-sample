class UDentistSplitToothAIResetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);

	default TickGroup = EHazeTickGroup::Input;

	ADentistSplitToothAI SplitToothAI;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothAI = Cast<ADentistSplitToothAI>(Owner);
		MoveComp = SplitToothAI.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto CircleConstraint = ADentistSplitToothAICircleConstraint::Get();
		if(CircleConstraint == nullptr)
			return false;

		FVector RelativeLocation = CircleConstraint.ActorTransform.InverseTransformPositionNoScale(SplitToothAI.ActorLocation);
		if(RelativeLocation.Z < -2000)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto CircleConstraint = ADentistSplitToothAICircleConstraint::Get();
		SplitToothAI.TeleportActor(
			CircleConstraint.ActorTransform.TransformPositionNoScale(FVector(0, 0, (SplitToothAI.CollisionComp.CapsuleHalfHeight * 2) + 20)),
			FRotator::MakeFromZX(FVector::UpVector, SplitToothAI.ActorForwardVector),
			this
		);

		// Make sure we are on the ground
		MoveComp.SnapToGround(false);
	}
};