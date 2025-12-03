
event void FOnDoublePullableCompleted();

/**
 * Standard implementation of a pullable actor that one or both players can move along a spline.
 */
class ADoublePullable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UPullableComponent PullableComponent;
	default PullableComponent.bRequireBothPlayers = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent ZoeInteraction;
	default ZoeInteraction.RelativeLocation = FVector(0.0, -100.0, 0.0);
	default ZoeInteraction.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default ZoeInteraction.bShowForOtherPlayer = true;
	default ZoeInteraction.MovementSettings = FMoveToParams::SmoothTeleport();
	default ZoeInteraction.InteractionSheet = Pullable::PullSheet;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent MioInteraction;
	default MioInteraction.RelativeLocation = FVector(0.0, 100.0, 0.0);
	default MioInteraction.UsableByPlayers = EHazeSelectPlayer::Mio;
	default MioInteraction.bShowForOtherPlayer = true;
	default MioInteraction.MovementSettings = FMoveToParams::SmoothTeleport();
	default MioInteraction.InteractionSheet = Pullable::PullSheet;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"PullablePullBackCapability");

	// Called when the pullable reaches the end of the spline and bCompleteAtEndOfSpline is on
	UPROPERTY()
	FOnDoublePullableCompleted OnPullableCompleted;

	// Called when a player starts pulling the pullable
	UPROPERTY()
	FOnPullableEvent OnStartedPulling;

	// Called when a player stops pulling the pullable
	UPROPERTY()
	FOnPullableEvent OnStoppedPulling;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PullableComponent.OnPullableCompleted.AddUFunction(this, n"TriggerCompletePullable");
		PullableComponent.OnStartedPulling.AddUFunction(this, n"TriggerStartedPulling");
		PullableComponent.OnStoppedPulling.AddUFunction(this, n"TriggerStoppedPulling");
	}

	UFUNCTION()
	private void TriggerCompletePullable(AHazePlayerCharacter Player)
	{
		OnPullableCompleted.Broadcast();
	}

	UFUNCTION()
	private void TriggerStartedPulling(AHazePlayerCharacter Player)
	{
		OnStartedPulling.Broadcast(Player);
	}

	UFUNCTION()
	private void TriggerStoppedPulling(AHazePlayerCharacter Player)
	{
		OnStoppedPulling.Broadcast(Player);
	}


	UFUNCTION(BlueprintCallable, Category = "Pullable")
	void DisablePullable(FInstigator Instigator)
	{
		ZoeInteraction.Disable(Instigator);
		ZoeInteraction.KickAnyPlayerOutOfInteraction();
		
		MioInteraction.Disable(Instigator);
		MioInteraction.KickAnyPlayerOutOfInteraction();
	}

	UFUNCTION(BlueprintCallable, Category = "Pullable")
	void EnablePullable(FInstigator Instigator)
	{
		ZoeInteraction.Enable(Instigator);
		MioInteraction.Enable(Instigator);
	}

	/**
	 * Get the current distance on the spline that we've pulled.
	 * 
	 * WARNING: Network sync of this value is unreliable, so if you trigger
	 * gameplay based on this, make sure to sync it yourself!
	 */
	UFUNCTION(BlueprintPure)
	float GetPulledDistanceOnSpline() const
	{
		return PullableComponent.GetPulledDistanceOnSpline();
	}
};