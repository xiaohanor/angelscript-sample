class AMeltdownScreenWalkConveyorObstacle01 : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.SpringStrength = 10.0;


	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UPROPERTY(EditAnywhere)
	FVector Impulse;

	float CurrentSplineDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnJumpTrigger.AddUFunction(this, n"OnActivated");
	}


	UFUNCTION()
	private void OnActivated()
	{
		OnJumped();
		TranslateComp.ApplyImpulse(
		ActorLocation, FVector(Impulse)
		);
	}

	UFUNCTION(BlueprintEvent)
	void OnJumped()
	{

	}

};