class ACounterWeightRotate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent EndComp;
	default EndComp.SetWorldScale3D(FVector(6.0));

	UPROPERTY(EditAnywhere, Category = "Setup")
	ANightQueenMetal Metal;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		Metal.OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{

	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{

	}
}