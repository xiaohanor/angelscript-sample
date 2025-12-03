class AMeltdownWorldSpinLaserChaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsSplineFollowComponent SplineFollow;
	default SplineFollow.NetworkMode = EFauxPhysicsSplineFollowNetworkMode::SyncedFromMioControl;

	UPROPERTY(DefaultComponent, Attach = SplineFollow)
	UFauxPhysicsWeightComponent FauxWeightComp;

	UPROPERTY(DefaultComponent, Attach = FauxWeightComp)
	UStaticMeshComponent BottomMachine;

	UPROPERTY(DefaultComponent, Attach = FauxWeightComp)
	UStaticMeshComponent TopMachine;

	UPROPERTY(DefaultComponent, Attach = FauxWeightComp)
	UDeathTriggerComponent LaserLeft;

	UPROPERTY(DefaultComponent, Attach = FauxWeightComp)
	UDeathTriggerComponent LaserRight;

	UPROPERTY(DefaultComponent)
    UMeltdownWorldSpinFauxPhysicsResponseComponent FauxResponseComp;

	UPROPERTY(EditInstanceOnly)
	TArray<ARespawnPoint> AvailableRespawnPoints;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserLeft.DisableDeathTrigger(this);
		LaserRight.DisableDeathTrigger(this);
	}

	UFUNCTION(BlueprintCallable)
	void StartLaser()
	{
		LaserEvent();
		LaserLeft.EnableDeathTrigger(this);
		LaserRight.EnableDeathTrigger(this);

		UMeltdownWorldSpinLaserChaserEventHandler::Trigger_LaserStarted(this);

		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"HandleRespawn");
		Game::Zoe.ApplyRespawnPointOverrideDelegate(this, RespawnOverride);
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		ARespawnPoint BestRespawnPoint;
		float BestRespawnPointDistance = BIG_NUMBER;

		FVector TargetLocation = FauxWeightComp.WorldLocation;
		TargetLocation.Z = Player.ActorLocation.Z;

		FVector LeftDirection = (LaserLeft.WorldLocation - TargetLocation).GetSafeNormal2D();
		float MaxLeftDistance = (LaserLeft.WorldLocation - TargetLocation).Size2D();
		FVector RightDirection = (LaserRight.WorldLocation - TargetLocation).GetSafeNormal2D();
		float MaxRightDistance = (LaserRight.WorldLocation - TargetLocation).Size2D();

		for (ARespawnPoint RespawnPoint : AvailableRespawnPoints)
		{
			// Don't allow respawn points that aren't contained within the lasers
			FVector RespawnLocation = RespawnPoint.GetPositionForPlayer(Player).Location;

			float LeftDistance = (RespawnLocation - TargetLocation).DotProduct(LeftDirection);
			if (LeftDistance > MaxLeftDistance)
				continue;

			float RightDistance = (RespawnLocation - TargetLocation).DotProduct(RightDirection);
			if (RightDistance > MaxRightDistance)
				continue;

			float Distance = RespawnLocation.Distance(TargetLocation);
			if (Distance < BestRespawnPointDistance)
			{
				BestRespawnPoint = RespawnPoint;
				BestRespawnPointDistance = Distance;
			}
		}

		if (BestRespawnPoint != nullptr)
		{
			OutLocation.RespawnRelativeTo = BestRespawnPoint.Root;
			OutLocation.RespawnPoint = BestRespawnPoint;
			OutLocation.RespawnTransform = BestRespawnPoint.GetRelativePositionForPlayer(Player);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintEvent)
	void LaserEvent()
	{

	}

	UFUNCTION(BlueprintCallable)
	void ApplyGravity()
	{
		FauxWeightComp.bApplyGravity = true;
	}

	UFUNCTION(BlueprintCallable)
	void DisableGravity()
	{
		FauxWeightComp.bApplyGravity = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Distance = Game::Zoe.GetDistanceTo(this);
		if (Distance < 5000.0)
			SplineFollow.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		else
			SplineFollow.OverrideNetworkSyncRate(EHazeCrumbSyncRate::Standard);
	}
};

UCLASS(Abstract)
class UMeltdownWorldSpinLaserChaserEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaserStarted() {}

};
