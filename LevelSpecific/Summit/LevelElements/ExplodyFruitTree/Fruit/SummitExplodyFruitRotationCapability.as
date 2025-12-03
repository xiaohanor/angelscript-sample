class USummitExplodyFruitRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	ASummitExplodyFruit Fruit;

	UHazeMovementComponent MoveComp;

	const float OnGroundAngularInterpSpeed = 10.0;
	const float InAirAngularInterpSpeed = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Fruit = Cast<ASummitExplodyFruit>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Fruit.bIsEnabled)
			return false;

		if(Fruit.bIsAttached)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Fruit.bIsEnabled)
			return true;

		if(Fruit.bIsAttached)
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
		if(HasControl())
		{
			FVector TargetAngularVelocity = MoveComp.HorizontalVelocity.CrossProduct(FVector::UpVector);;
			float Radius = Fruit.SphereComp.ScaledSphereRadius;
			
			if(MoveComp.IsOnWalkableGround())
				Fruit.AngularVelocity = Math::VInterpTo(Fruit.AngularVelocity, TargetAngularVelocity, DeltaTime, OnGroundAngularInterpSpeed);
			else
				Fruit.AngularVelocity = Math::VInterpTo(Fruit.AngularVelocity, TargetAngularVelocity * 0.2, DeltaTime, InAirAngularInterpSpeed);

			float RotationSpeed = (-Fruit.AngularVelocity.Size() / Radius) * Fruit.RotationMultiplier;
			FVector RotationAxis = Fruit.AngularVelocity.GetSafeNormal();
			FQuat DeltaRotation = FQuat(RotationAxis, RotationSpeed * DeltaTime);
			Fruit.CenterScaleRoot.AddWorldRotation(DeltaRotation);

			Fruit.SyncedRotation.SetValue(Fruit.CenterScaleRoot.WorldRotation);
		}
		else
		{
			Fruit.CenterScaleRoot.WorldRotation = Fruit.SyncedRotation.Value;
		}
	}
};