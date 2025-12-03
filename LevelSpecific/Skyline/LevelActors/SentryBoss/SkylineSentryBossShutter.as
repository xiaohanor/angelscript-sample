class ASKylineSentryBossShutter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftShutter1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightShutter1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftShutter2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightShutter2;

	bool bActivated;
	ASKylineSentryBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bActivated)
			return;


	}

	UFUNCTION()
	void ActivateShutter()
	{
		Boss.ShutterCollision.CollisionEnabled = ECollisionEnabled::NoCollision;
		DestroyActor();

		bActivated = true;
	}

}