event void FOnSolarFlareTriggerShieldCollected();

class ASolarFlareCollectTriggerShield : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareTriggerShieldCollected OnSolarFlareTriggerShieldCollected;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UInteractionComponent InteractComp;
	default InteractComp.bIsImmediateTrigger = true;

	UPROPERTY(EditDefaultsOnly)
	TPerPlayer<UAnimSequence> PickUpAnim;

	UPROPERTY(EditAnywhere)
	ASolarFlareTriggerShieldAttachContraption Contraption; 

	UPROPERTY()
	UHazeCapabilitySheet CapabilitySheet;

	AHazePlayerCharacter PickUpPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		InteractionComponent.Disable(this);
		USolarFlareTriggerShieldComponent UserComp =  USolarFlareTriggerShieldComponent::Get(Player);
		UserComp.SetShieldAvailable(Player);
		UserComp.Contraption = Contraption;
		MeshComp.SetHiddenInGame(true);
		Player.StartCapabilitySheet(CapabilitySheet, this);
		OnSolarFlareTriggerShieldCollected.Broadcast();
		FHazePlaySlotAnimationParams Params;
		Params.Animation = PickUpAnim[Player];
		FHazeAnimationDelegate BlendOut;
		BlendOut.BindUFunction(this, n"FinishedAnim");

		PickUpPlayer = Player;

		Timer::SetTimer(this, n"DelayAttach", 0.47);

		PickUpPlayer.PlaySlotAnimation(FHazeAnimationDelegate(), BlendOut, PickUpAnim[Player], false);
		PickUpPlayer.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION()
	void DelayAttach()
	{
		Contraption.AttachToComponent(PickUpPlayer.Mesh, n"RightAttach");
	}

	UFUNCTION()
	private void FinishedAnim()
	{
		Contraption.AttachToComponent(PickUpPlayer.Mesh, n"RightForeArm");
		PickUpPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION()
	void SetTriggerShieldActiveOnPlayer(AHazePlayerCharacter Player)
	{
		InteractComp.Disable(this);
		USolarFlareTriggerShieldComponent UserComp =  USolarFlareTriggerShieldComponent::Get(Player);
		UserComp.SetShieldAvailable(Player);
		UserComp.Contraption = Contraption;
		MeshComp.SetHiddenInGame(true);
		Player.StartCapabilitySheet(CapabilitySheet, this);
	}
};