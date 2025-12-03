class USummitObjectWeightRespondComponent : USceneComponent
{
	UMovementImpactCallbackComponent MovementImpactComp;

	float ImpactForce = 400;
	float SpringForce = 15.0;
	float Damping = 1.6;

	FVector StartLocation;
	FVector Force;
	float Acceleration; 

	TArray<UHazeMovementComponent> MovementComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactComp = UMovementImpactCallbackComponent::GetOrCreate(Owner);
		MovementImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpactedByPlayer");

		StartLocation = RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector DirectionToCenter = StartLocation - RelativeLocation;
		float Dist = DirectionToCenter.Size();
		DirectionToCenter.Normalize();
		
		Force += DirectionToCenter * (Dist * SpringForce) * DeltaSeconds;
		Force -= (Force * Damping) * DeltaSeconds;
		RelativeLocation += Force * DeltaSeconds;

		TArray<UHazeMovementComponent> ToRemoveMovementComps;
		for (UHazeMovementComponent& MoveComp : MovementComps)
		{
			if (!MoveComp.IsOnWalkableGround())
			{
				ToRemoveMovementComps.Add(MoveComp);

				if (MoveComp.Velocity.Z > 0.0)
				{
					JumpingOffImpact();
				}
			}
		}

		for (UHazeMovementComponent& MoveComp : ToRemoveMovementComps)
		{
			MovementComps.RemoveSingle(MoveComp);
		}
	}

	UFUNCTION()
	private void OnGroundImpactedByPlayer(AHazePlayerCharacter Player)
	{
		//UPlayerTeenDragonComponent UserComp = UPlayerTeenDragonComponent::Get(Player);
		UHazeMovementComponent CurrentMoveComp = UHazeMovementComponent::Get(Player);
		if (CurrentMoveComp != nullptr)
		{
			if (!MovementComps.Contains(CurrentMoveComp))
				MovementComps.Add(CurrentMoveComp);
		}

		FVector Direction = (WorldLocation - Player.ActorLocation).GetSafeNormal();
		Force = -FVector::UpVector * ImpactForce;
	}

	void JumpingOffImpact()
	{
		Force = -FVector::UpVector * ImpactForce / 1.2;
	}
}