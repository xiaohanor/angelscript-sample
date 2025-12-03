class ASpaceWalkSpinningScaryThing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Object;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Collision;
	default Collision.SetHiddenInGame(true);
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	UPROPERTY(EditAnywhere)
	float Rotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"KillTrigger");
	}

	UFUNCTION()
	private void KillTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                         UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                         const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
			if (Player == nullptr)
				return;

			Player.KillPlayer();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalRotation(FRotator(0,0,Rotation)* DeltaSeconds);
	}
};