class ASummitFlyingBird : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ASummitFlyingBirdFlockPosition FlockPos;

	FVector Offset;
	float Range = 1000.0;
	float Speed;
	float MaxDistance = 5000.0;
	float MinDistance = 1000.0;

	float ScatterFromCenterTime;
	float ScatterFromCenterDuration = 1.0;

	FQuat CurrentQuat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Offset = ActorLocation - FlockPos.ActorLocation;
		Speed = FlockPos.Speed / 1.2;
		ActorLocation = GetTruePos();
		CurrentQuat = (GetTruePos() - ActorLocation).ToOrientationQuat();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (FlockPos.bPlayerIsIntersectingBirds)
		{
			FVector Dir;

			if (Time::GameTimeSeconds < ScatterFromCenterTime)
				Dir = (ActorLocation - FlockPos.ActorLocation).GetSafeNormal();
			else
				Dir = (ActorLocation - FlockPos.ScatteringPlayer.ActorLocation).GetSafeNormal();

			FQuat DirQuat = Dir.ToOrientationQuat();
			CurrentQuat = Math::QInterpTo(CurrentQuat, DirQuat, DeltaSeconds, 0.8);
			ActorRotation = CurrentQuat.Rotator();
			ActorLocation += ActorForwardVector * Speed * 2.5 * DeltaSeconds;
		}
		else
		{
			ScatterFromCenterTime = Time::GameTimeSeconds + ScatterFromCenterDuration;

			FVector Dir = (GetTruePos() - ActorLocation);
			float Distance = Dir.Size();
			Dir.Normalize();

			float DistanceMultiplier = 1.0;

			if (Distance > MinDistance)
				DistanceMultiplier += (Distance - MinDistance) / MaxDistance;

			FQuat DirQuat = Dir.ToOrientationQuat();
			CurrentQuat = Math::QInterpTo(CurrentQuat, DirQuat, DeltaSeconds, 1.4);
			ActorRotation = CurrentQuat.Rotator();
			ActorLocation += ActorForwardVector * Speed * DistanceMultiplier * DeltaSeconds;
		}
	}

	FVector GetTruePos()
	{
		FVector Position = FlockPos.ActorLocation;
		Position += FlockPos.ActorForwardVector * Offset.X;
		Position += FlockPos.ActorRightVector * Offset.Y;
		Position += FlockPos.ActorUpVector * Offset.Z;
		return Position;
	}
}