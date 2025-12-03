
class UTeenDragonTailGeckoClimbEnterJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 79;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UHazeMovementComponent MoveComp;
	
	UTeleportingMovementData Movement;
	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;

	UCameraUserComponent CameraUser;

	UTeenDragonTailGeckoClimbEnterJumpSettings EnterSettings;

	FRotator CurrentRotation;
	FRotator StartRotation;
	FRotator FacingWallRotation;
	FRotator LandedOnWallRotation;

	FRotator WallTransitionStartViewRotation;

	FVector StartPos;

	bool bHasLandedWithDelay = false;

	bool bIsInAnticipation;
	bool bHasReachedWall;
	bool bHasCompleted;

	float TimeToWall = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);

		CameraUser = UCameraUserComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		EnterSettings = UTeenDragonTailGeckoClimbEnterJumpSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!GeckoClimbComp.bHasWallEnterLocation)
			return false;

		if(!MoveComp.HasGroundContact())
			return false;

		if(TailDragonComp.IsClimbing())
			return false;

		if(!TailDragonComp.bWantToJump)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bHasLandedWithDelay)
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GeckoClimbComp.JumpOntoWallAlpha = 0.0;

		GeckoClimbComp.bIsJumpingOntoWall = true;
		GeckoClimbComp.bHasReachedWall = false;
		bHasLandedWithDelay = false;

		FVector LandLocation = GeckoClimbComp.WallEnterClimbParams.Location;
		StartPos = Player.ActorLocation;

		TailDragonComp.ConsumeJumpInput();

		TailDragonComp.AnimationState.Apply(ETeenDragonAnimationState::Jump, this);
		StartRotation = Player.ActorRotation;

		FVector FlatLandLocation = LandLocation;
		FlatLandLocation.Z = Player.ActorLocation.Z;
		FVector DirToWall = (FlatLandLocation - Player.ActorLocation).GetSafeNormal();
		FacingWallRotation = FRotator::MakeFromXZ(DirToWall, Player.ActorUpVector);

		TimeToWall = Player.ActorLocation.Distance(LandLocation) / GeckoClimbComp.JumpOntoWallSpeed;
		float TotalDuration = GeckoClimbComp.WallEnterAnticipation + TimeToWall + GeckoClimbComp.WallEnterLandTime;

		// FVector ToWall = GeckoClimbComp.WallEnterClimbParams.Location - TeenDragon.ActorLocation;
		// FVector WallForward = ToWall.VectorPlaneProject(GeckoClimbComp.WallEnterClimbParams.WallNormal);
		// WallRotation = FRotator::MakeFromXZ(WallForward, GeckoClimbComp.WallEnterClimbParams.WallNormal);
		FVector Normal = GeckoClimbComp.WallEnterClimbParams.WallNormal;
		FVector Forward = GeckoClimbComp.WallEnterClimbParams.ClimbComp.Owner.ActorUpVector;
		LandedOnWallRotation = FRotator::MakeFromXZ(Forward, Normal);
		WallTransitionStartViewRotation = CameraUser.ViewRotation;

		// Debug::DrawDebugDirectionArrow(GeckoClimbComp.WallEnterClimbParams.Location, Forward, 500, 20, FLinearColor::Red, 10, 2);
		// Debug::DrawDebugDirectionArrow(GeckoClimbComp.WallEnterClimbParams.Location, Normal, 500, 20, FLinearColor::Blue, 10, 2);
		// GeckoClimbComp.OverrideCameraTransitionAlpha(1.0);

		Player.ApplyBlendToCurrentView(TotalDuration, UTeenDragonTailGeckoClimbBlend());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GeckoClimbComp.UpdateClimbParams(GeckoClimbComp.WallEnterClimbParams);
		GeckoClimbComp.StartClimbing();
		TailDragonComp.AnimationState.Clear(this);
		GeckoClimbComp.bIsJumpingOntoWall = false;
		//SpringArm.ClearReachModifiers(CameraUser, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float AfterAnticipationDuration = ActiveDuration - GeckoClimbComp.WallEnterAnticipation;
		float TimeUntilLand = TimeToWall - GeckoClimbComp.WallEnterAnticipation;
		float FullDuration = TimeUntilLand + GeckoClimbComp.WallEnterLandTime;

		// Make camera look in the original rotation while jumping towards wall
		CameraUser.SetDesiredRotation(WallTransitionStartViewRotation, this);

		bIsInAnticipation = ActiveDuration < GeckoClimbComp.WallEnterAnticipation;
		bHasReachedWall = AfterAnticipationDuration >= TimeUntilLand;
		bHasCompleted = AfterAnticipationDuration >= FullDuration;

		FVector UpVector;
		float Alpha;
		if(bIsInAnticipation)
		{
			Alpha = ActiveDuration / GeckoClimbComp.WallEnterAnticipation;
			UpVector = FVector::UpVector;
		}
		else if(!bHasReachedWall)
		{
			Alpha = AfterAnticipationDuration / TimeUntilLand;
			GeckoClimbComp.OverrideCameraTransitionAlpha(Alpha);
			UpVector = CurrentRotation.UpVector;
		}
		else
		{
			Alpha = 1.0;
			GeckoClimbComp.OverrideCameraTransitionAlpha(Alpha);
			UpVector = GeckoClimbComp.WallEnterClimbParams.ClimbUpVector;
			if(HasControl())
				CrumbSetHasReachedWall();
		}

		if(bHasCompleted)
			bHasLandedWithDelay = true;

		GeckoClimbComp.JumpOntoWallAlpha = AfterAnticipationDuration / FullDuration;

		TEMPORAL_LOG(Player).Value("Wall Enter Jump Alpha", Alpha);

		// FVector UpVector = GeckoClimbComp.WallEnterClimbParams.ClimbUpVector;
		// FVector UpVector = bHasReachedTarget ? GeckoClimbComp.WallEnterClimbParams.ClimbUpVector : FVector::UpVector;
		// Debug::DrawDebugDirectionArrow(TeenDragon.ActorLocation, UpVector, 500, 50, FLinearColor::LucBlue, 10);


		if (MoveComp.PrepareMove(Movement, UpVector))
		{
			if (HasControl())
			{
				if(bIsInAnticipation)
				{
					CurrentRotation = FQuat::Slerp(StartRotation.Quaternion(), FacingWallRotation.Quaternion(), Alpha).Rotator();
				}
				else if(!bHasReachedWall)
				{
					CurrentRotation = FQuat::Slerp(FacingWallRotation.Quaternion(), LandedOnWallRotation.Quaternion(), Alpha).Rotator();
					float CurvedAlpha = EnterSettings.DefaultJumpSpeedCurve.GetFloatValue(Alpha);
					FVector LerpedPos = Math::Lerp(StartPos, GeckoClimbComp.WallEnterClimbParams.Location, CurvedAlpha);
					Movement.AddDeltaFromMoveToPositionWithCustomHorizontalAndVerticalVelocity(LerpedPos, FVector::ZeroVector, FVector::ZeroVector);
				}
				else
				{
					CurrentRotation = LandedOnWallRotation;
					FVector LerpedPos = Math::Lerp(StartPos, GeckoClimbComp.WallEnterClimbParams.Location, Alpha);
					Movement.AddDeltaFromMoveToPositionWithCustomHorizontalAndVerticalVelocity(LerpedPos, FVector::ZeroVector, FVector::ZeroVector);
				}
				Movement.SetRotation(CurrentRotation);
				// Debug::DrawDebugCoordinateSystem(TeenDragon.ActorLocation, CurrentRotation, 300);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			TailDragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TailTeenClimb);
		}

	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbSetHasReachedWall()
	{
		GeckoClimbComp.bHasReachedWall = true;
	}
};
