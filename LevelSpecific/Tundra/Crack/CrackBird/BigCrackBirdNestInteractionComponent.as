class UBigCrackBirdNestInteractionComponent : UInteractionComponent
{
	default MovementSettings.Type = EMoveToType::NoMovement;
	default bIsImmediateTrigger = true;

	ABigCrackBirdNest Nest;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Nest = Cast<ABigCrackBirdNest>(Owner);
		AddInteractionCondition(this, FInteractionCondition(this, n"CheckInteractionAvailable"));
		OnInteractionStarted.AddUFunction(this, n"OnInteract");
	}

	UFUNCTION()
	private void OnInteract(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		UBigCrackBirdCarryComponent::Get(Player).SetBirdPutDownTarget(Nest);
	}

	UFUNCTION()
	private EInteractionConditionResult CheckInteractionAvailable(
	                                                              const UInteractionComponent InteractionComponent,
	                                                              AHazePlayerCharacter Player)
	{
		//Cannot interact with nest if it currently holds a bird
		if(Nest.Bird != nullptr)
			return EInteractionConditionResult::Disabled;

		//Cannot interact with nest if player is not carrying a bird
		UBigCrackBirdCarryComponent BirdCarryComp = UBigCrackBirdCarryComponent::Get(Player);
		if(BirdCarryComp.GetCurrentState() != ETundraPlayerCrackBirdState::Carrying)
			return EInteractionConditionResult::Disabled;

		//Cannot interact with nest if player is too close
		// float Dist = Player.ActorLocation.Distance(Owner.ActorLocation);
		// if(Dist < Nest.DistToPickupBird - 100)
		// 	return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}
}