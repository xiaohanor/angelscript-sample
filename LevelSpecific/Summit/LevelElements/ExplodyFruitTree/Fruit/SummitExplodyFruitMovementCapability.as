class USummitExplodyFruitMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	ASummitExplodyFruit Fruit;

	UHazeMovementComponent MoveComp;
	USummitBallMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Fruit = Cast<ASummitExplodyFruit>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(USummitBallMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Fruit.bIsEnabled)
			return false;

		if (MoveComp.HasMovedThisFrame())
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

		if (MoveComp.HasMovedThisFrame())
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
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
				FVector VerticalVelocity = MoveComp.VerticalVelocity;

				if(MoveComp.IsOnAnyGround())
					HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, Fruit.HorizontalSpeedGroundDeceleration);

				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();

				Movement.AddVelocity(HorizontalVelocity + VerticalVelocity);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}

		if(MoveComp.HasAnyValidBlockingImpacts())
		{
			auto Impacts = MoveComp.AllImpacts;

			for(auto Impact : Impacts)
			{
				FVector DirToImpact = (Impact.ImpactPoint - Fruit.ActorLocation).GetSafeNormal();
				float SpeedTowardsImpact = MoveComp.PreviousVelocity.DotProduct(DirToImpact);

				if(SpeedTowardsImpact < 400)
					continue;	

				FSummitExplodyFruitLandingOnGroundParams Params;
				Params.LandLocation = Impact.ImpactPoint;
				USummitExplodyFruitTreeEffectHandler::Trigger_OnFruitLandingOnGround(Fruit, Params);
			}
		}
	}
};