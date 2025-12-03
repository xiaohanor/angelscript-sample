class ASpiritVortex : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(25));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	float YawRotationSpeed = 130;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		RotationRoot.WorldRotation += FRotator(0, YawRotationSpeed, 0) * DeltaSeconds;
	}

	UFUNCTION()
	void ActivateVortex()
	{
		RemoveActorDisable(this);
	}
};