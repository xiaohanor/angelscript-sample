class UBigCrackBirdInteractionComponent : UInteractionComponent
{
	default MovementSettings.Type = EMoveToType::NoMovement;
	default bIsImmediateTrigger = true;

	ABigCrackBird Bird;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Bird = Cast<ABigCrackBird>(Owner);
		AddInteractionCondition(this, FInteractionCondition(this, n"CheckInteractionAvailable"));
		OnInteractionStarted.AddUFunction(this, n"OnInteract");
	}

	UFUNCTION()
	private void OnInteract(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		UBigCrackBirdCarryComponent::Get(Player).SetBirdPickupTarget(Bird);
	}

	UFUNCTION()
	private EInteractionConditionResult CheckInteractionAvailable(
	                                                              const UInteractionComponent InteractionComponent,
	                                                              AHazePlayerCharacter Player)
	{
		UBigCrackBirdCarryComponent BirdCarryComp = UBigCrackBirdCarryComponent::Get(Player);
	
		if(BirdCarryComp == nullptr)
			return EInteractionConditionResult::Disabled;

		//Cannot interact with bird if player is currently holding bird
		if(BirdCarryComp.GetCurrentState() != ETundraPlayerCrackBirdState::None)
			return EInteractionConditionResult::Disabled;

		if(Bird.IsPickupStarted())
			return EInteractionConditionResult::Disabled;

		if(Bird.bIsLaunched)
			return EInteractionConditionResult::Disabled;

		if(Bird.InteractingPlayer != nullptr)
			return EInteractionConditionResult::Disabled;

		if(!UPlayerMovementComponent::Get(Player).HasGroundContact())
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}
}