namespace SwarmDroneHijack
{
	FVector GetMovementInput(const AHazePlayerCharacter Player, const FVector2D RawInput, const FVector UpVector, bool bDrawDebug = false)
	{
		const FRotator ControlRotation = Player.GetControlRotation();

		FVector ForwardVector;
		FVector RightVector;

		if(Math::Abs(UpVector.Z) > 0.5)
		{
			ForwardVector = ControlRotation.ForwardVector.VectorPlaneProject(UpVector).GetSafeNormal();
			RightVector = ControlRotation.RightVector.VectorPlaneProject(UpVector).GetSafeNormal();
		}
		else
		{
			ForwardVector = FVector::UpVector;
			RightVector = UpVector.CrossProduct(FVector::UpVector).GetSafeNormal();
		}

		FVector MovementInput = (ForwardVector * Math::Pow(RawInput.X, 2.0) * Math::Sign(RawInput.X)) + (RightVector * Math::Pow(RawInput.Y, 2.0) * Math::Sign(RawInput.Y));

		if (bDrawDebug)
			Debug::DrawDebugDirectionArrow(Player.ActorLocation, MovementInput, MovementInput.Size() * 200.0, 5, FLinearColor::DPink);

		return MovementInput;
	}

	FTransform GetRandomWorldDiveTransformForHijackable(const USwarmDroneHijackTargetableComponent HijackComponent)
	{
		// Get area info
		FSwarmDroneHijackTargetRectangle TargetArea = HijackComponent.MakeBotDiveTargetRectangle();

		FVector RightVector = TargetArea.PlaneNormal.GetSafeNormal().CrossProduct(FVector::UpVector);
		FVector Binormal = TargetArea.PlaneNormal.CrossProduct(RightVector).GetSafeNormal();

		// Get random location in X
		float Width = TargetArea.Size.X;
		FVector HorizontalOffset = RightVector * Math::RandRange(-Width, Width);

		// Get random location in Y
		float Height = TargetArea.Size.Y;
		FVector VerticalOffset = Binormal * Math::RandRange(-Height, Height);

		FVector WorldLocation = TargetArea.WorldOrigin + HorizontalOffset + VerticalOffset;
		FQuat WorldRotation = FQuat::MakeFromZ(TargetArea.PlaneNormal);

		return FTransform(WorldRotation, WorldLocation);
	}
}