class ATundra_IcePalace_FairyPrecisionModeEnabler : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(EditInstanceOnly)
	ATundraFairyMoveSpline FairySpline;

	UPROPERTY(EditInstanceOnly)
	UTundraPlayerFairySettings FairyPrecisionModeSettings;
	
	UPlayerMovementComponent MoveComp;
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FairySpline.OnFairyEnterEvent.AddUFunction(this, n"OnFairyEnter");
	}

	UFUNCTION()
	private void OnFairyEnter()
	{
		MoveComp = UPlayerMovementComponent::Get(Game::Zoe);
		Game::Zoe.ApplySettings(FairyPrecisionModeSettings, this, EHazeSettingsPriority::Override);
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(MoveComp.IsOnAnyGround())
		{
			Game::Zoe.ClearSettingsByInstigator(this);
			SetActorTickEnabled(false);
		}
	}
};