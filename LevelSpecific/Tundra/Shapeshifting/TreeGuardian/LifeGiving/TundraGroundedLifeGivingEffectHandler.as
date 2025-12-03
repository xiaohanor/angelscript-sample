UCLASS(Abstract)
class UTundraGroundedLifeGivingEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	ATundraGroundedLifeGivingActor LifeGivingActor;

	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	UTundraLifeReceivingComponent LifeComp;

	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	UTundraGroundedLifeReceivingTargetableComponent GroundedTargetableComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LifeGivingActor = Cast<ATundraGroundedLifeGivingActor>(Owner);
		LifeComp = LifeGivingActor.LifeReceivingComp;
		GroundedTargetableComp = LifeGivingActor.Targetable;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundedFoundTarget() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundedLostTarget() {}

	// Will get called as soon as the tree guardian presses interact. OnLifeGivingStarted will get triggered a bit later.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterInteract() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLifeGivingStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLifeGivingStopped() {}
}