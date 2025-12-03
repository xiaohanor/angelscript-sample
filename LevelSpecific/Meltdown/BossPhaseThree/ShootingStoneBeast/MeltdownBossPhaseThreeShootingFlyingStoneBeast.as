class AMeltdownBossPhaseThreeShootingFlyingStoneBeast : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LaserMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent WorldMesh;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"MeltdownBossPhaseThreeStoneBeastActionSelectionCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MeltdownBossPhaseThreeStoneBeastSpawnCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MeltdownBossPhaseThreeStoneBeastTrackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MeltdownBossPhaseThreeStoneBeastFireCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MeltdownBossPhaseThreeStoneBeastIdleCapability");

	UPROPERTY()
	FRotator LaserOffsetRotation(10.0, 10.0, 0.0);

	UPROPERTY()
	FVector WorldStartScale;
	UPROPERTY()
	FVector WorldEndScale;

	UPROPERTY()
	FVector LaserStartScale;
	UPROPERTY()
	FVector LaserEndScale;

	FHazeStructQueue ActionQueue;
	AHazePlayerCharacter PlayerToTrack;
	int RemainingAttackCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WorldStartScale = WorldMesh.RelativeScale3D;
		LaserStartScale = LaserMesh.RelativeScale3D;

		AddActorDisable(this);
	}

	UFUNCTION(DevFunction)
	void StartAttack(int Attacks = 4)
	{
		RemainingAttackCount = Attacks;
		RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}
}
;