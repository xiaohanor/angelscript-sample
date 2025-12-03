class USkylineBallBossChargeLaserProgressComponent : UStaticMeshComponent
{
	default CollisionEnabled = ECollisionEnabled::NoCollision;
	float ProgressAlpha = 0.0;
	bool bSlowRetreat = false;

	UPROPERTY(EditAnywhere)
	float DownwardsProgressOffset = 100.0;

	FHazeAcceleratedFloat AccProgress;

	FVector OriginalRelative;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalRelative = RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccProgress.AccelerateTo(ProgressAlpha, bSlowRetreat ? 1.0 : 0.1, DeltaSeconds);
		SetRelativeLocation(OriginalRelative + FVector(0.0, 0.0, DownwardsProgressOffset * AccProgress.Value));
	}
}