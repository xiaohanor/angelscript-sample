
UCLASS(Abstract)
class UWorld_Summit_EggPath_Interactable_SummitEggHolder_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	ASummitEggHolder EggHolder;

	UPROPERTY(BlueprintReadOnly)
	int PlacedEggsCount = 0;

	TMap<ASummitEggHolder, AHazePlayerCharacter> EggHolderPlayers;
	private bool bInteractionOwner = false;

	UFUNCTION(BlueprintEvent)
	void OnEggPlaced(AHazePlayerCharacter Player) {};
	UFUNCTION(BlueprintEvent)
	void OnEggRemoved(AHazePlayerCharacter Player) {};

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Fast Version"))
	bool IsFastVersion()
	{
		return EggHolder.bFastAnimation;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		EggHolder = Cast<ASummitEggHolder>(HazeOwner);
		bInteractionOwner = EggHolder.OtherEggHolder == nullptr || !EggHolder.OtherEggHolder.bHasAttachedSoundDef;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!bInteractionOwner)
			return false;

		return !EggHolder.InteractionComp.IsDisabled();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return EggHolder.InteractionComp.IsDisabled();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		EggHolder.InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnPlayerEggPlaced");
		EggHolder.OnEggRemoved.AddUFunction(this, n"OnPlayerEggRemoved");

		if(EggHolder.OtherEggHolder != nullptr)
		{
			EggHolder.OtherEggHolder.InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnPlayerEggPlacedOtherHolder");
			EggHolder.OtherEggHolder.OnEggRemoved.AddUFunction(this, n"OnPlayerEggRemovedOtherHolder");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		EggHolder.InteractionComp.OnInteractionStarted.UnbindObject(this);
		EggHolder.InteractionComp.OnInteractionStopped.UnbindObject(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerEggPlaced(UInteractionComponent InteractionComp, AHazePlayerCharacter Player)
	{		
		++PlacedEggsCount;
		OnEggPlaced(Player);

		EggHolderPlayers.FindOrAdd(EggHolder) = Player;
	}
	UFUNCTION(NotBlueprintCallable)
	void OnPlayerEggPlacedOtherHolder(UInteractionComponent InteractionComp, AHazePlayerCharacter Player)
	{
		++PlacedEggsCount;
		OnEggPlaced(Player);

		EggHolderPlayers.FindOrAdd(EggHolder.OtherEggHolder) = Player;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerEggRemoved()
	{		
		--PlacedEggsCount;
		OnEggRemoved(EggHolderPlayers[EggHolder]);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerEggRemovedOtherHolder()
	{
		--PlacedEggsCount;
		OnEggRemoved(EggHolderPlayers[EggHolder.OtherEggHolder]);
	}
}