class AFireworksCart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.bIsImmediateTrigger = true;
	FMoveToParams Params;
	default Params.Type = EMoveToType::NoMovement;
	default InteractComp.MovementSettings = Params;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CartMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Origin;

	UPROPERTY()
	TSubclassOf<AFireworksRocket> RocketClass;

	float DisableDuration = 0.5;
	float DisableTime = 0.5;

	int FireworkId;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		FInteractionCondition Condition;
		Condition.BindUFunction(this, n"CheckCanInteract");
		InteractComp.AddInteractionCondition(this, Condition);
	}

	UFUNCTION()
	private EInteractionConditionResult CheckCanInteract(
	                                                     const UInteractionComponent InteractionComponent,
	                                                     AHazePlayerCharacter Player)
	{
		if(Time::GetGameTimeSince(DisableTime) < DisableDuration)
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		DisableTime = Time::GameTimeSeconds + DisableDuration;
		AFireworksRocket Rocket = SpawnActor(RocketClass, Origin.WorldLocation, Origin.WorldRotation);
		Rocket.MakeNetworked(this, FireworkId);
		Rocket.SetActorControlSide(Player);
		FireworkId++;
		Rocket.OwningPlayer = Player;
		auto UserComp = UPlayerFireworksComponent::Get(Player);
		if (UserComp != nullptr)
			UserComp.SetFirework(Rocket); 
		UFireworksCartEffectHandler::Trigger_OnFireworksActivated(this, FMoonMarketFireworkParams(InteractComp.WorldLocation));
		UFireworksRocketEffectHandler::Trigger_OnPickedUp(Rocket, FMoonMarketInteractingPlayerEventParams(Player));
	}
};