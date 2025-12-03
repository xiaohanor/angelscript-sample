event void FMeditationInteractionEvent();

class ATundra_IcePalace_MeditationInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = InteractionComp)
	UHazeSkeletalMeshComponentBase PreviewMesh;
	default PreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default PreviewMesh.bIsEditorOnly = true;
	default PreviewMesh.bHiddenInGame = true;

	UPROPERTY(EditInstanceOnly)
	ATundra_IcePalace_MeditationInteraction OtherMeditationInteraction;

	UPROPERTY()
	FMeditationInteractionEvent OnMeditationSeqStart;
	UPROPERTY()
	FMeditationInteractionEvent OnMeditationSeqStop;

	bool bCurrentlyInteracting = false;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MioMeditationAnimation;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ZoeMeditationAnimation;

	bool bInteractionDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnMeditationInteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"OnMeditationInteractionStopped");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Temp!!
		if(InteractionComp.UsableByPlayers == EHazeSelectPlayer::Mio)
		{
			if(UTundraPlayerShapeshiftingComponent::Get(Game::Mio).IsBigShape() && bInteractionDisabled)
			{
				bInteractionDisabled = false;
				InteractionComp.Enable(this);
			}
			else if(!UTundraPlayerShapeshiftingComponent::Get(Game::Mio).IsBigShape() && !bInteractionDisabled)
			{
				bInteractionDisabled = true;
				InteractionComp.Disable(this);
			}
		}
		else
		{
			if(UTundraPlayerShapeshiftingComponent::Get(Game::Zoe).IsBigShape() && bInteractionDisabled)
			{
				bInteractionDisabled = false;
				InteractionComp.Enable(this);
			}
			else if(!UTundraPlayerShapeshiftingComponent::Get(Game::Zoe).IsBigShape() && !bInteractionDisabled)
			{
				bInteractionDisabled = true;
				InteractionComp.Disable(this);
			}
		}
	}

	UFUNCTION()
	private void OnMeditationInteractionStarted(UInteractionComponent InteractionComponent,
	                                            AHazePlayerCharacter Player)
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big, false);
		Player.BlockCapabilities(CapabilityTags::Outline, this);
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Player.IsMio() ? MioMeditationAnimation : ZoeMeditationAnimation;
		AnimParams.bLoop = true;
		
		if(Player.IsMio())
		{
			UTundraPlayerSnowMonkeyComponent::Get(Game::Mio).GetShapeMesh().PlaySlotAnimation(AnimParams);
		}
		else
		{
			UTundraPlayerTreeGuardianComponent::Get(Game::Zoe).GetShapeMesh().PlaySlotAnimation(AnimParams);
		}

		bCurrentlyInteracting = true;

		if(bOtherMeditationInteractionActive())
		{
			OnMeditationSeqStart.Broadcast();
		}
	}
	
	UFUNCTION()
	private void OnMeditationInteractionStopped(UInteractionComponent InteractionComponent,
	                                            AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(CapabilityTags::Outline, this);
		if(Player.IsMio())
		{
			UTundraPlayerSnowMonkeyComponent::Get(Game::Mio).GetShapeMesh().StopAllSlotAnimations();
		}
		else
		{
			UTundraPlayerTreeGuardianComponent::Get(Game::Zoe).GetShapeMesh().StopAllSlotAnimations();
		}

		bCurrentlyInteracting = false;

		OnMeditationSeqStop.Broadcast();
	}

	bool bOtherMeditationInteractionActive()
	{
		if(OtherMeditationInteraction.bCurrentlyInteracting)
			return true;
		else
			return false;
	}
};