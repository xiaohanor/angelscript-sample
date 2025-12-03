class AGameShowArenaStomper : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovingMeshRoot;

	UPROPERTY(DefaultComponent, Attach = MovingMeshRoot)
	UStaticMeshComponent MovingMesh;

	UPROPERTY(DefaultComponent, Attach = MovingMesh)
	UStaticMeshComponent DetailMesh;

	UPROPERTY(DefaultComponent, Attach = MovingMeshRoot)
	UBoxComponent KillCollision;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bStartDisabled = true;

	UPROPERTY(EditInstanceOnly)
	float TimelineStartDelay = 0;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//Timeline in BP!
		KillCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnKillCollisionOverlap");
	}

	UFUNCTION()
	private void OnKillCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                    UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                    bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		Player.KillPlayer();
	}
}