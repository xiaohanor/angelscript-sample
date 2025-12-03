class UAnimInstanceTundraTreeGuardianRangedShootProjectileSpawner : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Shoot;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ClosedMH;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Open;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData OpenMH;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShoot = false;

	ATundraTreeGuardianRangedShootProjectileSpawner Spawner;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		Spawner = Cast<ATundraTreeGuardianRangedShootProjectileSpawner>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(Spawner == nullptr)
			return;

		bShoot = Spawner.bLaunch;
	}
}