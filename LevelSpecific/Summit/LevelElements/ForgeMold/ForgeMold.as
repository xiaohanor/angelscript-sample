class AForgeMold : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	ANightQueenChain Chain;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent PushEndLocation;
	default PushEndLocation.SetWorldScale3D(FVector(5.0));

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAtackResponseComp;
	
	bool Chained = true;
	float PushSpeed = 3500.0;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TailAtackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		Chain.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		TargetLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ActorLocation == TargetLocation)
			return;

		PrintToScreen("ActorLocation: " + ActorLocation);
		PrintToScreen("TargetLocation: " + TargetLocation);

		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaSeconds, PushSpeed);
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		Chained = false;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if(Chained)
			return;

		TargetLocation = PushEndLocation.WorldLocation;

	}
}