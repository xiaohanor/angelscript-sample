class AMoonMarketPolymorphChair : AMoonMarketInteractableActor
{
	default InteractableTag = EMoonMarketInteractableTag::Vehicle;
	default CompatibleInteractions.Add(EMoonMarketInteractableTag::Balloon);
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMoonMarketPolymorphShapeComponent ShapeComp;
	default ShapeComp.ShapeData.bIsBubbleBlockingShape = true;
	default ShapeComp.ShapeData.bCanDash = true;
	default ShapeComp.ShapeData.bUseCustomMovement = false;
	default ShapeComp.ShapeData.bCancelByThunder = true;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams EnterAnim;
	
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams SitAnim;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	
		for(int i = 0; i < int(EMoonMarketInteractableTag::MAX); i++)
		{
			if(EMoonMarketInteractableTag(i) == EMoonMarketInteractableTag::Vehicle)
				continue;

			if(EMoonMarketInteractableTag(i) == EMoonMarketInteractableTag::Shapeshift)
				continue;

			CompatibleInteractions.Add(EMoonMarketInteractableTag(i));
		}

		FInteractionCondition Condition;
		Condition.BindUFunction(this, n"InteractCondition");
		InteractComp.AddInteractionCondition(this, Condition);
	}

	UFUNCTION()
	private EInteractionConditionResult InteractCondition(
	                                                      const UInteractionComponent InteractionComponent,
	                                                      AHazePlayerCharacter Player)
	{
		if(Player == Cast<AHazePlayerCharacter>(AttachParentActor))
			return EInteractionConditionResult::Disabled;
		
		if(Player == nullptr)
		{
			auto MorphComp = UPolymorphResponseComponent::Get(AttachParentActor);
			if(MorphComp != nullptr)
			{
				if(Time::GetGameTimeSince(MorphComp.LastMorphTime) > MorphComp.PolymorphDuration - 2.5)
					return EInteractionConditionResult::Disabled;
			}
		}

		return EInteractionConditionResult::Enabled;
	}

	void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"OnEnterAnimComplete"), EnterAnim);
		Player.AttachToActor(this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, n"InteractionCancel", this);

		if (AttachParentActor != nullptr && AttachParentActor.IsA(AHazePlayerCharacter))
			Online::UnlockAchievement(n"PlayerChair");
	}


	void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		if(InteractingPlayer == nullptr)
			return;

		InteractingPlayer.DetachFromActor();
		InteractingPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		InteractingPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Super::OnInteractionStopped(InteractingPlayer);
		Player.StopSlotAnimation();
	}

	UFUNCTION()
	void OnEnterAnimComplete()
	{
		if(InteractingPlayer != nullptr)
			InteractingPlayer.PlaySlotAnimation(SitAnim);
	}
	
};