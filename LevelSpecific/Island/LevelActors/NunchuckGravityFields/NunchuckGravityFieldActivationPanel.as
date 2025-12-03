event void FEventGravityFieldActivated();
event void FEventGravityFieldDeactivated();
event void FEventGravityFieldProgress(float Progress);

UCLASS(Abstract)
class ANunchuckGravityFieldActivationPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent ProgressSyncComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Base;

	UPROPERTY(DefaultComponent, Attach = Base)
	UStaticMeshComponent Panel;

	UPROPERTY(EditAnywhere)
	UAnimSequence InteractionAnimation_Start;

	UPROPERTY(EditAnywhere)
	UAnimSequence InteractionAnimation_Loop;

	UPROPERTY(EditAnywhere)
	UAnimSequence InteractionAnimation_End;

	UPROPERTY(EditAnywhere)
	UMaterialInstance ActiveMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInstance DeactiveMaterial;

	UPROPERTY()
	FEventGravityFieldActivated GravityActivated;

	UPROPERTY()
	FEventGravityFieldDeactivated GravityDeactivated;

	UPROPERTY()
	FEventGravityFieldProgress ProgressEvent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComponent;
	default InteractionComponent.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractionComponent.bPlayerCanCancelInteraction = false;
	default InteractionComponent.bIsImmediateTrigger = false;
	default InteractionComponent.MovementSettings = FMoveToParams::SmoothTeleport();
	default InteractionComponent.InteractionCapability = n"NunchuckGravityFieldActivationPanelCapability";

	default PrimaryActorTick.bStartWithTickEnabled = false;
	bool bActive = false;
	AHazePlayerCharacter InteractionPlayer = nullptr;

	UPROPERTY(EditInstanceOnly)
	float ProgressPerSecond = 1.0;

	UPROPERTY(EditInstanceOnly)
	bool bProgressWrapAround = false;

	UPROPERTY(EditInstanceOnly)
	float Progress = 0.0;

	UPROPERTY()
	FTutorialPrompt TutorialPrompt;
	default TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;

	UPROPERTY(EditInstanceOnly)
	FName InteractionText = n"Interact";

	UPROPERTY(EditInstanceOnly)
	bool bImmediatelyExit = false;

	

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Panel.SetMaterial(0, DeactiveMaterial);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComponent.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
		InteractionComponent.OnInteractionStopped.AddUFunction(this, n"InteractionStopped");
		//TutorialPrompt.Text = FText::FromName(InteractionText);
		
		InteractionComponent.bPlayerCanCancelInteraction = !bImmediatelyExit;
	}

	UFUNCTION()
	private void InteractionStarted(UInteractionComponent OneShotInteraction, AHazePlayerCharacter Player)
	{
		InteractionPlayer = Player;
		FHazeSlotAnimSettings AnimSettings;
		AnimSettings.BlendTime = 0.2;
		Player.PlaySlotAnimation(InteractionAnimation_Start, AnimSettings);

		if(!bImmediatelyExit)
		{
			Timer::SetTimer(this, n"EnterInputState", InteractionAnimation_Start.GetPlayLength());
		}

		else
		{
			Timer::SetTimer(this, n"ToggleInteraction", InteractionAnimation_Start.GetPlayLength());
		}

	}

	UFUNCTION()
	private void ToggleInteraction()
	{
		if(!bActive)
		{
			ActivateGravityField();
		}

		else
		{
			DeactivateGravityField();
		}
		
		InteractionComponent.KickAnyPlayerOutOfInteraction();
	}
	
	UFUNCTION()
	private void InteractionStopped(UInteractionComponent OneShotInteraction, AHazePlayerCharacter Player)
	{
		FHazeSlotAnimSettings AnimSettings;
		AnimSettings.BlendTime = 0.2;
		InteractionPlayer.PlaySlotAnimation(InteractionAnimation_End, AnimSettings);
		
		if(!bImmediatelyExit)
		{
			Player.RemoveTutorialPromptByInstigator(this);
			DeactivateGravityField();
		}
	}

	UFUNCTION()
	private void EnterInputState()
	{
		FHazeSlotAnimSettings AnimSettings;
		AnimSettings.BlendTime = 0.2;
		AnimSettings.bLoop = true;
		InteractionPlayer.PlaySlotAnimation(InteractionAnimation_Loop, AnimSettings);
		InteractionPlayer.ShowTutorialPrompt(TutorialPrompt, this);
		ActivateGravityField();
	}

	UFUNCTION()
	private void ActivateGravityField()
	{
		GravityActivated.Broadcast();
		Panel.SetMaterial(0, ActiveMaterial);
		bActive = true;
	}

	UFUNCTION()
	private void DeactivateGravityField()
	{
		GravityDeactivated.Broadcast();
		Panel.SetMaterial(0, DeactiveMaterial);
		bActive = false;
	}

	UFUNCTION()
	void TickInput(FVector2D Input, float DeltaSeconds)
	{

		if(ProgressSyncComponent.HasControl())
		{
			Progress += (ProgressPerSecond * DeltaSeconds * Input.X);
			Print("Progress: "+Progress, 0);
			Print("Input: " + Input.X, 0);
			
			if(bProgressWrapAround)
			{
				// Let Progress continue beyond 1, but Broadcast a wrapped value (To avoid wierd lerp on network)
				//Progress = Math::Wrap(Progress, 0.0, 1.0);
			}
			else
			{
				Progress = Math::Clamp(Progress, 0.0, 1.0);
			}

			ProgressSyncComponent.Value = Progress;
		}

		else
		{
			Progress = ProgressSyncComponent.Value;
			Print("No Crtl Progress: "+Progress, 0);
		}

		// Let Progress continue beyond 1, but Broadcast a wrapped value (To avoid wierd lerp on network)
		ProgressEvent.Broadcast(Math::Wrap(Progress, 0.0, 1.0));
	}
}