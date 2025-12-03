class USummitAirRuneMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);	
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;
	ASummitAirRune Rune;
	UTeenDragonTailAttackResponseComponent ResponseComp;

	float RollVelocity = 1600.0;

	// FVector Velocity;
	FVector Direction;
	float Speed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		Rune = Cast<ASummitAirRune>(Owner);
		ResponseComp = UTeenDragonTailAttackResponseComponent::Get(Owner);
		ResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		// Direction = (Rune.ActorLocation - Params.HitResult.ImpactPoint).GetSafeNormal();
		Direction = Params.RollDirection;
		Speed = RollVelocity;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
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
		if (!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			FHitResult Hit = MoveComp.GetWallContact().ConvertToHitResult();

			if (Hit.bBlockingHit)
			{
				Direction = Direction.MirrorByVector(Hit.ImpactNormal);
			}

			Speed -= Math::Clamp(Speed * 0.5, RollVelocity / 15.0, RollVelocity) * DeltaTime;
			Speed = Math::Clamp(Speed, 0.0, RollVelocity);

			Movement.AddGravityAcceleration();

			FVector VelocityToAdd = Direction * Speed * DeltaTime; 

			Movement.AddDelta(VelocityToAdd);
			Movement.SetRotation(Owner.ActorRotation);
			MoveComp.ApplyMove(Movement);
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
			//Movement.ApplyCrumbSyncedAirMovement(); What is this?
		}
	}
}