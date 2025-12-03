class USummitWeighDownSeeSawStoneRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASummitWeighDownSeeSawStone Stone;

	UHazeMovementComponent MoveComp;

	const float OnGroundAngularInterpSpeed = 10.0;
	const float InAirAngularInterpSpeed = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Stone = Cast<ASummitWeighDownSeeSawStone>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Stone.bHasHitSeeSaw)
			return false;

		if(!Stone.bHasBeenHit)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Stone.bHasHitSeeSaw)
			return true;

		if(!Stone.bHasBeenHit)
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
			
			if(MoveComp.IsOnWalkableGround() || MoveComp.HasWallContact())
				Stone.AngularVelocity = Math::VInterpTo(Stone.AngularVelocity, TargetAngularVelocity, DeltaTime, OnGroundAngularInterpSpeed);
			else
				Stone.AngularVelocity = Math::VInterpTo(Stone.AngularVelocity, TargetAngularVelocity * 0.2, DeltaTime, InAirAngularInterpSpeed);

			Stone.SyncedAngularVelocityComp.SetValue(Stone.AngularVelocity);
		}
		else
		{
			Stone.AngularVelocity = Stone.SyncedAngularVelocityComp.Value;
		}

		float Radius = Stone.SphereComp.SphereRadius;
		float RotationSpeed = -Stone.AngularVelocity.Size() / Radius;
		FVector RotationAxis = Stone.AngularVelocity.GetSafeNormal();
		FQuat DeltaRotation = FQuat(RotationAxis, RotationSpeed * DeltaTime);
		Stone.StoneMesh.AddWorldRotation(DeltaRotation);
	}
};