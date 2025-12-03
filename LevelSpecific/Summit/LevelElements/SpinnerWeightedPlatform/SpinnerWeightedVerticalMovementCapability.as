class USpinnerWeightedMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WeightedMovement");
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	UDragonSpinnerResponseComponent SpinnerResponseComp;
	FVector Velocity;
	float GravityAcceleration = 500.0;
	float MaxGravity = 1200.0;

	ASpinnerWeightedVerticalPlatform VerticalPlatform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpinnerResponseComp = UDragonSpinnerResponseComponent::Get(Owner);
		VerticalPlatform = Cast<ASpinnerWeightedVerticalPlatform>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Offset = FVector::UpVector * SpinnerResponseComp.GetSpinForce() * 2.0;
		Velocity += Offset * DeltaTime;
		Velocity -= FVector(0.0, 0.0, GravityAcceleration) * DeltaTime;
		Velocity.Z = Math::Clamp(Velocity.Z, -MaxGravity, 4000.0);

		FVector FuturePosition = Owner.ActorLocation + Velocity * DeltaTime;

		float WithinBoundsCheck = VerticalPlatform.GetWithinMetalBoundsHeightDat(FuturePosition);

		if (WithinBoundsCheck != 0.0)
		{
			float Diff = VerticalPlatform.GetCurrentHeight() - WithinBoundsCheck;
			Owner.ActorLocation = FVector(Owner.ActorLocation.X, Owner.ActorLocation.Y, VerticalPlatform.StartLocation.Z + VerticalPlatform.GetCurrentHeight() - Diff);

			if (Velocity.Size() > 25.0)
			{
				Velocity = -Velocity * 0.3;
				Owner.ActorLocation += Velocity * DeltaTime;
			}
			else
			{
				Velocity.Z = 0.0;
			}	

			return;
		}
		
		if (VerticalPlatform.GetProjectedHeight(FuturePosition) <= 0.0)	
		{
			Owner.ActorLocation = VerticalPlatform.StartLocation;

			if (Velocity.Size() > 25.0)
			{
				Velocity = -Velocity * 0.3;
				Owner.ActorLocation += Velocity * DeltaTime;
			}
			else
			{
				Velocity.Z = 0.0;
			}
		}
		else if (VerticalPlatform.GetProjectedHeight(FuturePosition) >= VerticalPlatform.MaxDistance)
		{
			Owner.ActorLocation = VerticalPlatform.StartLocation + FVector(0.0, 0.0, VerticalPlatform.MaxDistance);

			if (Velocity.Size() > 25.0)
			{
				Velocity = -Velocity * 0.3;
				Owner.ActorLocation += Velocity * DeltaTime;
			}
			else
			{
				Velocity.Z = 0.0;
			}
		}
		else
		{
			Owner.ActorLocation += Velocity * DeltaTime;
		}

		PrintToScreen("VerticalPlatform Height: " + VerticalPlatform.GetCurrentHeight());
	}	
}