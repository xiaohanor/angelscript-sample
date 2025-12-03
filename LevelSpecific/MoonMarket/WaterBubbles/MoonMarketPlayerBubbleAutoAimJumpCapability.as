class UMoonMarketPlayerBubbleAutoAimJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;

	UMoonMarketPlayerBubbleComponent BubbleComp;
	UPlayerMovementComponent MoveComp;
	UPlayerAirJumpComponent AirJumpComp;
	USweepingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BubbleComp = UMoonMarketPlayerBubbleComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSweepingMovementData();
		AirJumpComp = UPlayerAirJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BubbleComp.CurrentBubble == nullptr)
			return false;

		if(!BubbleComp.bCanJump)
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, 0.25))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WasActionStarted(ActionNames::MovementJump))
			return true;
		
		if(ActiveDuration > 0.5)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.PlaySlotAnimation(BubbleComp.LaunchAnimation);
		Player.ResetMovement();

		const bool bHasInput = !Math::IsNearlyZero(MoveComp.MovementInput.Size());
		if(bHasInput)
		{
			const float Threshold = 0.5;
			float HighestDot = Threshold;
			AMoonMarketWaterBubble BestBubble;

			for(auto Bubble : TListedActors<AMoonMarketWaterBubbleManager>().Single.Bubbles)
			{
				if(Bubble == BubbleComp.CurrentBubble)
					continue;

				FVector ToBubble = (Bubble.ActorLocation - Player.ActorLocation);
				if(ToBubble.Size() > 2000)
					continue;

				ToBubble = ToBubble.VectorPlaneProject(FVector::UpVector);

				FVector Input = MoveComp.MovementInput;
				float Dot = Input.DotProduct(ToBubble.GetSafeNormal());

				float DistToBestBubble = MAX_flt;
				if(BestBubble != nullptr)
					DistToBestBubble = (BestBubble.ActorLocation - Player.ActorLocation).VectorPlaneProject(FVector::UpVector).Size();

				if(Dot > HighestDot)
				{
					if(BestBubble != nullptr && Dot - HighestDot < 0.1)
					{
						if(ToBubble.Size() > DistToBestBubble)
							continue;
					}

					HighestDot = Dot;
					BestBubble = Bubble;
				}
				else if(Dot > Threshold && HighestDot - Dot < 0.1 && ToBubble.Size() < DistToBestBubble)
				{
					BestBubble = Bubble;
				}
			}

			//if(BestBubble != nullptr)
			//	Debug::DrawDebugSphere(BestBubble.ActorLocation, 200, Duration = 3);

			if(BestBubble != nullptr)
				LaunchWithAutoAim(BestBubble.Root);
			else
				LaunchNoAutoAim(bHasInput);
		}
		else
		{
			if(BubbleComp.TargetedBubbleSceneComp != nullptr)
				LaunchWithAutoAim(BubbleComp.TargetedBubbleSceneComp);
			else
				LaunchNoAutoAim(bHasInput);
		}

		Player.PlayCameraShake(BubbleComp.CameraShake, this, 1.4);
		Player.PlayForceFeedback(BubbleComp.Rumble, false, false, this);
		BubbleComp.CurrentBubble = nullptr;
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopSlotAnimation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			auto Rotation = MoveComp.Velocity.VectorPlaneProject(FVector::UpVector).GetSafeNormal().ToOrientationRotator();
			MoveData.SetRotation(Rotation);
			MoveData.AddOwnerVelocity();
			MoveData.AddPendingImpulses();
			MoveData.AddGravityAcceleration();
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	void LaunchWithAutoAim(USceneComponent TargetComp)
	{
		const float Speed = BubbleComp.TrajectoryLaunchSpeed;
		const float Gravity = UPlayerMovementComponent::Get(Player).GravityForce;

		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Owner.ActorLocation, TargetComp.WorldLocation, Gravity, Speed);
		Player.SetActorVelocity(LaunchVelocity);
		Player.SetActorRotation((LaunchVelocity.VectorPlaneProject(FVector::UpVector).GetSafeNormal()).ToOrientationRotator());
		BubbleComp.TargetedBubbleSceneComp = nullptr;
	}

	void LaunchNoAutoAim(bool bHasInput)
	{
		FVector Impulse;
		
		if(!bHasInput)
			Impulse = Player.GetCameraDesiredRotation().ForwardVector.VectorPlaneProject(FVector::UpVector) * BubbleComp.JumpOutForwardImpulse + FVector::UpVector * BubbleComp.JumpOutVerticalImpulse;
		else
			Impulse = MoveComp.MovementInput.Rotation().ForwardVector * BubbleComp.JumpOutForwardImpulse + FVector::UpVector * BubbleComp.JumpOutVerticalImpulse;
		
		Player.AddPlayerLaunchMovementImpulse(Impulse);
	}
};