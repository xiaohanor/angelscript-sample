class ASummitLargeHittablePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPlayerInheritMovementComponent InheritMoveComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ArmMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent PlatformMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent HitMeshComp;

	UPROPERTY(DefaultComponent, Attach = HitMeshComp)
	UTeenDragonTailAttackResponseComponent TailResponseComp;
	default TailResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitHittablePlatformMoveCapability");

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	float ImpactForce = 5500.0;

	UPROPERTY(EditAnywhere)
	float Duration = 4.5;

	float Force;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		Force = ImpactForce;
	}

	float GetLoseForceAmount()
	{
		return ImpactForce / Duration;
	}

	UFUNCTION(CallInEditor)
	void SetToOrigin()
	{
		ActorLocation = SplineActor.Spline.GetWorldLocationAtSplineDistance(0);
	}
};