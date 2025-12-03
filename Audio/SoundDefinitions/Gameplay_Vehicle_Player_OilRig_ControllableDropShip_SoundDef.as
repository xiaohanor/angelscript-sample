
UCLASS(Abstract)
class UGameplay_Vehicle_Player_OilRig_ControllableDropShip_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	AControllableDropShip DropShip;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DropShip.bFlying;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DropShip = Cast<AControllableDropShip>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Player : Game::Players)
		{
			Player.ApplySettings(DamageDeathVoDisabled, this, EHazeSettingsPriority::Override);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto Player : Game::Players)
		{
			Player.ClearSettingsByInstigator(this);
		}
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Dropship Stick Input"))
	FVector2D GetStickInput()
	{
		return DropShip.PilotInput;
	}
}