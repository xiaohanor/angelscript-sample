enum EMoonMarketFlowerHatType
{
	Yellow,
	Blue,
	NonQuest
}

event void FOnMoonMarketFlowerHatStarted(AMoonMarketFlowerHat Hat);
event void FOnMoonMarketFlowerHatStopped(AMoonMarketFlowerHat Hat);

class AMoonMarketFlowerHat : AMoonMarketHoldableActor
{
	default InteractableTag = EMoonMarketInteractableTag::FlowerHat;
	default CompatibleInteractions.Add(EMoonMarketInteractableTag::Vehicle);
	default bCancelInteractionUponDeath = false;
	default bShowCancelPrompt = false;
	default bCancelByThunder = false;
	default InteractComp.ActionShapeTransform.Location = FVector(0,0,0);
	default InteractComp.bIsImmediateTrigger = true;
	
	FOnMoonMarketFlowerHatStarted OnMoonMarketFlowerHatStarted;
	FOnMoonMarketFlowerHatStarted OnMoonMarketFlowerHatStopped;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditAnywhere)
	EMoonMarketFlowerHatType Type;

	UPROPERTY(EditAnywhere)
	FLinearColor FlowerTint;

	AHazePlayerCharacter UsingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
		
		UMoonMarketPlayerFlowerSpawningComponent::Get(InteractingPlayer).SetHat(this);
		UsingPlayer = InteractingPlayer;
		OnMoonMarketFlowerHatStarted.Broadcast(this);
		UMoonMarketFlowerHatEventHandler::Trigger_OnPickedUp(this, FMoonMarketFlowerHatEffectParams(Player, ActorLocation));
	}

	void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		UMoonMarketPlayerFlowerSpawningComponent::Get(InteractingPlayer).RemoveHat(this);

		Super::OnInteractionStopped(Player);
		UsingPlayer = nullptr;
		OnMoonMarketFlowerHatStopped.Broadcast(this);
		UMoonMarketFlowerHatEventHandler::Trigger_OnHatDisintegrate(this, FMoonMarketFlowerHatEffectParams(Player, ActorLocation));
	}
};