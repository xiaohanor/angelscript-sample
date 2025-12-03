UCLASS(Abstract)
class USplitTraversalControllableTurretRocketEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}
}

class ASplitTraversalControllableTurretRocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float Speed = 1000.0;

	UPROPERTY()
	float Radius = 50.0;

	UPROPERTY()
	float LifeTime = 5.0;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	AActor IgnoredActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.UseSphereShape(Radius);
		Trace.IgnoreActor(IgnoredActor);

		FVector DeltaMovement = ActorForwardVector * Speed * DeltaSeconds;

		const FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMovement);
		if(Hit.bBlockingHit)
		{
			SetActorLocation(Hit.ImpactPoint);
			Explode();
		}

		AddActorWorldOffset(DeltaMovement);

		if (GameTimeSinceCreation > LifeTime)
			DestroyActor();
	}

	private void Explode()
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		BP_Explode();
		USplitTraversalControllableTurretRocketEventHandler::Trigger_OnExplode(this);
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode(){}
};