class UControllableDropShipPassengerPlayerComponent : UControllableDropShipPlayerComponent
{
	UPROPERTY()
	FAimingSettings AimingSettings;

	UPROPERTY()
	UPlayerAimingSettings PlayerAimingSettings;

	FVector2D AimBSValues = FVector2D::ZeroVector;
	bool bShooting = false;
}