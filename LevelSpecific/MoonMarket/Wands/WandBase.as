struct FWandPlayerData
{
	AHazePlayerCharacter Player;
	AWandBase Wand;

	UPROPERTY()
	UAnimSequence CastAnimation;

	float CastTime = 0.47;

	bool bIsCasting = false;

	UPROPERTY()
	EMoonMarketWandType Type;

	UPROPERTY()
	TSubclassOf<UAutoAimTargetComponent> AutoAimClass;

	FWandPlayerData(AHazePlayerCharacter NewPlayer, AWandBase NewWand, EMoonMarketWandType NewType)
	{
		Player = NewPlayer;
		Wand = NewWand;
		Type = NewType;
	}
}

struct FSpellHitData
{
	UPROPERTY(BlueprintReadOnly)
	AActor HitActor;

	UPROPERTY(BlueprintReadOnly)
	FVector HitLocation;

	FSpellHitData(AActor InHitActor, FVector InHitLocation)
	{
		HitActor = InHitActor;
		HitLocation = InHitLocation;
	}
}

class AWandBase : AMoonMarketHoldableActor
{
	default InteractableTag = EMoonMarketInteractableTag::Wand;
	//default CompatibleInteractions.Add(EMoonMarketInteractableTag::Balloon);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMoonMarketBobbingComponent BobbingComp;
	default BobbingComp.CircleRadius = 2.0;
	default BobbingComp.MinBobSpeed = 1.5;
	default BobbingComp.MaxBobSpeed = 2.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ShootOrigin;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UPointLightComponent LightComp;

	FMoveToParams MoveToParams;
	default MoveToParams.Type = EMoveToType::NoMovement;
	default InteractComp.MovementSettings = MoveToParams;
	default InteractComp.bIsImmediateTrigger = true;
	default InteractComp.bShowCancelPrompt = false;
	
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	FWandPlayerData PlayerData;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	bool bHoldWhenCasting;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
	}

	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
		PlayerData.Player = Player;
		Player.EnableStrafe(this);
		PlayerData.Wand = this;
		AttachToActor(Player, n"RightHand", EAttachmentRule::SnapToTarget);
		UWandPlayerComponent::Get(Player).SetWand(PlayerData);
		BobbingComp.SetBobbingState(false);
	}

	void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		UWandPlayerComponent::Get(PlayerData.Player).ClearWand();
		InteractingPlayer.DisableStrafe(this);
		Super::OnInteractionStopped(InteractingPlayer);
		BobbingComp.SetBobbingState(true);
	}

	void StartCasting() 
	{
	}

	void FinishCasting(FSpellHitData Data)
	{
	}
};