class USketchbookGoatInputCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Input;

	ASketchbookGoat Goat;
	USketchbookGoatSplineMovementComponent SplineComp;

	TOptional<float> PreviousHorizontalInput = 0;
	bool bStartedInputtingWhileUpsideDown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Goat = Cast<ASketchbookGoat>(Owner);
		SplineComp = USketchbookGoatSplineMovementComponent::Get(Goat);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Goat.SyncedHorizontalInput.Value = 0;
		Goat.SyncedRawInput.Value = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float HorizontalInput = GetAttributeFloat(AttributeNames::LeftStickRawX);
		float VerticalInput = GetAttributeFloat(AttributeNames::LeftStickRawY);

		Goat.SyncedRawInput.SetValue(FVector(0, HorizontalInput, VerticalInput));

		if(InputStartedOrFlippedThisFrame(HorizontalInput) && Goat.MoveComp.WorldUp.Z < 0)
		{
			// New input in loop!
			bStartedInputtingWhileUpsideDown = true;
		}
		else if(Math::IsNearlyZero(HorizontalInput))
		{
			bStartedInputtingWhileUpsideDown = false;
		}

		if(bStartedInputtingWhileUpsideDown)
			HorizontalInput = -HorizontalInput;

		if(SplineComp.IsInAir())
		{
			HorizontalInput = GetAirHorizontalInput(HorizontalInput, VerticalInput);
		}
		else
		{
			HorizontalInput = GetGroundHorizontalInput(HorizontalInput, VerticalInput);
		}

		Goat.SyncedHorizontalInput.SetValue(HorizontalInput);

		if(Math::Abs(HorizontalInput) > KINDA_SMALL_NUMBER)
		{
			PreviousHorizontalInput = HorizontalInput;
		}
		else
		{
			PreviousHorizontalInput.Reset();
		}
	}

	float GetAirHorizontalInput(float HorizontalInput, float VerticalInput)
	{
		const FVector WorldRight = FVector::RightVector.VectorPlaneProject(Goat.MoveComp.WorldUp).GetSafeNormal();

		FVector WorldInput = FVector(0, HorizontalInput, VerticalInput);

		// Project WorldInput along the ground
		float WorldInputAlongSpline = WorldInput.DotProduct(WorldRight);
		WorldInputAlongSpline = Math::Clamp(WorldInputAlongSpline * 2, -1, 1);

		// Get the strongest input
		if(Math::Abs(WorldInputAlongSpline) > Math::Abs(HorizontalInput) && Math::Sign(WorldInputAlongSpline) == Math::Sign(-HorizontalInput))
			return -WorldInputAlongSpline;
		else
			return HorizontalInput;
	}

	float GetGroundHorizontalInput(float HorizontalInput, float VerticalInput)
	{
		FVector WorldInput = FVector(0, HorizontalInput, VerticalInput);

		// Project WorldInput along the ground
		float WorldInputAlongSpline = WorldInput.DotProduct(SplineComp.GetWorldRight());
		WorldInputAlongSpline = Math::Clamp(WorldInputAlongSpline * 2, -1, 1);

		// Get the strongest input
		if(Math::Abs(WorldInputAlongSpline) > Math::Abs(HorizontalInput) && Math::Sign(WorldInputAlongSpline) == Math::Sign(-HorizontalInput))
			return -WorldInputAlongSpline;
		else
			return HorizontalInput;
	}

	bool InputStartedOrFlippedThisFrame(float HorizontalInput) const
	{
		// No input this frame
		if(Math::Abs(HorizontalInput) < KINDA_SMALL_NUMBER)
			return false;

		// No input last frame, but input started
		if(!PreviousHorizontalInput.IsSet() && Math::Abs(HorizontalInput) > KINDA_SMALL_NUMBER)
			return true;

		// Input last frame, and it is flipped from our input
		if(PreviousHorizontalInput.IsSet() && Math::Sign(PreviousHorizontalInput.Value) != Math::Sign(HorizontalInput))
			return true;

		return false;
	}
};