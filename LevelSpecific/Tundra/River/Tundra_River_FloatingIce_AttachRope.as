event void FFloatingIceAttachRopeEvent(ATundra_River_FloatingIce_AttachRope AttachRope);

class ATundra_River_FloatingIce_AttachRope : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCableComponent Cable_Bottom;
	default Cable_Bottom.EndLocation = FVector(0,0,0);

	UPROPERTY(DefaultComponent, Attach = Root)
	UCableComponent Cable_Top;
	default Cable_Top.EndLocation = FVector(0,0,0);

	UPROPERTY(DefaultComponent, Attach = Root)
	UOneShotInteractionComponent InteractionComp;
	default InteractionComp.bIsImmediateTrigger = true;
	default InteractionComp.UsableByPlayers = EHazeSelectPlayer::Mio;
	default InteractionComp.MovementSettings.Type = EMoveToType::NoMovement;
	default InteractionComp.ActionShape.Type = EHazeShapeType::Sphere;
	default InteractionComp.ActionShape.SphereRadius = 600;
	default InteractionComp.FocusShape.SphereRadius = 1500;

	UPROPERTY()
	FHazePlayAdditiveAnimationParams BiteAnimationData;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	FFloatingIceAttachRopeEvent Untethered;

	UPROPERTY()
	bool bCompleted = false;

	UPROPERTY(EditInstanceOnly)
	float CableWidth = 30;

	UPROPERTY(EditInstanceOnly)
	float TopLength = 0;

	UPROPERTY(EditInstanceOnly)
	float BottomLength = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
	}

	UFUNCTION(CallInEditor)
	void Init()
	{	
		Cable_Bottom.CableWidth = CableWidth;
		Cable_Top.CableWidth = CableWidth;
		Cable_Top.SetRelativeLocation(FVector(0,0,TopLength));
		Cable_Bottom.SetRelativeLocation(FVector(0,0,-BottomLength));
	}

	UFUNCTION()
	void SetInteractionEnabled(bool bNewEnabled)
	{
		if(!bCompleted)
		{
			if(bNewEnabled)
				InteractionComp.Enable(this);

			else
				InteractionComp.Disable(this);
		}
	}

	UFUNCTION()
	void InteractionStarted(UInteractionComponent UsedInteractionComp, AHazePlayerCharacter Player)
	{
		if(!bCompleted)
		{
			bCompleted = true;
			InteractionComp.Disable(this);
			Cable_Top.bAttachEnd = false;
			Cable_Bottom.bAttachEnd = false;
			Cable_Bottom.bAttachStart = false;
			Cable_Bottom.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, true);
			SetActorHiddenInGame(true);
			Untethered.Broadcast(this);
			UTundra_River_FloatingIce_AttachRope_EffectHandler::Trigger_TetherRemoved(this);
			FHazeAnimationDelegate OnBlendingOut;
			UTundraPlayerOtterComponent::Get(Player).GetShapeMesh().PlayAdditiveAnimation(OnBlendingOut, BiteAnimationData);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbResetInteraction()
	{
		ResetInteraction();
	}

	UFUNCTION()
	void ResetInteraction()
	{
		Cable_Top.bAttachEnd = true;
		Cable_Bottom.bAttachEnd = true;
		Cable_Bottom.bAttachStart = true;
		InteractionComp.Enable(this);
		bCompleted = false;
		//Cable_Bottom.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, true);
	}
};