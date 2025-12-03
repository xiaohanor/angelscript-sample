struct FMeltdownGlitchShootingPickupPowerupParams
{
	UPROPERTY()
	AMeltdownGlitchShootingPowerup Powerup;
	UPROPERTY()
	AHazePlayerCharacter PickedUpByPlayer;

	FMeltdownGlitchShootingPickupPowerupParams(AMeltdownGlitchShootingPowerup _Powerup, AHazePlayerCharacter Player)
	{
		Powerup = _Powerup;
		PickedUpByPlayer = Player;
	}
}

struct FMeltdownGlitchShootingDelayedSpawnPowerupParams
{
	UPROPERTY()
	AMeltdownGlitchShootingPowerup Powerup;

	FMeltdownGlitchShootingDelayedSpawnPowerupParams(AMeltdownGlitchShootingPowerup _Powerup)
	{
		Powerup = _Powerup;
	}
}


UCLASS(Abstract)
class UMeltdownGlitchShootingPickupEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPowerupDelayedSpawned(FMeltdownGlitchShootingDelayedSpawnPowerupParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPowerupsSpawned()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPowerupCollected(FMeltdownGlitchShootingPickupPowerupParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPowerupReachedGlitch()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPrePowerupReachedGlitch()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAllPowerupsCollected()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPickupStarted()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPickupFinished()
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGlitchActive()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAllReachedTarget()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPreAllReachedTarget()
	{
	}
};