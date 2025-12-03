class UControllableDropShipCrosshair : UCrosshairWithAutoAimWidget
{
	UPROPERTY(BlueprintReadOnly)
	bool bIsShooting = false;

	void Hit()
	{
		BP_Hit();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Hit() {}
}