enum EMoonMarketGardenCatAnimState
{
	Mh,
	PushEnter,
	PushMh,
	PushExit
}

class AMoonMarketGardenCat : AMoonMarketCat
{
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams PushEnter;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams PushMh;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams PushExit;

	UPROPERTY(EditInstanceOnly)
	AMoonMarketGardenFatMushroom FatMushroom;

	EMoonMarketGardenCatAnimState AnimState;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		FInteractionCondition Condition;
		Condition.BindUFunction(this, n"CanTakeCat");
		InteractComp.AddInteractionCondition(this, Condition);
		
	}

	UFUNCTION()
	private EInteractionConditionResult CanTakeCat(const UInteractionComponent InteractionComponent,
	                                               AHazePlayerCharacter Player)
	{
		return EInteractionConditionResult::Enabled;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(FatMushroom.bIsPushed && !FatMushroom.bCatCaught)
		{
			if(AnimState == EMoonMarketGardenCatAnimState::Mh)
			{
				AnimState = EMoonMarketGardenCatAnimState::PushEnter;
				PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"PlayPushMh"), PushEnter);
			}
		}
		else
		{
			if(AnimState == EMoonMarketGardenCatAnimState::PushMh || AnimState == EMoonMarketGardenCatAnimState::PushEnter)
			{
				AnimState = EMoonMarketGardenCatAnimState::PushExit;
				PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"StopAnimations"), PushExit);
			}
		}
	}

	UFUNCTION()
	private void StopAnimations()
	{
		AnimState = EMoonMarketGardenCatAnimState::Mh;
		StopSlotAnimation();
	}

	UFUNCTION()
	private void PlayPushMh()
	{
		AnimState = EMoonMarketGardenCatAnimState::PushMh;
		PlaySlotAnimation(PushMh);
	}

	void InitiateCollectCatSoul(AHazePlayerCharacter Player, bool bPlayerInteracted = true) override
	{
		Super::InitiateCollectCatSoul(Player, bPlayerInteracted);
		StopAllSlotAnimations();
	}
};