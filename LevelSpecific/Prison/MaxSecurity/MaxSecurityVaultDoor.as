UCLASS(Abstract)
class AMaxSecurityVaultDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	bool bLockdownActive = false;

	UFUNCTION(DevFunction)
	void SnapLockdown()
	{
		BP_SnapLockdown();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SnapLockdown() {}

	UFUNCTION(DevFunction)
	void ActivateLockdown()
	{
		if (bLockdownActive)
			return;

		bLockdownActive = true;

		BP_ActivateLockdown();

		UMaxSecurityVaultDoorEffectEventHandler::Trigger_ActivateLockdown(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateLockdown() {}

	UFUNCTION(DevFunction)
	void OpenVault()
	{
		BP_OpenVault();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenVault() {}
}