class USummitBouncyBirdNestEggMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	ASummitBouncyBirdNestEgg Egg;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	const float OnGroundAngularInterpSpeed = 10.0;
	const float InAirAngularInterpSpeed = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Egg = Cast<ASummitBouncyBirdNestEgg>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(Egg.AttachParentActor != nullptr)
			return false;

		if(!Egg.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Egg.AttachParentActor != nullptr)
			return true;

		if(!Egg.bIsActive)
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
		Egg.ActorVelocity = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddPendingImpulses();
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVelocity();

				FVector TargetAngularVelocity = MoveComp.HorizontalVelocity.CrossProduct(FVector::UpVector);
				float Radius = Egg.SphereCollisionComp.SphereRadius;

				if(MoveComp.IsOnWalkableGround())
					Egg.AngularVelocity = Math::VInterpTo(Egg.AngularVelocity, TargetAngularVelocity, DeltaTime, OnGroundAngularInterpSpeed);
				else
					Egg.AngularVelocity = Math::VInterpTo(Egg.AngularVelocity, TargetAngularVelocity * 0.2, DeltaTime, InAirAngularInterpSpeed);

				float RotationSpeed = (-Egg.AngularVelocity.Size() / Radius) * Egg.RotationMultiplier;
				FVector RotationAxis = Egg.AngularVelocity.GetSafeNormal();
				FQuat DeltaRotation = FQuat(RotationAxis, RotationSpeed * DeltaTime);
				Egg.MeshComp.AddWorldRotation(DeltaRotation);

				
			}
			else
			{
				// Follow the crumb trail on the remote side
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);

			if(HasControl())
			{
				if(MoveComp.HasAnyValidBlockingImpacts())
					HandleImpacts();
			}
		}
	}

	void HandleImpacts()
	{
		auto Impacts = MoveComp.AllImpacts;
		for(auto Impact : Impacts)
		{
			auto BirdNest = Cast<ASummitBouncyBirdNest>(Impact.Actor);
			if(BirdNest != nullptr)
			{
				if(Impact.Component.AttachParent == BirdNest.PlatformRoot)
				{
					LandInBirdNest(BirdNest);
					return;
				}
			}
			else if(Egg.bExplodeOnContact)
				Egg.Explode();
		}
	}

	void LandInBirdNest(ASummitBouncyBirdNest BirdNest)
	{
		BirdNest.AttachEgg(Egg);
		BirdNest.AttachEggs.Add(Egg);
		BirdNest.AccPlatformRotation.Velocity += FRotator(0.0, 0.0, 20.0);
	}
};