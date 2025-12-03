class ABattlefieldHoverboardBigAirPlayerVolume : APlayerTrigger
{
	default SetBrushColor(FLinearColor(0.80, 0.02, 0.02));
	default BrushComponent.LineThickness = 6.0;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEffectShareSet EffectShareSet;

	UPROPERTY(EditInstanceOnly, Meta = (ShowOnlyInnerProperties))
	FBattlefieldHoverboardBigAirInstigatorData BigAirInstigatorData;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();		
		OnPlayerEnter.AddUFunction(this, n"TriggerPlayerEnter");
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerPlayerEnter(AHazePlayerCharacter Player)
	{
		if(EffectShareSet == nullptr)
			return;

		auto BigAirPlayerComponent = UBattlefieldHoverboardBigAirPlayerComponent::Get(Player);
		if(BigAirPlayerComponent == nullptr)
			return;

		BigAirInstigatorData.EffectShareset = EffectShareSet;
		BigAirPlayerComponent.SetBigAirData(BigAirInstigatorData);		
	}
}