class AFallingPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitNightQueenGem> Crystals;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PitchRotationAmount = -70.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//HOOK UP TO CRYSTAL EVENTS + USE COUNTER
	}

	UFUNCTION(BlueprintEvent)
	void BP_PillarFallOver()
	{

	}
}