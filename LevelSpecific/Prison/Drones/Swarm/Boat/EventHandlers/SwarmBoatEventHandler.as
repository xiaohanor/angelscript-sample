USTRUCT()
struct FSwarmBoatVFX
{
	UPROPERTY()
	UNiagaraSystem EnterSplash;

	UPROPERTY()
	UNiagaraSystem PropellerSplash;
}

struct FSwarmBoatWallImpactEventParams
{
	UPROPERTY()
	float Strength = 0.0;
}

class USwarmBoatEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	FSwarmBoatVFX VFX;

	AHazePlayerCharacter Player;
	UDynamicWaterEffectDecalComponent WaterRippleComponent;

	UPlayerMovementComponent MovementComponent;
	UPlayerSwarmBoatComponent SwarmBoatComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		WaterRippleComponent = UDynamicWaterEffectDecalComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		SwarmBoatComponent = UPlayerSwarmBoatComponent::Get(Player);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaterEnter(FVector Location)
	{
		WaterRippleComponent.Strength = 4.0;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaterExit(FVector Location)
	{
		WaterRippleComponent.Strength = 1.0;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EnterRapids() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ExitRapids() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWallImpact(FSwarmBoatWallImpactEventParams Params)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMagnetDroneEnter(FSwarmBoatWallImpactEventParams Params)
	{
		WaterRippleComponent.Strength = 10.0;
		Timer::SetTimer(this, n"MagnetDroneEnterWaterReset", 0.1);
	}

	UFUNCTION()
	void MagnetDroneEnterWaterReset()
	{
		WaterRippleComponent.Strength = 1.0;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMagnetDroneExit()
	{
		WaterRippleComponent.Strength = 10.0;
		Timer::SetTimer(this, n"MagnetDroneEnterWaterReset", 0.1);
	}

	// How fast propeller is spinning (0 to 1)
	UFUNCTION(BlueprintPure)
	float GetPropellerSpeedFraction() const
	{
		return SwarmBoatComponent.AcceleratedInput.Value.Size();
	}

	UFUNCTION(BlueprintPure)
	bool IsPropellerSpinning() const
	{
		return !Math::IsNearlyZero(GetPropellerSpeedFraction(), 0.1);
	}
}