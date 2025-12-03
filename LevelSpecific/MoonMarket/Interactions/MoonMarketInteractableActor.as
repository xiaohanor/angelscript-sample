enum EMoonMarketInteractableTag
{
	None,
	Balloon,
	Potion,
	Shapeshift,
	FlowerHat,
	Lantern,
	Wand,
	Ingredient,
	Vehicle,
	MAX
}

UCLASS(Abstract)
class AMoonMarketInteractableActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractComp;
	default InteractComp.MovementSettings.Type = EMoveToType::NoMovement;
	default InteractComp.bIsImmediateTrigger = true;

	TArray<AHazePlayerCharacter> InteractingPlayers;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter InteractingPlayer;

	EMoonMarketInteractableTag InteractableTag;

	TArray<EMoonMarketInteractableTag> CompatibleInteractions;

	bool bCancelInteractionUponDeath = true;

	bool bCancelByThunder = true;

	bool bShowCancelPrompt = true;

	UPROPERTY(EditDefaultsOnly)
	bool bUseCustomCancelText = false;

	UPROPERTY(Meta = (EditCondition = "bUseCustomCancelText", EditConditionHides))
	FText CustomCancelText;

	UPROPERTY(EditAnywhere)
	const bool bMultiplayerInteract = false;

	UPROPERTY(EditAnywhere)
	float InteractionEnabledDelay = 0.5;

	float StartInteractionTime;
	float StopInteractionTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		OnDestroyed.AddUFunction(this, n"HandleDestroyed");

		FInteractionCondition Condition;
		Condition.BindUFunction(this, n"CanInteract");
		InteractComp.AddInteractionCondition(this, Condition);
	}

	UFUNCTION()
	private EInteractionConditionResult CanInteract(const UInteractionComponent InteractionComponent,
	                                                AHazePlayerCharacter Player)
	{
		if(Time::GetGameTimeSince(StopInteractionTime) < InteractionEnabledDelay)
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}

	UFUNCTION()
	protected void HandleDestroyed(AActor DestroyedActor)
	{
		for(int i = InteractingPlayers.Num() -1; i >= 0; i--)
			StopInteraction(InteractingPlayers[i]);

		InteractingPlayers.Empty();
		InteractingPlayer = nullptr;
	}

	UFUNCTION()
	void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		if(bMultiplayerInteract)
			InteractionComponent.DisableForPlayer(Player, this);
		else
			InteractComp.Disable(this);

		InteractingPlayers.Add(Player);
		InteractingPlayer = Player;

		SetActorControlSide(Player);

		if(HasControl())
			UMoonMarketPlayerInteractionComponent::Get(Player).CrumbStartNewInteraction(this);
	}

	void StopInteraction(AHazePlayerCharacter Player)
	{
		if(Player == nullptr)
			return;

		UMoonMarketPlayerInteractionComponent::Get(Player).StopInteraction(this);
	}

	void OnInteractionStopped(AHazePlayerCharacter Player)
	{
		StopInteractionTime = Time::GameTimeSeconds;
		InteractingPlayers.Remove(Player);
		InteractingPlayer = nullptr;

		if(bMultiplayerInteract)
			InteractComp.EnableForPlayer(Player, this);
		else
			InteractComp.Enable(this);
	}

	void OnInteractionCanceled()
	{
	}
};