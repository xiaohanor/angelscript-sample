class ATundraBossKillingBlockers : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathCollision;

	UPROPERTY()
	FHazeTimeLike MoveMeshTimelike;

	UPROPERTY(EditInstanceOnly)
	bool bStartDeactivated = false;

	bool bActive = true;

	FVector RelativeLocStart = FVector(205, 0 , -355);
	FVector RelativeLocEnd = FVector(5, 0, -8.6);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeathCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnDeathCollisionOverlap");
		MoveMeshTimelike.BindUpdate(this, n"MoveMeshTimelikeUpdate");

		if(bStartDeactivated)
			bActive = false;
	}

	UFUNCTION()
	private void OnDeathCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if(!bActive)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if(Player == nullptr)
			return;

		MoveMeshTimelike.PlayFromStart();
		Player.KillPlayer();
	}
	
	UFUNCTION()
	private void MoveMeshTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(RelativeLocStart, RelativeLocEnd, CurrentValue));
	}

	UFUNCTION()
	void ActivateBlockers(bool bShouldBeActive)
	{
		bActive = bShouldBeActive;
	}
};