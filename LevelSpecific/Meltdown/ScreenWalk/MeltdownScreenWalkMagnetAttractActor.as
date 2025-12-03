class AMeltdownScreenWalkMagnetAttractActor : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	UScenepointComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SuckMesh;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;
	
	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkReversePolarityActor AttractActor;
};