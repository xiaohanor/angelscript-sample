class AMeltdownScreenWalkBackAndForthBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Blocker;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BlockerTarget;
	default BlockerTarget.bHiddenInGame = true;
	default BlockerTarget.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkButtonActor ButtonLeft;

	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkButtonActor ButtonRight;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	FVector BlockerStart;
	FVector BlockerEnd;

	FHazeTimeLike MoveBlocker;
	default MoveBlocker.Duration = 2.0;
	default MoveBlocker.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		BlockerStart = Blocker.RelativeLocation;
		BlockerEnd = BlockerTarget.RelativeLocation;

		MoveBlocker.BindUpdate(this, n"OnUpdate");

		ButtonLeft.JumpedOn.AddUFunction(this, n"GoLeft");

		ButtonRight.JumpedOn.AddUFunction(this, n"GoRight");
	}

	UFUNCTION()
	private void GoLeft()
	{
		MoveBlocker.Play();
	}

	UFUNCTION()
	private void GoRight()
	{
		MoveBlocker.Reverse();
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Blocker.SetRelativeLocation(Math::Lerp(BlockerStart,BlockerEnd, CurrentValue));
	}
};