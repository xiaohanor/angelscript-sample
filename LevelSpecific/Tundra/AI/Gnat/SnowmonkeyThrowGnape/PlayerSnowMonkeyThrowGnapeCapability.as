struct FSnowMonkeyThrowGnapeParams
{
	AHazeActor Gnape;
}

class UTundraPlayerSnowMonkeyThrowGnapeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkey);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyGroundedGroundSlam);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(n"ThrowGnape");
	
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 42; // Before regular ground pounds

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerSnowMonkeyThrowGnapeComponent ThrowGnapeComp;
	UPlayerMovementComponent MoveComp;
	UTundraPlayerShapeshiftingComponent ShapeShiftComponent;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	USteppingMovementData Movement;
	UTundraPlayerSnowMonkeySettings GorillaSettings;

	bool bShapeshiftBlocked = false;

	float GrabCompleteTime;
	float ThrowCompleteTime;
	float ThrowLaunchTime;

	FVector MoveDir;
	float CurrentSpeed;

	bool bReadyToThrow = false;
	AHazeActor ThrowAtTarget;
	float ThrowAtRetargetTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		ShapeShiftComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		ThrowGnapeComp = UPlayerSnowMonkeyThrowGnapeComponent::Get(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GorillaSettings = UTundraPlayerSnowMonkeySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Since we get monkey business requested after gnape spawner requests this capability, we might need to delay getting some comps
		if (ShapeShiftComponent != nullptr)
			return;
		ShapeShiftComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
	}

	AHazeActor FindGnape(float Range, float Radius, float NearRadius) const
	{
		if (ThrowGnapeComp == nullptr)
			return nullptr;

		FVector OwnLoc = Owner.ActorLocation;
		FVector OwnFwd = Owner.ActorForwardVector;
		FVector FarLoc = OwnLoc + OwnFwd * (Range - Radius);
		float BestScore = 0.0;
		float RangeSqr = Math::Square(Range);
		AHazeActor ThrowableGnape = nullptr;
		for (AHazeActor Gnape : ThrowGnapeComp.Gnapes)
		{
			if (Gnape == ThrowGnapeComp.GrabbedGnape)
				continue;

			// If there is any gnape threatening Zoe within slam range, we use regular slam attack instead		
			if (Gnape.ActorLocation.IsWithinDist2D(OwnLoc, GorillaSettings.GroundSlamRadius) && IsThreateningTreeGuardian(Gnape))
				return nullptr; // No time for grab, slam!

			float DistSqr = OwnLoc.DistSquared(Gnape.ActorLocation);
			if (DistSqr > RangeSqr)
				continue;
			float FwdDotDist = OwnFwd.DotProduct(Gnape.ActorLocation - OwnLoc);
			if (FwdDotDist < 0.0)
				continue;
			float Score = FwdDotDist / Math::Max(1.0, DistSqr); // Dot / Dist
			if (Score < BestScore)
				continue;
			UTundraGnatComponent GnapeComp = UTundraGnatComponent::Get(Gnape);
			if (GnapeComp.bThrownByMonkey || GnapeComp.bGoBallistic)
				continue;			
			UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Gnape);
			if (HealthComp.IsDead())
				continue;
			if (!Gnape.ActorLocation.IsInsideTeardrop(OwnLoc, FarLoc, NearRadius, Radius))
				continue;
			BestScore = Score;
			ThrowableGnape = Gnape;		
		}
		return ThrowableGnape;
	}

	bool IsThreateningTreeGuardian(AHazeActor Gnape) const
	{
		if (Gnape == nullptr)
			return false;

		UTundraGnatComponent GnapeComp = UTundraGnatComponent::Get(Gnape);
		if (GnapeComp.bLatchedOn)
			return true;

		if (Gnape.ActorLocation.IsWithinDist2D(Game::Zoe.ActorLocation, GorillaSettings.SlamInsteadOfGrabAroundTreeguardianRange))
		{
			if (GnapeComp.bThrownByMonkey)			
				return false;
			if (GnapeComp.bGoBallistic)
				return false;
			UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Gnape);
			if (HealthComp.IsDead())
				return false;
			// Ready to attack tree guardian
			return true;
		}
	
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSnowMonkeyThrowGnapeParams& OutParams) const
	{
		if (ShapeShiftComponent == nullptr)
			return false;

		if(ShapeShiftComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return false;

		if(Time::GetGameTimeSince(SnowMonkeyComp.TimeOfLastGroundSlam) < GorillaSettings.GroundSlamCooldown)
			return false;

		if (!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.2))
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (MoveComp.IsInAir())
			return false;

		AHazeActor ThrowableGnape = FindGnape(GorillaSettings.GrabGnapeRange, GorillaSettings.GrabGnapeRadius, 100.0);	
		if (ThrowableGnape == nullptr)
			return false;	

		OutParams.Gnape = ThrowableGnape;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > ThrowCompleteTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSnowMonkeyThrowGnapeParams Params)
	{
		// Grab gnape in preparation of throwing
		ThrowGnapeComp.GrabbedGnape = Params.Gnape;
		ThrowGnapeComp.bThrow = false;

		UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnGroundSlamActivated(SnowMonkeyComp.SnowMonkeyActor);
		Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeyAirborneGroundSlam, this);
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		ShapeShiftComponent.AddShapeTypeBlocker(ETundraShapeshiftShape::Player, this);

		ThrowCompleteTime = BIG_NUMBER;
		ThrowLaunchTime = BIG_NUMBER;
		GrabCompleteTime = 0.3; // TOOD: Get duration of grab animation from feature
		ThrowAtRetargetTime = -1.0;
		ThrowAtTarget = nullptr;
		
		MoveDir = Player.ActorForwardVector;
		CurrentSpeed = MoveComp.HorizontalVelocity.Size();

		UPlayerFloorMotionSettings::SetMaximumSpeed(Player, GorillaSettings.GrabbedGnapeMoveSpeed, this, EHazeSettingsPriority::Gameplay);

		bReadyToThrow = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (IsValid(ThrowGnapeComp.GrabbedGnape) && HasControl())
			CrumbLaunchGnape(ThrowAtTarget); // Deactivated before releasing grabbed gnape, let fly!

		SnowMonkeyComp.TimeOfLastGroundSlam = Time::GetGameTimeSeconds();
		SnowMonkeyComp.bGroundedGroundSlamHandsHitGround = false;
		Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeyAirborneGroundSlam, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		ShapeShiftComponent.RemoveShapeTypeBlockerInstigator(this);
		SnowMonkeyComp.bCanTriggerGroundedGroundSlam = false;
		ThrowGnapeComp.GrabbedGnape = nullptr;
		ThrowGnapeComp.bThrow = false;
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStopped(ActionNames::PrimaryLevelAbility))
			bReadyToThrow = true;

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				ComposeMovement(DeltaTime);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, SnowMonkeyGnapeFeatureTags::SnowMonkeyThrowGnapeTag);
		}

		if ((ActiveDuration < ThrowLaunchTime) && (ActiveDuration > GrabCompleteTime))
		{
			if (CanRetarget())
			{
				AHazeActor NewTarget = FindGnape(GorillaSettings.ThrowGnapeRange, GorillaSettings.ThrowGnapeRadius, 60.0);
				if (NewTarget != ThrowAtTarget)
					Retarget(NewTarget);
			}

			// Should we start throw?
			if (HasControl() && bReadyToThrow && !ThrowGnapeComp.bThrow && WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, GrabCompleteTime - 0.01))
				CrumbStartThrow();
		}

		if (HasControl() && (ActiveDuration > ThrowLaunchTime))
			CrumbLaunchGnape(ThrowAtTarget);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			ShapeDebug::DrawTeardrop(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorForwardVector * (GorillaSettings.ThrowGnapeRange - GorillaSettings.ThrowGnapeRadius), 60.0, GorillaSettings.ThrowGnapeRadius);		
			if (ThrowAtTarget != nullptr && ThrowGnapeComp.GrabbedGnape != nullptr)
			{
				Debug::DrawDebugLine(Owner.FocusLocation, ThrowAtTarget.FocusLocation, FLinearColor::Red, 5.0);		
				Debug::DrawDebugLine(Owner.FocusLocation, Owner.FocusLocation + Owner.ActorForwardVector * 500.0, FLinearColor::Green, 5.0);
			}		
		}
#endif
	}

	bool CanRetarget() const
	{
		if (ActiveDuration > ThrowAtRetargetTime)
			return true;
		if (!IsValid(ThrowAtTarget))
			return true;
		FVector OwnFwd = Player.ActorForwardVector;
		FVector OwnLoc = Player.ActorLocation;
		if (OwnFwd.DotProduct((ThrowAtTarget.ActorLocation - OwnLoc).GetSafeNormal2D()) < 0.96)
			return true;
		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartThrow()
	{
		ThrowGnapeComp.bThrow = true; // This will trigger throw anim

		float AnimDuration = 0.8;
		float LaunchTime = 0.2;
		UHazeLocomotionFeatureBase Feature = SnowMonkeyComp.SnowMonkeyActor.Mesh.GetFeatureByTag(SnowMonkeyGnapeFeatureTags::SnowMonkeyThrowGnapeTag);
		ULocomotionFeatureSnowMonkeyThrowGnape ThrowGnapeFeature = Cast<ULocomotionFeatureSnowMonkeyThrowGnape>(Feature);
		if ((ThrowGnapeFeature != nullptr) && (ThrowGnapeFeature.AnimData.Throw.Sequence != nullptr))
		{
			AnimDuration = ThrowGnapeFeature.AnimData.Throw.Sequence.PlayLength;
			TArray<float32> NotifyInfo;
			if (ThrowGnapeFeature.AnimData.Throw.Sequence.GetAnimNotifyTriggerTimes(ULaunchGnapeAnimNotify, NotifyInfo) && (NotifyInfo.Num() > 0))
				LaunchTime = NotifyInfo[0]; // Gnape will be launched at this time
		}

		ThrowCompleteTime = ActiveDuration + 0.4;
		ThrowLaunchTime = ActiveDuration + LaunchTime;
	}

	void Retarget(AHazeActor Target)
	{
		if (Target != nullptr)
			ThrowAtRetargetTime = ActiveDuration + 0.8;

		if (ThrowAtTarget != nullptr)
			UTundraGnatComponent::Get(ThrowAtTarget).bTargetedByMonkeyThrow = false;	

		ThrowAtTarget = Target;	
		if (ThrowAtTarget != nullptr)
			UTundraGnatComponent::Get(ThrowAtTarget).bTargetedByMonkeyThrow = true;	
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchGnape(AHazeActor Target)
	{
		if (!IsValid(ThrowGnapeComp.GrabbedGnape))
			return; // Held gnape has been streamed out

		auto GnapeComp = UTundraGnatComponent::Get(ThrowGnapeComp.GrabbedGnape);
		GnapeComp.bThrownByMonkey = true;
		ThrowAtTarget = Target;
		GnapeComp.ThrownAtTarget = ThrowAtTarget;
		ThrowGnapeComp.GrabbedGnape = nullptr;
		ThrowLaunchTime = BIG_NUMBER;
	}

	void ComposeMovement(float DeltaTime)
	{
		// Allow some grounded movement
		FVector TargetDirection = MoveComp.MovementInput;
		float InputSize = MoveComp.MovementInput.Size();
		MoveDir = Math::VInterpConstantTo(MoveDir, TargetDirection, DeltaTime, 15.0);

		float SpeedAlpha = Math::Clamp((InputSize - FloorMotionComp.Settings.MinimumInput) / (1.0 - FloorMotionComp.Settings.MinimumInput), 0.0, 1.0);
		float TargetSpeed = FloorMotionComp.GetMovementTargetSpeed(SpeedAlpha);

		// Calculate the target speed
		TargetSpeed *= MoveComp.MovementSpeedMultiplier;

		if(InputSize < KINDA_SMALL_NUMBER)
			TargetSpeed = 0.0;
	
		// Update new velocity
		float InterpSpeed = FloorMotionComp.Settings.Acceleration * MoveComp.MovementSpeedMultiplier;
		if(TargetSpeed < CurrentSpeed)
			InterpSpeed = FloorMotionComp.Settings.Deceleration * MoveComp.MovementSpeedMultiplier;
		CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
		FVector HorizontalVelocity = MoveDir.GetSafeNormal() * CurrentSpeed;

		// While on edges, we force the player off them if they have 
		// moved to far out on the edge and are not steering out from the edge
		if(MoveComp.HasUnstableGroundContactEdge())
		{
			const FMovementEdge EdgeData = MoveComp.GroundContact.EdgeResult;
			const FVector Normal = EdgeData.EdgeNormal;
			float MoveAgainstNormal = 1 - HorizontalVelocity.GetSafeNormal().DotProduct(Normal);
			MoveAgainstNormal *= MoveDir.DotProductNormalized(Normal);
			float PushSpeed = Math::Clamp(HorizontalVelocity.Size(), FloorMotionComp.Settings.MinimumSpeed, FloorMotionComp.Settings.MaximumSpeed);
			HorizontalVelocity = Math::Lerp(HorizontalVelocity, Normal * PushSpeed, MoveAgainstNormal);
		}

		Movement.AddOwnerVerticalVelocity();
		Movement.AddGravityAcceleration();
		Movement.AddHorizontalVelocity(HorizontalVelocity);
		Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakePercentage(0.45));

		Movement.InterpRotationToTargetFacingRotation(FloorMotionComp.Settings.FacingDirectionInterpSpeed);
	}
}

class ULaunchGnapeAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "LaunchGnape";
	}
}
