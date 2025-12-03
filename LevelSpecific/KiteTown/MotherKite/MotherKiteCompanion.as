UCLASS(Abstract)
class AMotherKiteCompanion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent KiteRoot;

	float HoverTimeOffset;

	UPROPERTY(EditAnywhere)
	FKiteHoverValues HoverValues;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpawnTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HoverTimeOffset = Math::RandRange(0.0, 2.0);

		SpawnTimeLike.BindUpdate(this, n"UpdateSpawn");
		SpawnTimeLike.BindFinished(this, n"FinishSpawn");
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
	}

	void Spawn()
	{
		SetActorRelativeLocation(FVector(-2000, 0.0, 2000.0));
		Timer::SetTimer(this, n"ActuallySpawn", Math::RandRange(0.0, 1.0));
	}

	UFUNCTION()
	private void ActuallySpawn()
	{
		SpawnTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void UpdateSpawn(float CurValue)
	{
		float Offset = Math::Lerp(-2000.0, 0.0, CurValue);
		SetActorRelativeLocation(FVector(Offset, 0.0, -Offset));

		float Rot = Math::Lerp(-45.0, 0.0, CurValue);
		SetActorRelativeRotation(FRotator(Rot, 0.0, 0.0));
	}

	UFUNCTION()
	private void FinishSpawn()
	{
	}
}