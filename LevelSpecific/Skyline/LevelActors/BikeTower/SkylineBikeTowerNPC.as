class ASkylineBikeTowerNPC : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_Vehicle, ECollisionResponse::ECR_Block);
	default Collision.CapsuleRadius = 30.0;
	default Collision.CapsuleHalfHeight = 80.0;
	default Collision.RelativeLocation = FVector::UpVector * Collision.CapsuleHalfHeight;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMeshComp;
	default StaticMeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent BikeImpactResponseComp;
	default BikeImpactResponseComp.bIgnoreAfterImpact = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BikeImpactResponseComp.OnImpact.AddUFunction(this, n"HandleBikeImpact");
	}

	UFUNCTION()
	private void HandleBikeImpact(AGravityBikeFree GravityBike, FGravityBikeFreeOnImpactData Data)
	{
		BP_OnImpact();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnImpact() { }
};