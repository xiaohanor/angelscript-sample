
UCLASS(Abstract)
class UStormdrainBankVaultDoorEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	AIslandStormdrainBankVaultDoor IslandStormdrainBankVaultDoor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		IslandStormdrainBankVaultDoor = Cast<AIslandStormdrainBankVaultDoor>(Owner);

		// hmm was this EventHandler placed on something else then the door?
		check(IslandStormdrainBankVaultDoor != nullptr);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorActivate() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorDeactivate() {}

	/** when the beam locks */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BeamLocked(FStormdrainBankVaultDoorEventData BeamData) {}

	/**
	 * This is for whenever a beam opens.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBeamUnlocked(FStormdrainBankVaultDoorEventData BeamData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalBeamUnlocked(FStormdrainBankVaultDoorEventData BeamData) {}

	/**
	 * When the doors  gets hit by an impact for the first time and start opening 
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenDoorStarted() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenDoorUpdate() { }

	/**
	 * Whenever the door stops opening, but hasn't necessarily finished opening
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenDoorStopped() { }

	/**
	 * When the final beam has been unlocked and the door opens up completely
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenDoorFinished() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRotateCenterUpdate() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRotateCenterFinished() { }
};

struct FStormdrainBankVaultDoorEventData
{
	UPROPERTY()
	AIslandStormdrainBankVaultDoor_LockBeam Beam;

	FStormdrainBankVaultDoorEventData(AIslandStormdrainBankVaultDoor_LockBeam InBeam)
	{
		Beam = InBeam;
	}
}