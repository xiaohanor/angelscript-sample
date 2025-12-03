class UPlayerTailAdultDragonComponent : UPlayerAdultDragonComponent
{
	UPROPERTY()
	TSubclassOf<UCrosshairWidget> SpikeShotCrosshair;

	UPROPERTY()
	TSubclassOf<AAdultDragonSpikeProjectile> SpikeProjectileClass;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SmashStartCameraShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SmashImpactCameraShake;

	UPROPERTY()
	TSubclassOf<APlayerAdultDragonAimWidget> AimWidgetClass;

	UPROPERTY()
	TSubclassOf<UTargetableWidget> SmashTargetableWidget;

	FVector AimDirection;
	FVector AimOrigin;

	UFUNCTION()
	void ToggleCameraControl()
	{
		bRightStickCameraIsOn = !bRightStickCameraIsOn;
		Print(f"Right Stick Camera Control: {bRightStickCameraIsOn}");
	}
};
