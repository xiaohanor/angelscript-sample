class UTundraBossSetupSmashAttackCapability : UTundraBossSetupChildCapability
{
	float Duration = 1;
	bool bShouldTargetMio = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossSetupStates::Smash)
			return false;

		if(!HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector NewSmashAttackLoc;
		FRotator NewSmashAttackRot;

		AHazePlayerCharacter TargetPlayer = bShouldTargetMio ? Game::Mio : Game::Zoe;
		if(TargetPlayer.IsPlayerDead())
			TargetPlayer = TargetPlayer.OtherPlayer;

		FVector Dir = (TargetPlayer.ActorLocation - Boss.IceFloorNew.ActorLocation).GetSafeNormal2D();
		float Dot = Dir.DotProduct(Boss.IceFloorNew.ActorRightVector);

		if(Dot > 0)
		{
			NewSmashAttackLoc = FVector(Boss.IceFloorNew.ActorLocation.X - 1340, TargetPlayer.ActorLocation.Y - 300, Boss.IceFloorNew.ActorLocation.Z + 40);
			NewSmashAttackRot = FRotator::ZeroRotator;
		}
		else
		{
			NewSmashAttackLoc = FVector(Boss.IceFloorNew.ActorLocation.X + 1340, TargetPlayer.ActorLocation.Y + 300, Boss.IceFloorNew.ActorLocation.Z + 40);
			NewSmashAttackRot = FRotator(0, 180, 0);
		}
		
		Duration = Boss.AnimInstance.GetTundraBossSetupAnimationDuration(ETundraBossSetupAttackAnim::Smash);
		bShouldTargetMio = !bShouldTargetMio;
		Boss.CrumbActivateSmashAttack(ETundraBossSetupAttackAnim::Smash, NewSmashAttackLoc, NewSmashAttackRot);
		FTundraBossPhase01AttackEventData Data;
		Data.AttackType = ETundraBossSetupAttackAnim::Smash;
		Boss.CrumbTriggerSmashAttackVO(Data);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(HasControl())
			Boss.CrumbProgressQueue();
	}

	ATundraBossSetupSmashAttackActor ReturnSmashAttackActorBasedOnPlatformIndex(int Index, TArray<ATundraBossSetupSmashAttackActor> Array)
	{
		for(auto SmashActor : Array)
		{
			if(SmashActor.PlatformIndex == Index)
				return SmashActor;
		}

		return nullptr;
	}
};