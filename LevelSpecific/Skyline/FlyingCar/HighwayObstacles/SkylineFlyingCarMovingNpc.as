class ASkylineFlyingCarMovingNpc : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent NpcPivot;

	UPROPERTY(DefaultComponent, Attach = NpcPivot)
	UCapsuleComponent Collision;
	default Collision.CapsuleRadius = 30.0;
	default Collision.CapsuleHalfHeight = 80.0;
	default Collision.RelativeLocation = FVector::UpVector * Collision.CapsuleHalfHeight;
	default Collision.CollisionProfileName = n"BlockAllDynamic";
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UBillboardComponent RunLocation;

	UPROPERTY(DefaultComponent, Attach = NpcPivot)
	UStaticMeshComponent StaticMeshComp;
	default StaticMeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarImpactResponseComponent ImpactResponseComp;
	default ImpactResponseComp.VelocityLostOnImpact = 0;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueComp;
	UPROPERTY()
	FRuntimeFloatCurve FloatCurve;

	UPROPERTY(EditAnywhere)
	float RunDuration = 10;

	FVector StartLocation;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactResponseComp.OnImpactedByFlyingCar.AddUFunction(this, n"OnImpactedByFlyingCar");
		Trigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		StartLocation = NpcPivot.GetRelativeLocation();
	}
	
	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		ActionQueComp.Duration(RunDuration, this, n"HandleStartMoving");
	}

	UFUNCTION()
	private void HandleStartMoving(float Alpha)
	{
		float AlphaValue = FloatCurve.GetFloatValue(Alpha);
		NpcPivot.SetRelativeLocation((Math::Lerp(StartLocation, RunLocation.GetRelativeLocation(),AlphaValue)));
	}

	UFUNCTION()
	private void OnImpactedByFlyingCar(ASkylineFlyingCar FlyingCar, FFlyingCarOnImpactData ImpactData)
	{
		BP_OnImpactedByFlyingCar();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnImpactedByFlyingCar() {}
};