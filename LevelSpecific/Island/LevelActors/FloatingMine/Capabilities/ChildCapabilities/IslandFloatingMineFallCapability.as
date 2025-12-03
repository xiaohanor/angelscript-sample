class UIslandFloatingMineFallCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AIslandFloatingMine Mine;
	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	bool bHasBeenOverloaded = false;
	bool bHasHitSomething = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mine = Cast<AIslandFloatingMine>(Owner);
		MoveComp = UHazeMovementComponent::Get(Mine);
		Movement = MoveComp.SetupSimpleMovementData();

		if(Mine.BluePanel != nullptr)
			Mine.BluePanel.OnCompleted.AddUFunction(this, n"OnBluePanelCompleted");
		if(Mine.RedPanel != nullptr)
			Mine.RedPanel.OnCompleted.AddUFunction(this, n"OnRedPanelCompleted");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBluePanelCompleted()
	{
		if(Mine.bIsDoubleInteract)
		{
			if(Mine.RedPanel.IsOvercharged())
				bHasBeenOverloaded = true;
		}
		else
		{
			bHasBeenOverloaded = true;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRedPanelCompleted()
	{
		if(Mine.bIsDoubleInteract)
		{
			if(Mine.BluePanel.IsOvercharged())
				bHasBeenOverloaded = true;
		}
		else
		{
			bHasBeenOverloaded = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!bHasBeenOverloaded)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration >= Mine.FallDuration)
			return true;

		if(bHasHitSomething)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Mine.bIsFalling = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Mine.bIsFalling = false;
		Mine.Explode();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.AddOwnerVelocity();
				Movement.AddGravityAcceleration();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
		}
	}
}