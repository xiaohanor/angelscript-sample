class ABombToss_LaserWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent LaserMesh01;
	default LaserMesh01.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent LaserMesh02;
	default LaserMesh02.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathCollision;

	float ToggleActivationTimer = 0;
	float ToggleActivationTimerDuration = 1.1;
	bool bLaserIsOn = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeathCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnDeathCollisionOverlap");
	}

	UFUNCTION()
	private void OnDeathCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(Player.HasControl())
			Player.KillPlayer();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ToggleActivationTimer += DeltaSeconds;
		if (ToggleActivationTimer < ToggleActivationTimerDuration)
			return;
		
		bLaserIsOn = !bLaserIsOn;
		ToggleActivationTimer = 0;
		CrumbToggleActivation(bLaserIsOn);
	}

	UFUNCTION(CrumbFunction)
	void CrumbToggleActivation(bool bActive)
	{
		MeshRoot.SetHiddenInGame(!bActive, true);
		DeathCollision.CollisionEnabled = bActive ? ECollisionEnabled::QueryOnly : ECollisionEnabled::NoCollision;
	}
}