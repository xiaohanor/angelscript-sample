class AIslandJetpackPickup : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Category = "Interaction")
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Both;
	default InteractComp.InteractionCapability = n"IslandJetpackPickupInteractionCapability";
	default InteractComp.MovementSettings.Type = EMoveToType::NoMovement;

	TPerPlayer<UIslandJetpackComponent> JetpackComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.AddInteractionCondition(this, FInteractionCondition(this, n"CanInteract"));	

		for(auto Player : Game::Players)
		{
			JetpackComps[Player] = UIslandJetpackComponent::Get(Player);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private EInteractionConditionResult CanInteract(const UInteractionComponent InteractionComponent,
	                                                AHazePlayerCharacter Player)
	{
		if(JetpackComps[Player] == nullptr)
		{
			JetpackComps[Player] = UIslandJetpackComponent::Get(Player);
			if(JetpackComps[Player] == nullptr)
				return EInteractionConditionResult::Disabled;
		}

		if(JetpackComps[Player].IsOn())
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}
}