class UPirateShipHelmPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;

	UPirateShipHelmPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UPirateShipHelmPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!PlayerComp.bIsMounted)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!PlayerComp.bIsMounted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(Pirate::Helm::bUseStickSpin)
		{
			FStickSpinSettings Settings;
			Settings.bAllowPlayerCancel = false;
			Settings.bAllowSpinClockwise = true;
			Settings.bAllowSpinCounterClockwise = true;

			Player.StartStickSpin(Settings, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Pirate::Helm::bUseStickSpin)
		{
			Player.StopStickSpin(this);
		}

		PlayerComp.Helm.SteerInput = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Pirate::Helm::bUseStickSpin)
		{
			FStickSpinState State = Player.GetStickSpinState(this);
			PlayerComp.Helm.SteerInput = State.SpinVelocity;
		}
		else
		{
			float SteerInput = GetAttributeFloat(AttributeNames::MoveRight);
			if(Math::Abs(SteerInput) < 0.2)
			{
				PlayerComp.Helm.SteerInput = 0;
			}
			else
			{
				PlayerComp.Helm.SteerInput = Math::Sign(GetAttributeFloat(AttributeNames::MoveRight));
			}
		}

		if(Player.IsPlayerDead() || Player.IsPlayerRespawning())
			PlayerComp.Helm.InteractionComp.KickAnyPlayerOutOfInteraction();
	}
};