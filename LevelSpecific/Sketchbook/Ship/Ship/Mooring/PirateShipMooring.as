UCLASS(Abstract)
class APirateShipMooring : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCableComponent CableComp;

	UPROPERTY(DefaultComponent)
	UThreeShotInteractionComponent InteractionComp;

	private bool bIsMoored = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		auto PlayerComp = UPirateShipMooringPlayerComponent::Get(Player);
		PlayerComp.Mooring = this;
		PlayerComp.bIsMooring = true;
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		auto PlayerComp = UPirateShipMooringPlayerComponent::Get(Player);
		PlayerComp.bIsMooring = false;
	}

	void UnMoor()
	{
		if(!bIsMoored)
			return;
		
		bIsMoored = false;
		CableComp.SetHiddenInGame(true, true);
		InteractionComp.Disable(this);
	}

	bool IsMoored() const
	{
		return bIsMoored;
	}
};