event void FBothPlayerTriggerEvent();

/**
 * Trigger volume that tracks specific actors or actors of specific classes.
 */ 
UCLASS(HideCategories = "Collision Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass, Meta = (HighlightPlacement))
class ABothPlayerTrigger : AVolume
{
	// TODO: Do we need a handshake again like we had in Nuts?

    default Shape::SetVolumeBrushColor(this, FLinearColor(0.5, 0.2, 1.0, 1.0));
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	// Whether the trigger should ignore networking and only trigger locally
    UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Both Player Trigger", AdvancedDisplay)
	bool bTriggerLocally = false;

    UPROPERTY(Category = "Both Player Trigger")
    FBothPlayerTriggerEvent OnBothPlayersInside;

    UPROPERTY(Category = "Both Player Trigger")
    FBothPlayerTriggerEvent OnStopBothPlayersInside;

	private TArray<FInstigator> DisableInstigators;
	private TPerPlayer<bool> PlayersInsideTrigger;
	private bool bBothPlayersInside = false;

    UFUNCTION(Category = "Both Player Trigger")
    void EnableBothPlayerTrigger(FInstigator Instigator)
    {
		DisableInstigators.Remove(Instigator);
        UpdateAlreadyInsidePlayers();
    }

    UFUNCTION(Category = "Both Player Trigger")
    void DisableBothPlayerTrigger(FInstigator Instigator)
    {
		DisableInstigators.AddUnique(Instigator);
        UpdateAlreadyInsidePlayers();
    }

	UFUNCTION(BlueprintOverride)
	private void BeginPlay()
	{
	}

	// Manually update which players are inside, we may have missed overlap events due to disable or streaming
	private void UpdateAlreadyInsidePlayers()
	{
		// Only track on the control side of the trigger
		if (!HasControl() && !bTriggerLocally)
			return;

		for (auto Player : Game::Players)
		{
			bool bIsInside = false;
			if (DisableInstigators.Num() == 0)
			{
				if (Player.CapsuleComponent.TraceOverlappingComponent(BrushComponent))
					bIsInside = true;
			}

			PlayersInsideTrigger[Player] = bIsInside;
		}

		if (PlayersInsideTrigger[0] && PlayersInsideTrigger[1])
		{
			if (!bBothPlayersInside)
			{
				bBothPlayersInside = true;
				if (bTriggerLocally)
					OnBothPlayersInside.Broadcast();
				else
					CrumbBothPlayersInside();
			}
		}
		else
		{
			if (bBothPlayersInside)
			{
				bBothPlayersInside = false;
				if (bTriggerLocally)
					OnStopBothPlayersInside.Broadcast();
				else
					CrumbStopBothPlayersInside();
			}
		}
	}

    UFUNCTION(BlueprintOverride)
    private void ActorBeginOverlap(AActor OtherActor)
    {
		// Only track on the control side of the trigger
		if (!HasControl() && !bTriggerLocally)
			return;

        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
        if (DisableInstigators.Num() != 0)
            return;

		PlayersInsideTrigger[Player] = true;
		if (!bBothPlayersInside && PlayersInsideTrigger[0] && PlayersInsideTrigger[1])
		{
			bBothPlayersInside = true;
			if (bTriggerLocally)
				OnBothPlayersInside.Broadcast();
			else
				CrumbBothPlayersInside();
		}
	}

    UFUNCTION(BlueprintOverride)
    private void ActorEndOverlap(AActor OtherActor)
    {
		// Only track on the control side of the trigger
		if (!HasControl() && !bTriggerLocally)
			return;

        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
        if (DisableInstigators.Num() != 0)
            return;

		PlayersInsideTrigger[Player] = false;
		if (bBothPlayersInside && !(PlayersInsideTrigger[0] && PlayersInsideTrigger[1]))
		{
			bBothPlayersInside = false;
			if (bTriggerLocally)
				OnStopBothPlayersInside.Broadcast();
			else
				CrumbStopBothPlayersInside();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbBothPlayersInside()
	{
		OnBothPlayersInside.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStopBothPlayersInside()
	{
		OnStopBothPlayersInside.Broadcast();
	}
}