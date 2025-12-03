
UCLASS(Abstract)
class AScifiGasZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Trigger;
	default Trigger.SetBoxExtent(FVector(400.0), false);
	default Trigger.ShapeColor = FColor::Green;
	default Trigger.CollisionProfileName = n"TriggerOnlyPlayer";
	default Trigger.LineThickness = 2.0;

	UPROPERTY(DefaultComponent)	
	UHazeRequestCapabilityOnPlayerComponent RequestComponent;

	UPROPERTY(Category = "Player Trigger")
    FPlayerTriggerEvent OnPlayerEnter;

    UPROPERTY(Category = "Player Trigger")
    FPlayerTriggerEvent OnPlayerExit;

	// Only used if set, else the default settings on the player component is used
	UPROPERTY(EditInstanceOnly)
	UScifiGasZoneSettings CustomSettings;

	// UPROPERTY()
	// UHazeCapabilitySheet PlayerSheet;

	// Should we start with the zone active, else call 'ActivateGas' to enable it
	UPROPERTY(EditInstanceOnly)
	bool bStartWithGasActive = true;

	/** How long it will take to start making damage after activated 
	 * Only used if > 0; else its insta activated 
	*/
	UPROPERTY(EditInstanceOnly)
	float TimeToFullEffect = 1.65;

	private TPerPlayer<bool> bPlayerIsInside;
	private float TimeToReach = 0;
	private float InternalTime = 0;
	private int GasFadeDirection = 0;
	private float InternalGasAlpha = 0;
	private bool bGasHasBeenActivatedInternal = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"OnZoneEnter");
		Trigger.OnComponentEndOverlap.AddUFunction(this, n"OnZoneExit");

		if(bStartWithGasActive)
		{
			ActivateGas();
		}
	}

	UFUNCTION(NotBlueprintCallable)
    private void OnZoneEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
		
		SetPlayerInside(Player, true);
	}

    UFUNCTION(NotBlueprintCallable)
    private void OnZoneExit(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;

		SetPlayerInside(Player, false);
	}

	// Called when the player enters the zone
	UFUNCTION(BlueprintEvent)
	protected void OnPlayerEnterZone(AHazePlayerCharacter Player)
	{
		
	}

	// Called when the player exit the zone
	UFUNCTION(BlueprintEvent)
	protected void OnPlayerExitZone(AHazePlayerCharacter Player)
	{
		
	}

	// Called when the zone is turned on
	UFUNCTION(BlueprintEvent)
	protected void OnZoneActivated()
	{
		
	}

	// Called when the zone is turned off
	UFUNCTION(BlueprintEvent)
	protected void OnZoneDeactivated()
	{
		
	}

	private void UpdateAlreadyInsidePlayers()
	{
		for (auto Player : Game::Players)
		{
			if (Player.CapsuleComponent.TraceOverlappingComponent(Trigger))
			{
				SetPlayerInside(Player, true);
			}
		}
	}

	UFUNCTION()
	void ActivateGas()
	{
		if(bGasHasBeenActivatedInternal)
			return;

		if(TimeToFullEffect <= 0)
		{
			InternalGasAlpha = 1.0;
			GasFadeDirection = 0;
			TimeToReach = 0;
			InternalTime = 0;
		}
		else
		{
			TimeToReach = TimeToFullEffect;
			InternalTime = 0;
			GasFadeDirection = 1;
		}

		bGasHasBeenActivatedInternal = true;
		OnZoneActivated();
	}

	UFUNCTION()
	void DeactivateGas(float GasFadeOutTime = 0)
	{
		if(!bGasHasBeenActivatedInternal)
			return;

		if(GasFadeOutTime <= 0)
		{
			InternalGasAlpha = 0.0;
			GasFadeDirection = 0;
			TimeToReach = 0;
			InternalTime = 0;
			OnZoneDeactivated();
		}
		else
		{
			TimeToReach = GasFadeOutTime;
			InternalTime = 0;
			GasFadeDirection = -1;
		}	

		bGasHasBeenActivatedInternal = false;		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Fade out
		if(GasFadeDirection < 0)
		{
			InternalTime = Math::Min(InternalTime + DeltaSeconds, TimeToReach);
			InternalGasAlpha = InternalTime / TimeToReach;
			if(InternalGasAlpha <= KINDA_SMALL_NUMBER)
			{	
				InternalGasAlpha = 0.0;
				GasFadeDirection = 0;
				TimeToReach = 0;
				InternalTime = 0;
				OnZoneDeactivated();
			}
		}
		// Fade in
		else if(GasFadeDirection > 0)
		{
			InternalTime = Math::Min(InternalTime + DeltaSeconds, TimeToReach);
			InternalGasAlpha = InternalTime / TimeToReach;
			if(InternalGasAlpha >= 1.0 - KINDA_SMALL_NUMBER)
			{	
				InternalGasAlpha = 1.0;
				GasFadeDirection = 0;
				TimeToReach = 0;
				InternalTime = 0;
				// Always called the activated event WHEN we call activated
			}
		}
	}

	private void SetPlayerInside(AHazePlayerCharacter Player, bool bIsInside)
	{
		if(bPlayerIsInside[Player] == bIsInside)
			return;

		bPlayerIsInside[Player] = bIsInside;
	
		if(bIsInside)
		{
			OnPlayerEnterZone(Player);
			OnPlayerEnter.Broadcast(Player);
			UScifiPlayerGasZoneComponent::Get(Player).GasZones.Add(this);
		}
		else
		{
			OnPlayerExitZone(Player);
			OnPlayerExit.Broadcast(Player);
			UScifiPlayerGasZoneComponent::Get(Player).GasZones.RemoveSingleSwap(this);
		}
	}

	bool GasIsActive() const
	{
		if(GasFadeDirection < 0) // We are turning off the gas
			return InternalGasAlpha < KINDA_SMALL_NUMBER;
		else
			return InternalGasAlpha > 1.0 - KINDA_SMALL_NUMBER;
	}

	float GetGasAlpha() const
	{
		return InternalGasAlpha;
	}


}