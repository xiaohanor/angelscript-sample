class AMeltdownBossPhaseThreeSkylineCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USoftSplitBobbingComponent Bobbing;

	UPROPERTY(DefaultComponent, Attach = Bobbing)
	UStaticMeshComponent Car;

	UPROPERTY(DefaultComponent, Attach = Bobbing)
	UDamageTriggerComponent Damage;

	UPROPERTY(EditAnywhere)
	float Speed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Bobbing.ShakeAmountZ = Math::RandRange(15,50);
	//	SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalOffset(FVector(Speed * DeltaSeconds,0,0));
	}
};