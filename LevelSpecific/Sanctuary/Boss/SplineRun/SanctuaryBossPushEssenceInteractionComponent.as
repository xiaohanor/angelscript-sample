class USanctuaryBossPushEssenceInteractionComponent : UInteractionComponent
{
	UPROPERTY()
	FOnButtonMashCompleted ButtonMashCompleted;

	AHazePlayerCharacter InteractingPlayer;


	private UButtonMashComponent ButtonMashComp = nullptr;

	float MashProgress;
	float PreviousFrameMashProgress;
	FHazeAcceleratedFloat AccMashProgress;
	
	bool bInteracting = false;
	bool bPushing = false;

	ASanctuaryBossSplineRunPushEssence PushEssence;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		PushEssence = Cast<ASanctuaryBossSplineRunPushEssence>(Owner);

		OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		AccMashProgress.AccelerateTo(MashProgress, 1.0, DeltaSeconds);

		if(bInteracting)
		{
			MashProgress=ButtonMashComp.GetButtonMashProgress(this);
			if(MashProgress>PreviousFrameMashProgress && !bPushing)
				StartPushing();

			if(MashProgress<PreviousFrameMashProgress && bPushing)
				StopPushing();
		}
		PreviousFrameMashProgress = MashProgress;
	}

	UFUNCTION()
	private void HandleInteractionStopped(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.StopButtonMash(this);
		bInteracting = false;
		Player.StopAllSlotAnimations();

		if(!PushEssence.bCompleted)
		{
			MashProgress = 0.0;
		}
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{

		InteractingPlayer = Player;
		InteractingPlayer.AttachToComponent(this, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		StopPushing();

		Player.StartButtonMash(PushEssence.MashSettings, this, ButtonMashCompleted);
		ButtonMashComp = UButtonMashComponent::Get(Player);
		ButtonMashComp.SetAllowButtonMashCompletion(this, false);

		bInteracting = true;
	}

	private void StartPushing()
	{
		bPushing = true;

		InteractingPlayer.PlaySlotAnimation(Animation = PushEssence.PushAnim, bLoop = true);

	}

	private void StopPushing()
	{
		bPushing = false;

		InteractingPlayer.PlaySlotAnimation(Animation = PushEssence.IdleAnim, bLoop = true);

	}


};