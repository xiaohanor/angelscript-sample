class AJetskiMovingSpikes : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent KillCollision;

	FHazeTimeLike MoveSpikeTimelike;
	default MoveSpikeTimelike.Duration = 0.25;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveSpikeTimelike.BindUpdate(this, n"OnMoveSpikeUpdate");
		MoveSpikeTimelike.BindFinished(this, n"OnMoveSpikeFinished");
		KillCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnKillBoxOverlap");
	}

	UFUNCTION()
	void MoveSpike()
	{
		MoveSpikeTimelike.PlayFromStart();
	}

	UFUNCTION()
	void OnMoveSpikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector::ZeroVector, FVector(0, 0, -600), CurrentValue));
	}

	UFUNCTION()
	void OnMoveSpikeFinished()
	{
		KillCollision.CollisionEnabled = ECollisionEnabled::QueryOnly;
	}

	UFUNCTION()
    void OnKillBoxOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Player.KillPlayer();
    }
}