class USanctuaryCatapultRotatorInteractionComponent : UInteractionComponent
{
	AHazePlayerCharacter InteractingPlayer;

	bool bInteracting = false;
	bool bPushing = false;

	private UButtonMashComponent ButtonMashComp = nullptr;
	float MashProgress;
	float PreviousFrameMashProgress;
	FHazeAcceleratedFloat AccMashProgress;


	ASanctuaryCatapultRotator CatapultRotator;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		CatapultRotator = Cast<ASanctuaryCatapultRotator>(Owner);

		

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
		
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		InteractingPlayer = Player;
		InteractingPlayer.AttachToComponent(this, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		StopPushing();

		Player.StartButtonMash(CatapultRotator.MashSettings, this);
		ButtonMashComp = UButtonMashComponent::Get(Player);
		ButtonMashComp.SetAllowButtonMashCompletion(this, false);
		bInteracting = true;
	}

		private void StartPushing()
	{
		bPushing = true;

		InteractingPlayer.PlaySlotAnimation(Animation = CatapultRotator.PushAnim, bLoop = true);

	}

	private void StopPushing()
	{
		bPushing = false;

		InteractingPlayer.PlaySlotAnimation(Animation = CatapultRotator.IdleAnim, bLoop = true);
	}
};