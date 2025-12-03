UCLASS(Abstract)
class UFoliage_SoundDef : USoundDefBase
{
	UPROPERTY()
	UPlayerFoliageAudioComponent FoliageComponent;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		if (PlayerOwner != nullptr)
			FoliageComponent = UPlayerFoliageAudioComponent::GetOrCreate(HazeOwner);
	}

	// Default
	AHazePlayerCharacter GetFoliagePlayer() const
	{
		if(PlayerOwner != nullptr)
			return PlayerOwner;

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool GetScriptImplementedTriggerEffectEvents(
												 UHazeEffectEventHandlerComponent& EventHandlerComponent,
												 TMap<FName,TSubclassOf<UHazeEffectEventHandler>>& EventClassAndFunctionNames) const
	{
		auto Player = GetFoliagePlayer();
		if (Player == nullptr)
		{
			Warning(f"Failed to find Player for Foilage TriggerEffectEvents on {GetName()} with owner '{HazeOwner}'");
			return false;
		}

		auto PlayerEffectHandlerComponent = UHazeEffectEventHandlerComponent::Get(Player);
		if (PlayerEffectHandlerComponent == nullptr)
		{
			Warning(f"Failed to find UHazeEffectEventHandlerComponent on {Player} for {GetName()} with owner '{HazeOwner}'");
			return false;
		}

		EventHandlerComponent = PlayerEffectHandlerComponent;
		EventClassAndFunctionNames.Add(n"FoliageOverlapEvent", UFoliageDetectionEventHandler);

		return true;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FoliageOverlapEvent(FFoliageDetectionData Data)
	{
	}
}