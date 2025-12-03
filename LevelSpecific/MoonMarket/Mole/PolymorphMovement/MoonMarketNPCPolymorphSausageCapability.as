class UMoonMarketNPCPolymorphSausageCapability : UMoonMarketNPCWalkCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::BeforeMovement;

	FHazeAcceleratedFloat AcceleratedFloppiness;
	FHazeAcceleratedVector AcceleratedRelativeMeshLocation;

	const float JiggleAmplitude = 30.0;
	const float JiggleSpeed = 18.0;
	const float MaxTangentHeight = 100.0;

	AMoonMarketSausage Sausage;

	// Input direction multiplier
	float LastSignedInput;

	bool bHasInputThisFrame;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(PolymorphComp.ShapeshiftComp.ShapeshiftShape == nullptr)
			return false;

		if(Cast<AMoonMarketSausage>(PolymorphComp.ShapeshiftComp.ShapeshiftShape.CurrentShape) == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if(PolymorphComp.ShapeshiftComp.ShapeshiftShape == nullptr)
			return true;
		
		if(PolymorphComp.ShapeshiftComp.ShapeshiftShape.CurrentShape != Sausage)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		AcceleratedFloppiness.Value = 0;
		Sausage = Cast<AMoonMarketSausage>(PolymorphComp.ShapeshiftComp.ShapeshiftShape.CurrentShape);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Sausage = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		// Juicy mesh movement
		const float JiggleSeed = ActiveDuration * JiggleSpeed;
		
		bHasInputThisFrame = true;
		AcceleratedFloppiness.Value = 1;
		Flop(JiggleSeed, DeltaTime);
		WiggleMesh(JiggleSeed, DeltaTime);
	}

	void Flop(float Seed, float DeltaTime, bool bReset = false)
	{
		// // Rotate pitch to get flopiness
		// {
		// 	// float PitchAngle = Math::Pow(Math::Sin(Seed), 3) * JiggleAmplitude * Floppiness * 0.0;
		// 	// FQuat Pitch = FQuat(MeshOffsetComponent.RightVector, Math::DegreesToRadians(PitchAngle));
		// 	FQuat MeshRotation = /*Pitch */ Owner.ActorQuat;

		// 	if (!bReset)
		// 		MeshOffsetComponent.LerpToRotation(this, MeshRotation, 0.1);
		// }

		// Move mesh's height with floppiness to avoid clipping into floor
		{
			float Height = (Math::Sin(Seed) * JiggleAmplitude) + Sausage.Girth / 2;
			FVector RelativeMeshLocation = FVector::UpVector * (1.0 + Math::Abs(AcceleratedFloppiness.Value * 0.75)) + Owner.ActorUpVector * Height * AcceleratedFloppiness.Value;
			if (bReset)
				RelativeMeshLocation = FVector::ZeroVector;

			float AccelerationDuration = bHasInputThisFrame ? 0.1 : 0.0;
			AcceleratedRelativeMeshLocation.AccelerateTo(RelativeMeshLocation, AccelerationDuration, DeltaTime);
			Sausage.SplineMesh.SetRelativeLocation(AcceleratedRelativeMeshLocation.Value);
		}
	}

	void WiggleMesh(float Seed, float DeltaTime, float Intensity = 1.0)
	{
		float TangentHeight = Math::Cos(Seed) * MaxTangentHeight * AcceleratedFloppiness.Value * Intensity;
		const float Stiffness = 1000.0;
		float Damping = 0.1;

		FVector StartTangent = Sausage.GetStartTangent() * FVector::ForwardVector + FVector::UpVector * TangentHeight;
		Sausage.AcceleratedStartTangent.SpringTo(StartTangent, Stiffness, Damping, DeltaTime);

		FVector EndTangent = Sausage.GetEndTangent() * FVector::ForwardVector - FVector::UpVector * TangentHeight;
		Sausage.AcceleratedEndTangent.SpringTo(EndTangent, Stiffness, Damping, DeltaTime);

		Sausage.UpdateTangents();
	}
};