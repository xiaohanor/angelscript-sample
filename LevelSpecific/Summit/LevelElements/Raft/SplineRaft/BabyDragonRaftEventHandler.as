struct FBabyDragonRaftOarEventParams
{
	UPROPERTY()
	FVector OarWaterEnterLocation;
}

UCLASS(Abstract)
class UBabyDragonRaftEventHandler : UHazeEffectEventHandler
{

	UHazeOffsetComponent FrontLocation;
	UHazeOffsetComponent BackLocation;

	ABabyDragonRaft Raft;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Raft = Cast<ABabyDragonRaft>(Owner);
		check(Raft != nullptr);

		FrontLocation = Raft.RaftFront;
		BackLocation = Raft.RaftBack;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOarEnterWater(FBabyDragonRaftOarEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhileOarSubmerged(FBabyDragonRaftOarEventParams Params) {}

	UFUNCTION(BlueprintPure)
	float GetCurrentRaftSpeed()
	{
		return Raft.bIsMoving ? Raft.RaftSpeed : 0;
	}

	UFUNCTION(BlueprintPure)
	FVector GetRaftFrontLocation()
	{
		return FVector(FrontLocation.WorldLocation.X, FrontLocation.WorldLocation.Y, 
		Raft.RootComp.WorldLocation.Z + Raft.RootComp.WaterLevelOffset);
	}

	UFUNCTION(BlueprintPure)
	FVector GetRaftBackLocation()
	{
		return FVector(BackLocation.WorldLocation.X, BackLocation.WorldLocation.Y, 
		Raft.RootComp.WorldLocation.Z + Raft.RootComp.WaterLevelOffset);
	}

	UFUNCTION(BlueprintPure)
	FRotator GetRaftRotation()
	{
		return Raft.ActorRotation;
	}

	UFUNCTION(BlueprintPure)
	bool RaftIsMoving()
	{
		return Raft.bIsMoving;
	}
}