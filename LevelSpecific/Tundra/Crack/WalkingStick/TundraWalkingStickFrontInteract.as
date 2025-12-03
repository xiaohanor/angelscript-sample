UCLASS(Abstract)
class UTundraWalkingStickFrontInteractEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ScreamStarted() {}
	
}

class ATundraWalkingStickFrontInteract : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UTundraGroundedLifeReceivingTargetableComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeComp;

	UPROPERTY(EditAnywhere)
	ATundraGroundedLifeGivingActor LifeGiveActorRef;

	UPROPERTY(EditAnywhere)
	ATundraWalkingStick WalkingStickRef;

	EAttachmentRule AttachmentRule = EAttachmentRule::KeepWorld;

	UFUNCTION(BlueprintEvent)
	void BP_ScreamWasCalled() {}
}