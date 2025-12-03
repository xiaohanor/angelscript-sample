class URemoteHackableRobotMouseCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	ARemoteHackableRobotMouse RobotMouse;

	const float MoveSpeed = 90.0;

	FSplinePosition SplinePos;

	bool bStruggling = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		RobotMouse = Cast<ARemoteHackableRobotMouse>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplinePos = FSplinePosition(RobotMouse.FollowSplineComp, 0.0, true);

		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		URemoteHackableMouseEffectEventHandler::Trigger_StopStruggling(RobotMouse);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			TickControl(DeltaTime);
		}
		else
		{
			TickRemote(DeltaTime);
		}

		if (RobotMouse.IsStruggling())
		{
			if (!bStruggling)
			{
				bStruggling = true;
				URemoteHackableMouseEffectEventHandler::Trigger_StartStruggling(RobotMouse);
			}
		}
		else
		{
			if (bStruggling)
			{
				bStruggling = false;
				URemoteHackableMouseEffectEventHandler::Trigger_StopStruggling(RobotMouse);
			}
		}
	}

	private void TickControl(float DeltaTime)
	{
		check(HasControl());

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		// float MoveInput = RobotMouse.bSideScrolling ? Input.Y : Input.X;
		float MoveInput = Math::Clamp(Input.Y + Input.X, -1.0, 1.0);
		if (RobotMouse.bForwardBlocked)
			MoveInput = Math::Clamp(MoveInput, -1.0, 0.0);

		if (!RobotMouse.bFallen)
		{
			SplinePos.Move(MoveInput * MoveSpeed * DeltaTime);
			RobotMouse.SyncedSplinePosComp.SetValue(SplinePos);

			FVector Loc = Math::VInterpTo(RobotMouse.ActorLocation, RobotMouse.SyncedSplinePosComp.Value.WorldLocation, DeltaTime, 5.0);
			RobotMouse.SetActorLocation(Loc);

			FRotator Rot = Math::RInterpTo(RobotMouse.ActorRotation, FRotator(RobotMouse.SyncedSplinePosComp.Value.WorldRotation), DeltaTime, 5.0);
			RobotMouse.SetActorRotation(Rot);
		}
		else
		{
			if (Math::Abs(MoveInput) >= 0.2)
			{
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(ActiveDuration * 80) * 0.2;
				FF.RightMotor = Math::Sin(-ActiveDuration * 80) * 0.2;
				Player.SetFrameForceFeedback(FF);
			}
		}

		MoveInput = Input.X + Input.Y;
	}

	private void TickRemote(float DeltaTime)
	{
		check(!HasControl());

		if (!RobotMouse.bFallen)
		{
			// Move towards synced spline position
			FVector Loc = Math::VInterpTo(RobotMouse.ActorLocation, RobotMouse.SyncedSplinePosComp.Value.WorldLocation, DeltaTime, 5.0);
			RobotMouse.SetActorLocation(Loc);

			FRotator Rot = Math::RInterpTo(RobotMouse.ActorRotation, FRotator(RobotMouse.SyncedSplinePosComp.Value.WorldRotation), DeltaTime, 5.0);
			RobotMouse.SetActorRotation(Rot);
		}
	}
}