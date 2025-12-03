class USketchbookBossChasePlayerUndergroundCapability : USketchbookCrabBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction); 


	FVector LastUpdatedPlayerPosition;
	float LastUpdatedPlayerPositionTime;
	const float RefreshRate = 1;

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
		if(CrabComp.SubPhase != ESketchbookCrabBossSubPhase::Chasing)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Math::Abs(LastUpdatedPlayerPosition.Y - Owner.ActorLocation.Y) <= KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Always target closest player first
		if(JumpComp.JumpsInRow == 0 && Boss.CurrentTargetPlayer == nullptr)
			Boss.CurrentTargetPlayer = Game::GetClosestPlayer(Boss.ActorLocation);
		else
			Boss.CurrentTargetPlayer = Game::GetOtherPlayer(Boss.CurrentTargetPlayer.Player);

		if(Boss.CurrentTargetPlayer.IsPlayerDead())
			Boss.CurrentTargetPlayer = Game::GetOtherPlayer(Boss.CurrentTargetPlayer.Player);
		
		UpdatePlayerPosition();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CrabComp.SubPhase = ESketchbookCrabBossSubPhase::Jump;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Time::GetGameTimeSince(LastUpdatedPlayerPositionTime) >= RefreshRate)
		{
			UpdatePlayerPosition();
		}
		
		FVector NewLocation = Math::VInterpConstantTo(Owner.ActorLocation, LastUpdatedPlayerPosition, DeltaTime, CrabComp.HorizontalMoveSpeed);
		Owner.SetActorLocation(NewLocation);
	}

	void UpdatePlayerPosition()
	{
		LastUpdatedPlayerPosition = Boss.CurrentTargetPlayer.ActorLocation;
		LastUpdatedPlayerPosition.Z = Owner.ActorLocation.Z;
		LastUpdatedPlayerPositionTime = Time::GameTimeSeconds;

		float YawMultiplier = 1;
		if(Boss.CurrentTargetPlayer.ActorLocation.Y > Owner.ActorLocation.Y)
			YawMultiplier = -1;

		// Boss.RotateTowards(FQuat::MakeFromEuler(FVector::UpVector * 30 * YawMultiplier));
	}
};