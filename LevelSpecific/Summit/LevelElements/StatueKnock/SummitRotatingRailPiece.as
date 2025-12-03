class ASummitRotatingRailPiece : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent RailMesh;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal MetalBlocker;

	UPROPERTY()
	FRotator RailStartRot;
	UPROPERTY()
	FRotator RailTargetRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshRoot.RelativeRotation = RailStartRot;
		RailTargetRot = FRotator(0,90,0);
		if (MetalBlocker != nullptr)
		{
		MetalBlocker.OnNightQueenMetalMelted.AddUFunction(this, n"MetalMelted");
		MetalBlocker.OnNightQueenMetalRecovered.AddUFunction(this, n"MetalRecovered");
		}
	}

	UFUNCTION(BlueprintCallable)
	private void MetalRecovered()
	{
	}

	UFUNCTION(BlueprintCallable)
	private void MetalMelted()
	{
	}
};