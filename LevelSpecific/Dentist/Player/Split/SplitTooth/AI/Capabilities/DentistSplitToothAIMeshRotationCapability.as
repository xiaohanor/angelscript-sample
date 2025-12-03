class UDentistSplitToothAIMeshRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	ADentistSplitToothAI SplitToothAI;
	UHazeMovementComponent MoveComp;

	float BobTime = 0;
	float AirTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothAI = Cast<ADentistSplitToothAI>(Owner);
		MoveComp = UHazeMovementComponent::Get(SplitToothAI);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SplitToothAI.HasSetMeshRotationThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SplitToothAI.HasSetMeshRotationThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat WorldRotation = SplitToothAI.ActorQuat;
		WorldRotation = FQuat::MakeFromZX(SplitToothAI.AccTiltAmount.Value, FVector::ForwardVector) * WorldRotation;

		if(MoveComp.IsInAir())
		{
			AirTime += DeltaTime;
		}
		else
		{
			AirTime = 0;
		}

		const float AirFactor = 1.0 - Math::Saturate(Math::NormalizeToRange(AirTime, 0, 0.5));
		if(AirFactor < KINDA_SMALL_NUMBER)
		{
			BobTime = 0;
		}
		else
		{
			float ForwardSpeed = Math::Max(SplitToothAI.ActorVelocity.DotProduct(SplitToothAI.ActorForwardVector), 0);
			const float BobSpeedAlpha = Math::GetPercentageBetweenClamped(SplitToothAI.Settings.BobSpeed.Min, SplitToothAI.Settings.BobSpeed.Max, ForwardSpeed);
			BobTime += BobSpeedAlpha * DeltaTime;

			float Rotation = (Math::Sin(BobTime * SplitToothAI.Settings.BobFrequency) * BobSpeedAlpha) * SplitToothAI.Settings.BobAngle;
			FQuat BobRotation = FQuat(SplitToothAI.ActorForwardVector, Rotation * AirFactor);

			WorldRotation =  BobRotation * WorldRotation;
		}

		SplitToothAI.SetMeshWorldRotation(WorldRotation, this, 0.4, DeltaTime);
	}
};