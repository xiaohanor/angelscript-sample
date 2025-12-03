enum EMoonMarketCauldronIngredient
{
	Cone,
	Wind,
	Organic
}

UCLASS(Abstract)
class AMoonMarketCauldronIngredient : AMoonMarketHoldableActor
{
	default InteractableTag = EMoonMarketInteractableTag::Ingredient;
	default bResetTransformOnDropped = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditAnywhere)
	EMoonMarketCauldronIngredient IngredientType;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor IngredientColor;

	UPROPERTY(EditAnywhere)
	FVector RelativeOffset;

	UPROPERTY(EditAnywhere)
	FRotator RelativeRotation;

	AMoonMarketCauldronIngredientPile IngredientPile;

	TOptional<FTraversalTrajectory> EnterCauldronTrajectory;
	bool bDroppedInCauldron = false;
	float TimeSinceDropped = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnDestroyed.AddUFunction(this, n"HandleDestroyed");
		InteractComp.AddInteractionCondition(this, FInteractionCondition(this, n"InteractCondition"));
		UMoonMarketIngredientEventHandler::Trigger_OnPickedUp(this);
	}

	void DropInCauldron(FVector TargetLocation)
	{
		UMoonMarketIngredientEventHandler::Trigger_OnThrown(this);
		bDroppedInCauldron = true;
		const float Gravity = 2000;

		FTraversalTrajectory Trajectory;
		Trajectory.LaunchLocation = ActorLocation;
		Trajectory.LandLocation = TargetLocation;
		Trajectory.Gravity = FVector::DownVector * Gravity;
		Trajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Trajectory.LaunchLocation, Trajectory.LandLocation, Gravity, 20);
		EnterCauldronTrajectory.Set(Trajectory);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!EnterCauldronTrajectory.IsSet())
			return;

		TimeSinceDropped += DeltaSeconds;
		FVector NewLocation = EnterCauldronTrajectory.Value.GetLocation(TimeSinceDropped);
		SetActorLocation(NewLocation);
	}

	UFUNCTION()
	private EInteractionConditionResult InteractCondition(
	                                                      const UInteractionComponent InteractionComponent,
	                                                      AHazePlayerCharacter Player)
	{
		return EInteractionConditionResult::Disabled;
	}

	void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
	}

	void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		UMoonMarketWitchCauldronPlayerComponent PlayerComp = UMoonMarketWitchCauldronPlayerComponent::Get(InteractingPlayer);

		if(PlayerComp.HeldIngredient == this)
			PlayerComp.HeldIngredient = nullptr;

		Super::OnInteractionStopped(Player);
		
		if(!bDroppedInCauldron)
		{
			DestroyActor();
			IngredientPile.Enable();
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		SetActorRelativeLocation(RelativeOffset);
		SetActorRelativeRotation(RelativeRotation);
	}
#endif
};