class ATundra_River_IceBlock_Climbable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FPTranslateComp;
	default FPTranslateComp.ForceScalar = 2;
	default FPTranslateComp.Friction = 8;
	default FPTranslateComp.bConstrainX = true;
	default FPTranslateComp.bConstrainY = true;
	default FPTranslateComp.bConstrainZ = true;
	default FPTranslateComp.MinZ = -250;
	default FPTranslateComp.SpringStrength = 5;

	UPROPERTY(DefaultComponent, Attach = FPTranslateComp)
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent, Attach = MovingRoot)
	UStaticMeshComponent ClimbMesh;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyCeilingClimbComponent ClimbComp;

	bool bMioClimbing = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ClimbComp.OnAttach.AddUFunction(this, n"HandleOnAttach");
		ClimbComp.OnDeatch.AddUFunction(this, n"HandleOnDetach");
	}

	UFUNCTION()
	private void HandleOnDetach()
	{
		bMioClimbing = false;
	}

	UFUNCTION()
	private void HandleOnAttach()
	{
		bMioClimbing = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bMioClimbing)
		{
			FauxPhysics::ApplyFauxForceToActorAt(this, Game::GetMio().GetActorLocation(), FVector(0,0,-500));
		}
	}
};