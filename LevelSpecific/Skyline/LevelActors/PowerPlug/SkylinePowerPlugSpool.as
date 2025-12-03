class ASkylinePowerPlugSpool : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent PowerPlugPivot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpoolRoot;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylinePowerPlug> PowerPlugClass;

	UPROPERTY(EditAnywhere)
	float ThrowSpeed = 3000.0;

	UPROPERTY(EditAnywhere)
	float CableLength = 1300.0;

	UPROPERTY(EditAnywhere)
	float VisableDistance = 4000.0;

	UPROPERTY(EditAnywhere)
	float GrabDistance = 4000.0;

	UPROPERTY(EditAnywhere)
	float ReturnDelay = 3.0;

	UPROPERTY(EditInstanceOnly)
	bool bStartSocketed;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition="bStartSocketed", EditConditionHides))
	ASkylinePowerPlugSocket InitialSocket;

	ASkylinePowerPlug PowerPlug;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		PowerPlug = SpawnActor(PowerPlugClass, PowerPlugPivot.WorldLocation, PowerPlugPivot.WorldRotation, bDeferredSpawn = true, Level = Level);
		PowerPlug.MakeNetworked(this);
		PowerPlug.Origin = PowerPlugPivot;
		PowerPlug.CableAttach = Root;
		PowerPlug.ThrowSpeed = ThrowSpeed;
		PowerPlug.CableLength = CableLength;
		PowerPlug.ReturnDelay = ReturnDelay;
		PowerPlug.GravityWhipTargetComp.VisibleDistance = VisableDistance;
		PowerPlug.GravityWhipTargetComp.MaximumDistance = GrabDistance;
		FinishSpawningActor(PowerPlug);

		auto Rail = Cast<ASkylinePowerPlugRail>(AttachParentActor);
		if (Rail != nullptr)
		{
			Rail.PowerPlug = PowerPlug;
			Rail.Spool = this;
			Rail.BP_OnSpoolConnected();
		}

		if (bStartSocketed && IsValid(InitialSocket))
		{
			PowerPlug.Plug(InitialSocket, bWasInitialPlug = true);
			//InitialSocket.Activate();			
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = (PowerPlug.ActorLocation.Distance(PowerPlugPivot.WorldLocation) / CableLength);
		float ScaleAlpha = Math::Lerp(1.0, 0.75, Alpha);
		SpoolRoot.SetWorldScale3D(FVector(ScaleAlpha, 1.0, ScaleAlpha));
		SpoolRoot.SetRelativeRotation(FRotator(0.0, 0.0, Math::Lerp(0.0, -1000.0, Alpha)));
		// PrintToScreen("Alpha" + Alpha);
	}
};