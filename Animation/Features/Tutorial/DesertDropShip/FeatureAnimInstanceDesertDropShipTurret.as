UCLASS(Abstract)
class UFeatureAnimInstanceDesertDropShipTurret : UHazeAnimInstanceBase
{	
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimBSValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsShooting;

	AControllableDropShipTurret Turret;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		Turret = Cast<AControllableDropShipTurret>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Turret == nullptr)
			return;

		AimBSValues = Turret.AimBSValues;
		bIsShooting = Turret.bShooting;
	}
}

