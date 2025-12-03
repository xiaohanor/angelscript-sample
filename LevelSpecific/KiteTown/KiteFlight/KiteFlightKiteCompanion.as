UCLASS(Abstract)
class AKiteFlightKiteCompanion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent KiteRoot;

	bool bDespawning = false;
	FVector DespawnDirection;
	float DespawnMoveSpeed = 10000.0;
	float CurrentDespawnTime = 0.0;
	float DespawnDuration = 1.5;

	float HoverTimeOffset;

	UPROPERTY(EditAnywhere)
	FKiteHoverValues HoverValues;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HoverTimeOffset = Math::RandRange(0.0, 2.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Time = Time::GameTimeSeconds + HoverTimeOffset;
		float Roll = Math::DegreesToRadians(Math::Sin(Time * HoverValues.HoverRollSpeed) * HoverValues.HoverRollRange);
		float Pitch = Math::DegreesToRadians(Math::Cos(Time * HoverValues.HoverPitchSpeed) * HoverValues.HoverPitchRange);
		FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);

		KiteRoot.SetRelativeRotation(Rotation);

		float XOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.X) * HoverValues.HoverOffsetRange.X;
		float YOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.Y) * HoverValues.HoverOffsetRange.Y;
		float ZOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.Z) * HoverValues.HoverOffsetRange.Z;

		FVector Offset = (FVector(XOffset, YOffset, ZOffset));

		KiteRoot.SetRelativeLocation(Offset);

		if (bDespawning)
		{
			AddActorWorldOffset(DespawnDirection * DespawnMoveSpeed * DeltaTime);

			CurrentDespawnTime += DeltaTime;
			if (CurrentDespawnTime >= DespawnDuration)
			{
				DestroyActor();
			}
		}
	}

	void DespawnCompanion(FVector Direction)
	{
		DespawnDirection = Direction;
		DespawnDirection = (DespawnDirection + ActorForwardVector).GetSafeNormal();
		bDespawning = true;
	}
}