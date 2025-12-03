class ASkylineFlyingCarNpc : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;
	default Collision.CapsuleRadius = 30.0;
	default Collision.CapsuleHalfHeight = 80.0;
	default Collision.RelativeLocation = FVector::UpVector * Collision.CapsuleHalfHeight;
	default Collision.CollisionProfileName = n"BlockAllDynamic";
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMeshComp;
	default StaticMeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarImpactResponseComponent ImpactResponseComp;
	default ImpactResponseComp.VelocityLostOnImpact = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactResponseComp.OnImpactedByFlyingCar.AddUFunction(this, n"OnImpactedByFlyingCar");
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