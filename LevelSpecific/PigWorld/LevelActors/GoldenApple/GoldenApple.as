event void FGoldenApplePickedUpEvent();

UCLASS(Abstract)
class AGoldenApple : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent AppleRoot;

	UPROPERTY(DefaultComponent, Attach = AppleRoot)
	UStaticMeshComponent AppleMesh;

	UPROPERTY(DefaultComponent, Attach = AppleRoot)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	FGoldenApplePickedUpEvent OnPickedUp;

	bool bPickedUp = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"PickUp");
		FInteractionCondition Condition;
		Condition.BindUFunction(this, n"InteractCondition");
		InteractionComp.AddInteractionCondition(this, Condition);
	}

	UFUNCTION()
	private void PickUp(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		if (bPickedUp)
			return;

		bPickedUp = true;

		InteractionComp.Disable(this);

		UGoldenApplePlayerComponent GoldenApplePlayerComp = UGoldenApplePlayerComponent::GetOrCreate(Player);
		GoldenApplePlayerComp.PickUpApple(this);

		FGoldenApplePickupEventHandlerParams EventParams;
		EventParams.Player = Player;
		UGoldenAppleEventHandler::Trigger_ApplePickup(this, EventParams);

		OnPickedUp.Broadcast();
	}

	UFUNCTION()
	private EInteractionConditionResult InteractCondition(const UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		// Don't pick other apple if already married to one
		UGoldenApplePlayerComponent GoldenApplePlayerComp = UGoldenApplePlayerComponent::GetOrCreate(Player);
		if (GoldenApplePlayerComp != nullptr)
			if (GoldenApplePlayerComp.CurrentApple != nullptr)
				return EInteractionConditionResult::Disabled;

		// Never get apple when airborne
		if (!Player.IsOnWalkableGround())
			return EInteractionConditionResult::DisabledVisible;

		// Can't screw around when stretched
		UPlayerPigStretchyLegsComponent StretchyLegsComponent = UPlayerPigStretchyLegsComponent::Get(Player);
		if (StretchyLegsComponent != nullptr)
		{
			if (StretchyLegsComponent.IsStretching() || StretchyLegsComponent.IsStretched() || StretchyLegsComponent.IsAirborneAfterStretching())
				return EInteractionConditionResult::DisabledVisible;
		}

		return EInteractionConditionResult::Enabled;
	}
}