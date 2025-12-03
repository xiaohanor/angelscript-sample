class UWindTunnelRotationComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FRotator RotationPerSecond;

	UPROPERTY(EditAnywhere)
	bool bStartActive = true;

	UPROPERTY(EditAnywhere)
	float SpeedConstInterp = 0.5;

	float Speed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bStartActive)
			Speed = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bStartActive)
			Speed = Math::FInterpConstantTo(Speed, 1.0, DeltaSeconds, SpeedConstInterp);
		else
			Speed = Math::FInterpConstantTo(Speed, 0.0, DeltaSeconds, SpeedConstInterp);

		Owner.AddActorLocalRotation(RotationPerSecond * Speed * DeltaSeconds);
	}

	UFUNCTION()
	void ActivateRotation()
	{
		bStartActive = true;
	}
};