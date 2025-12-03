struct FPirateShipSailPlayerOnDeactivateParams
{
	bool bCompleted = false;
}


class UPirateShipSailPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UPirateShipSailPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UPirateShipSailPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!PlayerComp.bIsUnrolling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPirateShipSailPlayerOnDeactivateParams& Params) const
	{
		if(!PlayerComp.bIsUnrolling)
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
	void OnDeactivated(FPirateShipSailPlayerOnDeactivateParams Params)
	{
		Player.StopButtonMash(this);

		if(Params.bCompleted)
		{
			PlayerComp.Sail.FinishUntieInteraction(PlayerComp.InteractionComp);
			PlayerComp.InteractionComp.KickAnyPlayerOutOfInteraction();
			PlayerComp.bIsUnrolling = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Player.IsPlayerDead() || Player.IsPlayerRespawning())
			PlayerComp.InteractionComp.KickAnyPlayerOutOfInteraction();
	}
};