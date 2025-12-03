event void FBranchLeverActivated();

UCLASS(Abstract)
class USplitTraversalBranchLeverEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeverPulled() {}
}

class ASplitTraversalBranchLever : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent BranchRotateComp;

	UPROPERTY(DefaultComponent, Attach = BranchRotateComp)
	UStaticMeshComponent BranchMeshComp;

	UPROPERTY()
	FBranchLeverActivated OnActivated;

	UPROPERTY()
	FBranchLeverActivated OnReachedEnd;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	//Animations

	AHazeAnimActor LeverAnimActor;

	UPROPERTY()
	UAnimSequence PullAnim;
	UPROPERTY()
	UAnimSequence LeverClosedAnim;
	UPROPERTY()
	UAnimSequence LeverActivateAnim;
	UPROPERTY()
	UAnimSequence LeverOpenAnim;

	FHazeAnimationDelegate PlayerInteractionBlendedOut;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		PlayerInteractionBlendedOut.BindUFunction(this, n"InteractionBlendedOut");

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (auto AttachedActor : AttachedActors)
		{
			auto AnimActor = Cast<AHazeAnimActor>(AttachedActor);
			if (AnimActor != nullptr)
				LeverAnimActor = AnimActor;
		}

		InteractionComp.AddInteractionCondition(this, FInteractionCondition(this, n"InteractionCondition"));
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
			Game::Mio.PlaySlotAnimation(Animation = PullAnim, OnBlendingOut = PlayerInteractionBlendedOut);
			Game::Mio.BlockCapabilities(CapabilityTags::Movement, this);

			LeverAnimActor.PlaySlotAnimation(Animation = LeverActivateAnim);

			OnActivated.Broadcast();
			InteractionComponent.Disable(this);

			BP_PlayFF();

			QueueComp.Idle(0.75);
			QueueComp.Event(this, n"PlayAudio");
			QueueComp.Idle(0.5);
			QueueComp.Event(this, n"LeverReachedBottom");
			QueueComp.Idle(0.75);
			QueueComp.Event(this, n"DelayedActivation");	
	}

	UFUNCTION(BlueprintEvent)
	private void BP_PlayFF(){}

	UFUNCTION()
	private void PlayAudio()
	{
		USplitTraversalBranchLeverEventHandler::Trigger_OnLeverPulled(this);
	}

	UFUNCTION()
	private void LeverReachedBottom()
	{
		bActivated = true;
		BP_Activated();
		BranchMeshComp.SetSimulatePhysics(true);
		Game::Mio.BlockCapabilities(CapabilityTags::MovementInput, this);
		Game::Mio.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION()
	private void InteractionBlendedOut()
	{
		Game::Mio.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION()
	private EInteractionConditionResult InteractionCondition(
	                                                         const UInteractionComponent InteractionComponent,
	                                                         AHazePlayerCharacter Player)
	{
		//Checking if there is ground where the player will interact

		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		auto HitResult = Trace.QueryTraceSingle(InteractionComp.WorldLocation + FVector::UpVector * 50.0, InteractionComp.WorldLocation + FVector::UpVector * -50.0);

		if (HitResult.bBlockingHit)
			return EInteractionConditionResult::Enabled;
		else
			return EInteractionConditionResult::DisabledVisible;
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activated()
	{}

	UFUNCTION()
	private void DelayedActivation()
	{
		OnReachedEnd.Broadcast();
	}
};