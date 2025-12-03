class ATundra_IcePalace_InsideLockBouncePad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UBoxComponent BounceTrigger;

	UPROPERTY()
	FHazeTimeLike MoveBouncePadTimelike;
	default MoveBouncePadTimelike.Duration = 1;

	AHazePlayerCharacter Player;

	UPROPERTY(EditInstanceOnly)
	float BounceVelocity = 1500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BounceTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
		MoveBouncePadTimelike.BindUpdate(this, n"MoveBouncePadTimelikeUpdate");
		MoveBouncePadTimelike.BindFinished(this, n"MoveBouncePadTimelikeFinished");
	}

	UFUNCTION()
	private void MoveBouncePadTimelikeFinished()
	{
		GiveVelocity();
	}

	UFUNCTION()
	private void MoveBouncePadTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector::ZeroVector, FVector(0, 0, -70), CurrentValue)); 
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;	

		if(!MoveBouncePadTimelike.IsPlaying())
			MoveBouncePadTimelike.PlayFromStart();
	}

	UFUNCTION()
	void GiveVelocity()
	{
		Player.SetActorVerticalVelocity(FVector(0.0, 0.0, BounceVelocity));
	}
};