struct FTundraRangedLifeGivingActorOnStartInteractEffectParams
{
	UPROPERTY()
	float DurationUntilStartLifeGive;
}

UCLASS(Abstract)
class UTundraRangedLifeGivingActorEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	ATundraRangedLifeGivingActor LifeGivingActor;

	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	UTundraLifeReceivingComponent LifeComp;

	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	UTundraTreeGuardianRangedInteractionTargetableComponent RangedTargetableComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LifeGivingActor = Cast<ATundraRangedLifeGivingActor>(Owner);
		LifeComp = LifeGivingActor.LifeReceivingComponent;
		RangedTargetableComp = LifeGivingActor.RangedTargetable;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLookingAt() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopLookingAt() {}

	// Will get triggered as soon as the TreeGuardian interacts with this life giving actor, the life giving will then start when the roots have reached the point.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterInteract(FTundraRangedLifeGivingActorOnStartInteractEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLifeGivingStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLifeGivingStopped() {}
}