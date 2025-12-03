event void FGravityBikeSplineBladeBarrelOnAttached();
event void FGravityBikeSplineBladeBarrelOnDetached();

UCLASS(Abstract)
class AGravityBikeBladeBarrel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent TargetRootComp;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = TargetRootComp)
	UGravityBikeBladeTargetComponent BladeTargetComp;
	default BladeTargetComp.Type = EGravityBikeBladeTargetType::Barrel;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent DropVFX;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UGravityBikeBladeBarrelDropCapability);

	UPROPERTY()
	FGravityBikeSplineBladeBarrelOnAttached OnAttached;

	UPROPERTY()
	FGravityBikeSplineBladeBarrelOnDetached OnDetached;

	AGravityBikeSpline GravityBike;
	float AttachTime = -1;

	bool bIsDropping = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(GravityBikeSpline::GetDriverPlayer());
	}

	void AttachGravityBike(AGravityBikeSpline InGravityBike)
	{
		GravityBike = InGravityBike;
		AttachTime = Time::GameTimeSeconds;
		OnAttached.Broadcast();

		UGravityBikeBladeBarrelEventHandler::Trigger_OnGravityBikeAttached(this);
	}

	void DetachGravityBike()
	{
		GravityBike = nullptr;
		OnDetached.Broadcast();
		AddActorCollisionBlock(this);

		UGravityBikeBladeBarrelEventHandler::Trigger_OnGravityBikeDetached(this);
	}

	bool IsGravityBikeAttached() const
	{
		return IsValid(GravityBike);
	}
};