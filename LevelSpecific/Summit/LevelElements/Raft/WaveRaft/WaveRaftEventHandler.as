struct FWaveRaftPaddleEventParams
{
	UPROPERTY()
	FVector PaddleLocation;
}

struct FWaveRaftCollisionEventParams
{
	UPROPERTY()
	FVector WaveRaftLocation;

	UPROPERTY()
	FVector ImpactLocation;
}

struct FWaveRaftExplosionEventParams
{
	UPROPERTY()
	FVector WaveRaftLocation;
}

struct FWaveRaftAirborneEventParams
{
	UPROPERTY()
	FVector WaveRaftLocation;
}

struct FWaveRaftWaterLandingEventParams
{
	UPROPERTY()
	FVector WaveRaftLocation;
}

UCLASS(Abstract)
class UWaveRaftEventHandler : UHazeEffectEventHandler
{
	UHazeOffsetComponent FrontLocation;
	UHazeOffsetComponent BackLocation;

	UPROPERTY()
	AWaveRaft Raft;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Raft = Cast<AWaveRaft>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPaddleEnterWater(FWaveRaftPaddleEventParams Params)
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhilePaddleSubmerged(FWaveRaftPaddleEventParams Params)
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRaftCollision(FWaveRaftCollisionEventParams Params)
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRaftCollisionRaw(FWaveRaftCollisionEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRaftExploded(FWaveRaftExplosionEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaterLanding(FWaveRaftWaterLandingEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhileAirborne(FWaveRaftAirborneEventParams Params)
	{
	}

	UFUNCTION(BlueprintPure)
	FVector GetRaftVelocity() const
	{
		return Raft.AccWaveRaftRotation.Value.ForwardVector * Raft.AccCurrentRaftSpeed.Value;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentRaftSpeed()
	{
		float ForwardSpeed = Raft.ActorVelocity.DotProduct(Raft.ActorForwardVector);
		return ForwardSpeed;
	}

	UFUNCTION(BlueprintPure)
	FVector GetRaftFrontLocation()
	{
		return (Raft.FLWaterSampleComp.WorldLocation + Raft.FRWaterSampleComp.WorldLocation) * 0.5;
	}

	UFUNCTION(BlueprintPure)
	FVector GetRaftBackLocation()
	{
		return (Raft.BLWaterSampleComp.WorldLocation + Raft.BRWaterSampleComp.WorldLocation) * 0.5;
	}

	UFUNCTION(BlueprintPure)
	FRotator GetRaftRotation()
	{
		return Raft.AccWaveRaftRotation.Value;
	}
}