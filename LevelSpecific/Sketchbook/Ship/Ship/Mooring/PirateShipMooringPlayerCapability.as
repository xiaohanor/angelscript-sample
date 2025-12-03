struct FPirateShipMooringPlayerOnDeactivateParams
{
	bool bCompleted = false;
}

class UPirateShipMooringPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UPirateShipMooringPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UPirateShipMooringPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!PlayerComp.bIsMooring)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPirateShipMooringPlayerOnDeactivateParams& Params) const
	{
		if(!PlayerComp.bIsMooring)
			return true;

		if(Player.GetButtonMashProgress(this) > 1.0 - KINDA_SMALL_NUMBER)
		{
			Params.bCompleted = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FButtonMashSettings MashSettings;
		MashSettings.Difficulty = EButtonMashDifficulty::Easy;
		MashSettings.Duration = 1.0;
		Player.StartButtonMash(MashSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPirateShipMooringPlayerOnDeactivateParams Params)
	{
		Player.StopButtonMash(this);

		if(Params.bCompleted)
		{
			PlayerComp.Mooring.UnMoor();
			PlayerComp.Mooring.InteractionComp.KickAnyPlayerOutOfInteraction();
			PlayerComp.bIsMooring = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Player.IsPlayerDead() || Player.IsPlayerRespawning())
			PlayerComp.Mooring.InteractionComp.KickAnyPlayerOutOfInteraction();
	}
};