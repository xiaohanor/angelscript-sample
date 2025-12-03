class UAnimInstanceSkylineBossTank : UHazeAnimInstanceBase
{
	ASkylineBossTank SkylineBossTank;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator TurretWorldRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator CrusherWorldRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CrusherSpin = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CrusherArmRotation = 0.0;

	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		SkylineBossTank = Cast<ASkylineBossTank>(HazeOwningActor);
		if (SkylineBossTank == nullptr)
			return;
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SkylineBossTank == nullptr)
			return;

		TurretWorldRotation = SkylineBossTank.TurretComp.WorldRotation;
		CrusherWorldRotation = SkylineBossTank.CrusherComp.WorldRotation;
		CrusherSpin = SkylineBossTank.CrusherComp.Spin;
		CrusherArmRotation = SkylineBossTank.CrusherComp.ArmRotation;
	}
}