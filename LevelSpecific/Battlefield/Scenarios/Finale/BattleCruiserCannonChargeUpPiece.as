class ABattleCruiserCannonChargeUpPiece : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MoveRoot;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	UStaticMeshComponent MeshPiece;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	float TargetOffset;
	float TargetAmount = 800;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TargetOffset = Math::FInterpConstantTo(TargetOffset, 0.0, DeltaSeconds, TargetAmount / 3.5);
		MoveRoot.RelativeLocation = FVector(0,0,-TargetOffset);
	}

	void Fire()
	{
		TargetOffset = TargetAmount;
	}
};