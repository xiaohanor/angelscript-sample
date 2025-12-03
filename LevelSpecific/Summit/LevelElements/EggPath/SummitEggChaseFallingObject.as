event void FASummitEggChaseFallingObjectSignature();

class ASummitEggChaseFallingObject : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent SplineStartComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent)
	UInheritVelocityComponent InheritVelocityComp;
	default InheritVelocityComp.UnFollowHorizontalVelocityInheritance = 0.5;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY()
	UNiagaraSystem ExplosionEffect;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger TriggerRef;

	UPROPERTY()
	FVector DestinationUpVector = FVector::UpVector;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	bool bIsActivated;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 9.0;

	UPROPERTY(EditAnywhere)
	float DurationToCollision = 0.25;

	UPROPERTY(EditAnywhere)
	float DelayDuration = SMALL_NUMBER;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	FRuntimeFloatCurve Speed;
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(1.0, 1.0);

	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	FRuntimeFloatCurve MoveAnimationCurve;

	UPROPERTY(BlueprintReadOnly)
	FRotator EndingRotation;
	UPROPERTY(BlueprintReadOnly)
	FVector EndingPosition;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	float CrumbTimeOffset;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SplineActor != nullptr)
		{
			auto Spline = SplineActor.Spline;
			OnUpdate(0.0);
			DestinationComp.SetWorldLocation(Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength).GetLocation());
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor == nullptr)
			return;

		if (DelayDuration == 0)
			DelayDuration = SMALL_NUMBER;

		DurationToCollision = AnimationDuration - DurationToCollision;
		if (DurationToCollision <= 0)
			DurationToCollision = SMALL_NUMBER;

		if (TriggerRef != nullptr)
			TriggerRef.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActionQueueComp.ScrubTo(Time::PredictedGlobalCrumbTrailTime - CrumbTimeOffset);
	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (bIsActivated)
			return;

		if (!HasControl())
			return;

		CrumbActivate(Time::PredictedGlobalCrumbTrailTime);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		float AnimAlpha = MoveAnimationCurve.GetFloatValue(Alpha);

		FTransform TransformAtDistance = SplineActor.Spline.GetWorldTransformAtSplineFraction(AnimAlpha);
		FVector CurrentLocation = TransformAtDistance.Location;
		FQuat CurrentRotation = FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(DestinationUpVector, TransformAtDistance.Rotation.ForwardVector), Rotation.GetFloatValue(AnimAlpha));

		SetActorLocationAndRotation(CurrentLocation, CurrentRotation);
	}

	UFUNCTION()
	void OnFinished()
	{
		if (CameraShake != nullptr)
			Game::GetMio().PlayCameraShake(CameraShake, this);
		
		ActivatePlatformEffects();
	}

	UFUNCTION()
	void OnDelayFinished()
	{
		UASummitEggChaseFallingObjectEffectHandler::Trigger_OnStartMoving(this);
		BP_OnActivated();
	}

	UFUNCTION()
	void ActivatePlatformEffects()
	{
		BP_OnActivateEffect();
		UASummitEggChaseFallingObjectEffectHandler::Trigger_OnReachedDestination(this);
		SetActorTickEnabled(false);
		Deactivate();
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivate(float CrumbTime)
	{
		bIsActivated = true;
		CrumbTimeOffset = CrumbTime;
		ActionQueueComp.Idle(DelayDuration);
		ActionQueueComp.Event(this, n"OnDelayFinished");
		ActionQueueComp.Duration(AnimationDuration, this, n"OnUpdate");
		ActionQueueComp.Event(this, n"OnFinished");
		ActionQueueComp.ScrubTo(Time::PredictedGlobalCrumbTrailTime - CrumbTimeOffset);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void Deactivate()
	{
		bIsActivated = false;
		AddActorDisable(this);
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (auto Actor : AttachedActors)
			Actor.AddActorDisable(this);

		BP_OnDeactivated();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivated(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivateEffect(){}

}

UCLASS(Abstract)
class UASummitEggChaseFallingObjectEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedDestination() {}
}