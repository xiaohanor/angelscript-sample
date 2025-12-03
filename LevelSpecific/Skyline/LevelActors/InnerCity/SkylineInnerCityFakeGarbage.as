class ASkylineInnerCityFakeGarbage : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ProjectileMesh;

	float DestroyTime = 20.0;
	float Flytime;

	FVector LaunchImpulse;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueComp;
	UPROPERTY()
	FRuntimeFloatCurve FloatCurve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		
		ProjectileMesh.SetSimulatePhysics(true);
		
		ProjectileMesh.AddImpulse(LaunchImpulse);
		ProjectileMesh.LinearDamping = .5;
	

		
	}






	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(GameTimeSinceCreation > DestroyTime)
		{
			DestroyActor();
		}
	}
};