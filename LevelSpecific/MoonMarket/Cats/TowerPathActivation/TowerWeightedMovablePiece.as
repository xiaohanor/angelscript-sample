class ATowerWeightedMovablePiece : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent ConeComp;
	default ConeComp.ConeAngle = 85.0;
	default ConeComp.LocalConeDirection = FVector(0,0,-1);
	default ConeComp.SpringStrength = 0.004;

	UPROPERTY(DefaultComponent, Attach = ConeComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;
	default WeightComp.PlayerForce = 140.0;
	default WeightComp.PlayerImpulseScale = 0.01;

	float AverageDot = 0.0;
	float Radius = 500.0;

	float FullMoveAmount = 500.0;

	FHazeAcceleratedVector AccelMoveVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector MoveVector = FVector(0);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!CanReadFromPlayer(Player))
				continue;

			FVector OffsetToCenter = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector);
			PrintToScreen(f"{OffsetToCenter.Size()=}");

			if (OffsetToCenter.Size() > Radius / 2)
			{
				float Percent = Math::Clamp(OffsetToCenter.Size() / Radius, 0, Radius);
				MoveVector += OffsetToCenter.GetSafeNormal() * FullMoveAmount * Percent;
			}
		}

		AccelMoveVector.AccelerateTo(MoveVector, 4.5, DeltaSeconds);
		PrintToScreen(f"{AccelMoveVector.Value.Size()=}");

		ActorLocation += AccelMoveVector.Value * DeltaSeconds;

		Debug::DrawDebugSphere(ActorLocation, Radius, 12, FLinearColor::Red);

		// ActorLocation = AccelVec.Value;
	}

	bool CanReadFromPlayer(AHazePlayerCharacter Player)
	{
		auto MoveComp = UHazeMovementComponent::Get(Player); 
		if (MoveComp == nullptr)
			return false;
		
		if (MoveComp.IsInAir())
			return false;

		FVector OffsetToCenter = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector);

		if (OffsetToCenter.Size() > Radius)
			return false;

		return true;
	}
};