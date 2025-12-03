struct FSandSharkLungeAttackDeactivateParams
{
	ASandSharkSpline TargetSpline;
} class USandSharkLungeAttackCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SandSharkTags::SandShark);
	default CapabilityTags.Add(SandSharkTags::SandSharkLunge);

	default CapabilityTags.Add(SandSharkBlockedWhileIn::AttackFromBelow);
	default CapabilityTags.Add(SandSharkBlockedWhileIn::Distract);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = SandShark::TickGroupOrder::Lunge;
	default TickGroupSubPlacement = 0;

	USandSharkMovementComponent MoveComp;
	USandSharkLungeComponent LungeComp;
	USandSharkAnimationComponent AnimationComp;

	USandSharkSettings SharkSettings;

	ASandShark SandShark;

	FQuat InitialRotation;

	bool bCanAttackTarget = false;

	TOptional<FVector> LastValidPlayerSandLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		MoveComp = USandSharkMovementComponent::Get(Owner);
		LungeComp = USandSharkLungeComponent::Get(Owner);
		AnimationComp = USandSharkAnimationComponent::Get(Owner);
		SharkSettings = USandSharkSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!LungeComp.bIsLunging)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSandSharkLungeAttackDeactivateParams& Params) const
	{
		bool bShouldDeactivate = false;
		if (ActiveDuration >= SandShark::Animations::LungeDuration)
			bShouldDeactivate = true;

		if (LungeComp.State != ESandSharkLungeState::Jumping)
			bShouldDeactivate = true;

		if (bShouldDeactivate)
		{
			ASandSharkSpline TargetSpline;
			auto Player = SandShark.GetTargetPlayer();
			auto LastSafePoint = USandSharkPlayerComponent::Get(Player).GetLastSafePoint();

			if (LastSafePoint != nullptr)
				TargetSpline = LastSafePoint.Spline;
			else
				TargetSpline = SandShark.GetCurrentSpline();

			Params.TargetSpline = TargetSpline;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (DeactiveDuration < 0.4)
			SandShark.SetActorRotation(GetBestRotation());

		MoveComp.AccDive.SnapTo(0);
		bCanAttackTarget = true;
		AnimationComp.Data.Lunge.bIsJumping = true;
		USandSharkEventHandler::Trigger_OnJumpAttackStarted(SandShark);
		LungeComp.State = ESandSharkLungeState::Jumping;
		AnimationComp.AddHighAnimUpdateInstigator(this);
		InitialRotation = SandShark.ActorQuat;
		LastValidPlayerSandLocation.Set(SandShark.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSandSharkLungeAttackDeactivateParams Params)
	{
		AnimationComp.RemoveHighAnimUpdateInstigator(this);
		MoveComp.AccMovementSpeed.SnapTo(0);
		bCanAttackTarget = false;
		AnimationComp.Data.Lunge.bIsJumping = false;
		LungeComp.bIsLunging = false;

		USandSharkEventHandler::Trigger_OnJumpAttackFinished(SandShark);
	}

	FRotator GetBestRotation()
	{
		float BestScore = -1;

		// Check initial rotation to player, if no blocking hit we use that one
		// Otherwise we trace from points around player towards player and use the one that doesn't have a blocking hit,
		// or the one that has the blocking hit furthest from start

		FVector PlayerLocation = Desert::GetLandscapeLocationByLevel(SandShark.GetTargetPlayer().ActorLocation, ESandSharkLandscapeLevel::Lower);
		FVector InitialToPlayer = (PlayerLocation - SandShark.ActorLocation - SandShark.ActorForwardVector * 100).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		FRotator BestRotation = FRotator::MakeFromXZ(InitialToPlayer, FVector::UpVector);
		FHazeTraceSettings TraceSettings;
		TraceSettings.TraceWithChannel(ECollisionChannel::EnemyCharacter);
		TraceSettings.UseSphereShape(50);
		TraceSettings.IgnoreActor(Desert::GetLandscapeActor(ESandSharkLandscapeLevel::Lower));
		TraceSettings.IgnoreActor(SandShark);
		TraceSettings.IgnorePlayers();
		FVector SandSharkLocation = Desert::GetLandscapeLocationByLevel(SandShark.ActorLocation, ESandSharkLandscapeLevel::Lower);
		FHitResult InitialHit = TraceSettings.QueryTraceSingle(SandSharkLocation - BestRotation.ForwardVector * 100, SandSharkLocation + BestRotation.ForwardVector * 100);
		if (!InitialHit.bBlockingHit)
			return BestRotation;

		int NumIterations = 4;
		float AngleAmount = 180.0 / NumIterations;
		for (int i = 1; i < NumIterations; i++)
		{
			FVector ClockwiseToPlayer = InitialToPlayer.RotateAngleAxis(AngleAmount * i, FVector::UpVector);
			FVector CounterClockwiseToPlayer = InitialToPlayer.RotateAngleAxis(AngleAmount * -i, FVector::UpVector);
			FHitResult Hit1 = TraceSettings.QueryTraceSingle(SandSharkLocation - (ClockwiseToPlayer * 200), SandSharkLocation + ClockwiseToPlayer * 100);
			FHitResult Hit2 = TraceSettings.QueryTraceSingle(SandSharkLocation - (CounterClockwiseToPlayer * 200), SandSharkLocation + CounterClockwiseToPlayer * 100);
			FRotator ClockwiseRotation = FRotator::MakeFromXZ(ClockwiseToPlayer, FVector::UpVector);
			FRotator CounterClockwiseRotation = FRotator::MakeFromXZ(CounterClockwiseToPlayer, FVector::UpVector);
			float Score1 = 0, Score2 = 0;
			if (Hit1.bBlockingHit)
				Score1 = 10000 * Hit1.Time;
			else
				return ClockwiseRotation;

			if (Hit2.bBlockingHit)
				Score2 = 10000 * Hit2.Time;
			else
				return CounterClockwiseRotation;

			if (Score1 > BestScore)
			{
				BestScore = Score1;
				BestRotation = FRotator::MakeFromXZ(ClockwiseToPlayer, FVector::UpVector);
			}
			else if (Score2 > BestScore)
			{
				BestScore = Score2;
				BestRotation = FRotator::MakeFromXZ(CounterClockwiseToPlayer, FVector::UpVector);
			}
		}
		return BestRotation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			if (AnimationComp.HasBreachedSand())
			{
				AnimationComp.ConsumeSandBreach();
				FSandSharkSandBreachParams Params;
				Params.SandBreachedLocation = Desert::GetLandscapeLocationByLevel(AnimationComp.GetNeckLocation(), ESandSharkLandscapeLevel::Lower);
				USandSharkEventHandler::Trigger_OnJumpAttackBreakSandSurface(SandShark, Params);
			}

			if (ActiveDuration < SandShark::Lunge::TimeBeforeKill)
				MoveComp.AccDive.AccelerateTo(SandShark::Idle::Height, 0.25, DeltaTime);
			else if (ActiveDuration > SandShark::Lunge::TimeBeforeKill + 0.4)
				MoveComp.AccDive.AccelerateTo(-700, SandShark::Animations::LungeDuration - SandShark::Lunge::TimeBeforeKill - 0.4, DeltaTime);

			SandShark.AccMeshForwardOffset.AccelerateTo(0, 0.5, DeltaTime);

			auto Player = SandShark.GetTargetPlayer();

			FVector TargetLocation = SandShark.ActorLocation;
			// Debug::DrawDebugSphere(TargetLocation, 250, 12, FLinearColor::White, 4, 100);
			FVector NewLocation = SandShark.ActorLocation;
			if (Pathfinding::FindNavmeshLocation(Player.ActorLocation, SandShark::Navigation::AgentRadius, SandShark::Navigation::AgentHeight, TargetLocation))
				LastValidPlayerSandLocation.Set(TargetLocation);

			NewLocation = Math::VInterpConstantTo(SandShark.ActorLocation, Desert::GetLandscapeLocationByLevel(LastValidPlayerSandLocation.Value, SandShark.LandscapeLevel), DeltaTime, Math::Max(MoveComp.AccMovementSpeed.Value, 1000));

			if (bCanAttackTarget)
			{
				FVector ToPlayer = (Player.ActorLocation - SandShark.ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
				if (ToPlayer.IsZero())
					ToPlayer = SandShark.ActorForwardVector;
				FRotator TargetRotation = FRotator::MakeFromXZ(ToPlayer, FVector::UpVector);
				FRotator NewRotation = Math::RInterpShortestPathTo(SandShark.ActorRotation, TargetRotation, DeltaTime, 1);
				MoveComp.ApplyMove(NewLocation, NewRotation.Quaternion(), this);
			}

			if (ActiveDuration >= SandShark::Lunge::TimeBeforeKill)
			{
				TArray<AHazePlayerCharacter> KilledPlayers;
				if (SandShark.AttemptKillPlayersAtMouth(KilledPlayers))
				{
					for (auto KilledPlayer : KilledPlayers)
					{
						KilledPlayer.PlayForceFeedback(LungeComp.KillForceFeedback, false, false, this, LungeComp.ForceFeedbackMaxIntensity);
					}
				}
			}

			if (!SandShark.IsTargetPlayerAttackable())
				bCanAttackTarget = false;
		}
		else
		{
			MoveComp.ApplyCrumbSyncedLocationAndRotation(this);
		}
	}
};