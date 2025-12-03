class ASkylineMallChaseDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DoorRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MioMashRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ZoeMashRoot;

	UPROPERTY()
	FButtonMashSettings ButtonMashSettings;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditAnywhere)
	UAnimSequence MioStruggleAnim;

	UPROPERTY(EditAnywhere)
	UAnimSequence ZoeStruggleAnim;

	bool bStarted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoubleInteract.OnCompletedBlendingIn.AddUFunction(this, n"StartDoubleInteract");
	}


	UFUNCTION()
	private void StartDoubleInteract(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction,
	                                 UInteractionComponent InteractionComponent)
	{
		FButtonMashSettings PlayerMashSettings = ButtonMashSettings;
		PlayerMashSettings.WidgetAttachComponent = Player == Game::Mio ? MioMashRoot : ZoeMashRoot;
		Player.StartButtonMash(PlayerMashSettings, this);
		PlayerMashSettings.bShowButtonMashWidget = false;
		bStarted = true;
	}


	UFUNCTION()
	void StopMash()
	{
		Game::Mio.StopButtonMash(this);
		Game::Zoe.StopButtonMash(this);
		
		bStarted = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bStarted && !Game::Mio.bIsControlledByCutscene)
		{
			Game::Mio.PlaySlotAnimation(Animation = MioStruggleAnim, bLoop = true);
			Game::Zoe.PlaySlotAnimation(Animation = ZoeStruggleAnim, bLoop = true);
		}
	}


};