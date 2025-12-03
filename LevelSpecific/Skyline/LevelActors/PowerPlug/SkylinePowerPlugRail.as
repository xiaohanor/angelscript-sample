class ASkylinePowerPlugRail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	ASkylinePowerPlug PowerPlug;

	UPROPERTY(BlueprintReadOnly)
	ASkylinePowerPlugSpool Spool;

	UFUNCTION(BlueprintEvent)
	void BP_OnSpoolConnected() {};

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (PowerPlug != nullptr && Spool != nullptr)
		{
			FVector Force = (PowerPlug.ActorLocation - Spool.ActorLocation) * 5.0;
			ForceComp.Force = Force;
		}
	}
};