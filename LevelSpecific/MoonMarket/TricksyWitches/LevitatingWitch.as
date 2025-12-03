class ALevitatingWitch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FXTrail;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USwingPointComponent SwingPointComp;
	default SwingPointComp.bTestCollision = false;
	default SwingPointComp.TetherLength = 500.0;
	default SwingPointComp.AdditionalVisibleRange = 1200.0;
	default SwingPointComp.ActivationRange = 1200.0;
	default SwingPointComp.HeightActivationSettings = EHeightActivationSettings::ActivateOnlyBelow;
	default SwingPointComp.MinimumRange = 500.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bUseSwing = false;

	bool bWasEnabled = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bUseSwing)
			SwingPointComp.Disable(this);
		else
		{
			SwingPointComp.OnPlayerAttachedEvent.AddUFunction(this, n"OnPlayerAttached");
			SwingPointComp.OnPlayerDetachedEvent.AddUFunction(this, n"OnPlayerDetached");
		}
	}

	UFUNCTION()
	private void OnPlayerAttached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		if(Player.HasControl())
			UMoonMarketPlayerInteractionComponent::Get(Player).CrumbStopAllInteractions();
		
		UMoonMarketFlyingWitchEventHandler::Trigger_OnPlayerStartSwinging(this, FMoonMarketInteractingPlayerEventParams(Player));
	}

	UFUNCTION()
	private void OnPlayerDetached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		UMoonMarketFlyingWitchEventHandler::Trigger_OnPlayerStopSwinging(this, FMoonMarketInteractingPlayerEventParams(Player));
	}
};