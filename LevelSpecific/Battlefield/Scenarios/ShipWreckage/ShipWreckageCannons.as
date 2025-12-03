class AShipWreckageCannons : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CannonRoot;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = CannonRoot)
	UBattlefieldProjectileComponent ProjComp;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = CannonRoot)
	USceneComponent ShellSpawnLoc;

	UPROPERTY()
	TSubclassOf<AShipWreckageShell> ShellClass;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	FVector CannonStartLoc;

	UPROPERTY()
	FVector OffsetAmount;

	UPROPERTY()
	float BackOffset = 700.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CannonStartLoc = CannonRoot.WorldLocation;
		OffsetAmount = CannonRoot.ForwardVector * BackOffset;
		ProjComp.OnBattlefieldProjectileFiredProjectile.AddUFunction(this, n"OnBattlefieldProjectileFiredProjectile");
	}

	UFUNCTION()
	private void OnBattlefieldProjectileFiredProjectile()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 5000.0, 15000.0);

		AShipWreckageShell Shell = SpawnActor(ShellClass, ShellSpawnLoc.WorldLocation, ShellSpawnLoc.WorldRotation);
		BP_FireProjectile();

		// Timer::SetTimer(this, n"DelayedShellAction", 0.1);
	}

	UFUNCTION()
	void DelayedShellAction()
	{
		// Shell.MeshComp.AddImpulse(ShellSpawnLoc.ForwardVector * 1045000.0);
		// Shell.MeshComp.AddForceAtLocation(ShellSpawnLoc.ForwardVector * 55000.0, Shell.ImpulseOrigin.WorldLocation);
	}

	UFUNCTION(BlueprintEvent)
	void BP_FireProjectile() {}
}