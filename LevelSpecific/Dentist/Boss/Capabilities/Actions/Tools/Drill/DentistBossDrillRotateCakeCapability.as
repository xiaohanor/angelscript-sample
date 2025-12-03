struct FDentistBossDrillRotateCakeActivationParams
{
	float SpinDuration;
}

class UDentistBossDrillRotateCakeCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossDrillRotateCakeActivationParams Params;

	ADentistBossToolDrill Drill;
	ADentistBoss Dentist;
	ADentistBossCake Cake;

	FRotator LastFrameCakeRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		Drill = Cast<ADentistBossToolDrill>(Dentist.Tools[EDentistBossTool::Drill]);
		Cake = Dentist.Cake;
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossDrillRotateCakeActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= Params.SpinDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastFrameCakeRotation = Cake.InnerCakeRoot.WorldRotation; 
		if(HasControl())
			Cake.NetStartRotating(Time::GlobalCrumbTrailTime);
		
		FDentistBossEffectHandlerOnDrillStartedSpinningArenaParams EffectParams;
		EffectParams.DrillHitLocation = Cake.ActorLocation;
		UDentistBossEffectHandler::Trigger_OnDrillStartedSpinningArena(Dentist, EffectParams);

		// The drill is usually EnemyCharacter, and we use that so that the split teeth always ignore it
		// But while the drill is drilling the cake, this is no good!
		Drill.DrillTipMesh.SetCollisionObjectType(ECollisionChannel::ECC_WorldDynamic);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Drill.bIsDirected = false;
		Dentist.bDrillSpinArena = false;

		FDentistBossEffectHandlerOnDrillStoppedSpinningArenaParams EffectParams;
		EffectParams.DrillHitLocation = Cake.ActorLocation;
		UDentistBossEffectHandler::Trigger_OnDrillStoppedSpinningArena(Dentist, EffectParams);
		
		Drill.DrillTipMesh.SetCollisionObjectType(ECollisionChannel::EnemyCharacter);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator CakeRotation = Cake.InnerCakeRoot.WorldRotation;
		FRotator DeltaRotation = LastFrameCakeRotation - CakeRotation;

		Drill.DrillRoot.AddRelativeRotation(FRotator(0, DeltaRotation.Yaw * 30, 0));
		LastFrameCakeRotation = CakeRotation;
	}
};