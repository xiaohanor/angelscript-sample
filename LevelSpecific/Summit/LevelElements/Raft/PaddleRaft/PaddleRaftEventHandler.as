struct FPaddleOarEventParams
{
	UPROPERTY()
	FVector OarWaterEnterLocation;
}

struct FPaddleRaftCollisionEventParams
{
	UPROPERTY()
	FVector PaddleRaftLocation;

	UPROPERTY()
	FVector ImpactLocation;
}

UCLASS(Abstract)
class UPaddleRaftEventHandler : UHazeEffectEventHandler
{
	UHazeOffsetComponent FrontLocation;
	UHazeOffsetComponent BackLocation;

	UPROPERTY()
	APaddleRaft Raft;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Raft = Cast<APaddleRaft>(Owner);
		check(Raft != nullptr);

		FrontLocation = Raft.RaftFront;
		BackLocation = Raft.RaftBack;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOarEnterWater(FPaddleOarEventParams Params)
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhileOarSubmerged(FPaddleOarEventParams Params)
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRaftCollision(FPaddleRaftCollisionEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRaftCollisionRaw(FPaddleRaftCollisionEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRaftDamaged(){}

	UFUNCTION(BlueprintPure)
	FVector GetRaftVelocity() const
	{
		return Raft.MovementComponent.Velocity;
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
		return FVector(FrontLocation.WorldLocation.X, FrontLocation.WorldLocation.Y, Raft.RaftRoot.WorldLocation.Z + Raft.RaftRoot.WaterLevelOffset);
	}

	UFUNCTION(BlueprintPure)
	FVector GetRaftBackLocation()
	{
		return FVector(BackLocation.WorldLocation.X, BackLocation.WorldLocation.Y, Raft.RaftRoot.WorldLocation.Z + Raft.RaftRoot.WaterLevelOffset);
	}

	UFUNCTION(BlueprintPure)
	FRotator GetRaftRotation()
	{
		return Raft.ActorRotation;
	}

	UFUNCTION(BlueprintPure)
	bool RaftIsMoving()
	{
		return !Raft.ActorVelocity.IsNearlyZero();
	}
}