
UCLASS(Abstract)
class UWorld_Summit_WaterTemple_WaveRaft_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnRaftExploded(FWaveRaftExplosionEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnRaftCollision(FWaveRaftCollisionEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void WhilePaddleSubmerged(FWaveRaftPaddleEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPaddleEnterWater(FWaveRaftPaddleEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void WhileAirborne(FWaveRaftAirborneEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnWaterLanding(FWaveRaftWaterLandingEventParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HazeOwner.IsActorDisabled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HazeOwner.IsActorDisabled())
			return true;

		return false;
	}

}