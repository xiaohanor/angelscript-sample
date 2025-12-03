class ASolarFlareGreenhouseShutter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)
	float MoveDownAmount = 5500;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 350.0;

	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshComp.StaticMesh = Mesh;	
		TargetLocation = ActorLocation + (-ActorUpVector * MoveDownAmount);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		TargetLocation = ActorLocation + (-ActorUpVector * MoveDownAmount);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaSeconds, MoveSpeed);

		if ((ActorLocation - TargetLocation).Size() < 1)
		{
			USolarFlareGreenhouseShutterEventHandler::Trigger_OnShutterStopMoving(this);
			SetActorTickEnabled(false);
			AddActorDisable(this);
		}
	}

	void ActivateGreenhouseDoorsShutters()
	{
		SetActorTickEnabled(true);
		USolarFlareGreenhouseShutterEventHandler::Trigger_OnShutterStartMoving(this);
	}

	void SetEndState()
	{
		SetActorTickEnabled(false);
		AddActorDisable(this);	
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugLine(ActorLocation, TargetLocation, FLinearColor::Red, 50);
	}
#endif
};