class USketchbookBossBuryUndergroundCapability : USketchbookCrabBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction); 

	FVector TargetLocation;

	const float AnimAnticipationTime = 1;
	const float BuryTime = 2;
	bool bHasBuried = false;

	USketchbookBossJumpComponent JumpComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		JumpComp = USketchbookBossJumpComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CrabComp.SubPhase != ESketchbookCrabBossSubPhase::Bury)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Owner.ActorLocation.Z <= TargetLocation.Z)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetLocation = Owner.ActorLocation;
		TargetLocation.Z = Boss.ArenaFloorZ - CrabComp.BuryDepth;
		auto BossManager = SketchbookBoss::GetSketchbookBossFightManager();
		BossManager.SetNewCameraTargetLocation(BossManager.CameraDefaultLocation + FVector::DownVector * CrabComp.CameraBuryDepth);

		Boss.RotateTowards(FQuat::MakeFromEuler(FVector::UpVector * 0), InterpSpeed = 99999);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.SetActorLocation(TargetLocation);

		if(JumpComp.JumpsInRow >= JumpComp.JumpsToDo || CrabComp.bMainSequenceActive)
		{
			Boss.StartMainAttackSequence();
			JumpComp.JumpsInRow = 0;
		}
		else CrabComp.SubPhase = ESketchbookCrabBossSubPhase::Chasing;

		bHasBuried = false;
		CrabComp.bIsUnderground = true;

		Boss.Mesh.SetAnimBoolParam(n"EnterBurrow", false);
		Boss.Mesh.SetAnimTrigger(n"BurrowComplete");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration >= AnimAnticipationTime)
			Boss.Mesh.SetAnimBoolParam(n"EnterBurrow", true);

		if(ActiveDuration < BuryTime)
			return;

		if(!bHasBuried)
			USketchbookBossEffectEventHandler::Trigger_OnPrepareAttack(Boss);

		FVector NewLocation = Math::VInterpConstantTo(Owner.ActorLocation, TargetLocation, DeltaTime, CrabComp.BurySpeed);
		Owner.SetActorLocation(NewLocation);
		bHasBuried = true;
	}
};