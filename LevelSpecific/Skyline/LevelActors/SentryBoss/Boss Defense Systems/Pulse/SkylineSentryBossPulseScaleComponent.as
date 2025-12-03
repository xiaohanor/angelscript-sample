class USkylineSentryBossPulseScaleComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	float Radius = 500.0;

	UPROPERTY(EditAnywhere)
	AActor Origin;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Origin == nullptr)
			Origin = Owner;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateScale();
	}

	void UpdateScale()
	{
		float DistanceToOrigin = (Origin.ActorLocation - WorldLocation).Size();
		float Scale = Math::Sin(Math::Acos(DistanceToOrigin / Radius));
		RelativeScale3D = FVector(Scale * Radius * 0.02, Scale * Radius * 0.02, RelativeScale3D.Z);
	}
}