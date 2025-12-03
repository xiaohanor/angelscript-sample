class AForgeGoldConveyor : ANightQueenMetal
{

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FauxTranslate;

	UPROPERTY(DefaultComponent, Attach = FauxTranslate)
	UFauxPhysicsForceComponent ForceComp;
	
	//UPROPERTY(EditAnywhere)
	//ASummitRollingWheel RollingWheel;

	UPROPERTY(DefaultComponent, Attach = ForceComp)
	USceneComponent MeshOrigi;

	TSubclassOf<ANightQueenChain> QueenChainClass;

//	UPROPERTY(EditAnywhere)
//	ASplineActor SplineActor;
	
	UHazeSplineComponent SplineComp;

	float SplineSpeed = 800;

	float CurrentDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	SplineComp = SplineActor.Spline;
		Super::BeginPlay();
		FauxTranslate.AddDisabler(this);
		OnNightQueenMetalMelted.AddUFunction(this, n"OnMetalMelted");
	//	RollingWheel.OnWheelRolled.AddUFunction(this, n"WheelRolling");
	
	}

	/*UFUNCTION()
	private void WheelRolling(float Amount)
	{
		CurrentDistance += Amount;
	}
	*/
	UFUNCTION()
	private void OnMetalMelted()
	{
		FauxTranslate.RemoveDisabler(this);
		Print("iMmELTING", 5.0);

	}
	
}