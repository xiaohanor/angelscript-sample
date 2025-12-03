class UTundraPlayerSnowMonkeyTriggerCeilingClimbAnimationCapability: UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyCeilingClimb);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkey);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 23;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	float CurrentDistanceToCeiling = -1;
	bool bWithinBoundsOfACeiling = false;

	UTundraPlayerSnowMonkeyCeilingClimbComponent CurrentCeiling;
	UPlayerMovementComponent MoveComp;
	UTundraPlayerSnowMonkeyCeilingClimbDataComponent CeilingClimbDataComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UTundraPlayerShapeshiftingComponent ShapeShiftComp;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	UTundraPlayerSnowMonkeySettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		CeilingClimbDataComp = UTundraPlayerSnowMonkeyCeilingClimbDataComponent::GetOrCreate(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
		ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		Settings = UTundraPlayerSnowMonkeySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		CalculateDistanceToCeiling();
#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("Current Ceiling", CurrentCeiling)
			.Value("bWithinBoundsOfACeiling", bWithinBoundsOfACeiling)
			.Value("Distance To Ceiling", CurrentDistanceToCeiling)
		;
#endif
	}

	void CalculateDistanceToCeiling()
	{
		FTundraPlayerSnowMonkeyCeilingData NewCeiling;
		bWithinBoundsOfACeiling = CeilingClimbDataComp.IsSnowMonkeyWithinDistanceToCeiling(NewCeiling, Settings.CeilingClimbAnimationTriggerDistance);
		if(NewCeiling.ClimbComp != nullptr)
		{
			const float HorizontalDistance = NewCeiling.GetHorizontalDistanceToCeiling(TopOfPlayerCapsule);
 			if(HorizontalDistance > 0)
			{
				CurrentDistanceToCeiling = -1;
				return;
			}

			CurrentCeiling = NewCeiling.ClimbComp;
		}

		if(CurrentCeiling != nullptr)
		{
			FVector ClosestPoint;
			FTundraPlayerSnowMonkeyCeilingData Data = CurrentCeiling.GetCeilingData();
			CurrentDistanceToCeiling = Data.GetDistanceToCeiling(TopOfPlayerCapsule, ClosestPoint);
#if !RELEASE
			TEMPORAL_LOG(this).Point("Closest Point", ClosestPoint);
#endif

			const float HorizontalDistance = Data.GetHorizontalDistanceToCeiling(TopOfPlayerCapsule, ClosestPoint);
#if !RELEASE
			TEMPORAL_LOG(this).Point("Closest Point", ClosestPoint);
			TEMPORAL_LOG(this).Value("Horizontal Distance", HorizontalDistance);
#endif
 			if(HorizontalDistance > 0)
			{
				CurrentDistanceToCeiling = -1;
				return;
			}	
		}
		else
		{
			CurrentDistanceToCeiling = -1;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerSnowMonkeyCeilingMovementActivation& Params) const
	{			
		if(DeactiveDuration < 0.5)
		{
			TemporalLogActivation("DeactiveDuration < 0.5");
			return false;
		}

		if(!ShapeShiftComp.IsBigShape())
		{
			TemporalLogActivation("We aren't big shape!");
			return false;
		}

		if(MoveComp.HasGroundContact())
		{
			TemporalLogActivation("We are grounded");
			return false;
		}

		if(MoveComp.HasCeilingContact())
		{
			TemporalLogActivation("We have ceiling contact");
			return false;
		}

		if(PoleClimbComp.IsClimbing())
		{
			TemporalLogActivation("We are climbing on a pole");
			return false;
		}

		if(MoveComp.VerticalSpeed <= 0)
		{
			TemporalLogActivation("We are falling");
			return false;
		}

		if(CurrentDistanceToCeiling < 0.0)
		{
			TemporalLogActivation("Distance to ceiling is negative");
			return false;
		}

		if(SnowMonkeyComp.bJustCeilingClimbed)
		{
			TemporalLogActivation("We just ceiling climbed");
			return false;
		}

		if(CurrentDistanceToCeiling > Settings.CeilingClimbAnimationTriggerDistance)
		{
			TemporalLogActivation("Distance to ceiling is above CeilingClimbAnimationTriggerDistance");
			return false;
		}

		float DistanceToEnterCeiling = CurrentDistanceToCeiling;
		if(CurrentCeiling.bAllowCoyoteSuckUp)
			DistanceToEnterCeiling -= Settings.CeilingSuckupMaxVerticalDistance;

		float MaxHeight = Acceleration::GetMaxHeight(MoveComp.VerticalSpeed, MoveComp.GravityForce);

		// Don't activate if the current vertical speed wont reach the ceiling or the suckup distance (if ceiling uses suckup)
		if(DistanceToEnterCeiling > MaxHeight)
		{
			TemporalLogActivation("We wont reach the ceiling");
			return false;
		}
		
		Params.CurrentCeilingComponent = CurrentCeiling;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraPlayerSnowMonkeyCeilingMovementDeactivatedParams& Params) const
	{	
		if(ShapeShiftComp.CurrentShapeType != ETundraShapeshiftShape::Big)
		{
			TemporalLogDeactivation("We aren't big shape");
			return true;
		}

		if(MoveComp.HasMovedThisFrame())
		{
			TemporalLogDeactivation("We have moved this frame");
			return true;
		}

		if(WasActionStarted(ActionNames::Cancel))
		{
			TemporalLogDeactivation("We pressed cancel");
			return true;
		}

		if(ActiveDuration > 0.5 && WasActionStarted(ActionNames::MovementJump))
		{
			TemporalLogDeactivation("We pressed jump");
			Params.bWithJumpOffForce = true;
			return true;
		}

		if(MoveComp.VerticalSpeed <= 0)
		{
			TemporalLogDeactivation("We are falling");
			return true;
		}

		if(MoveComp.HasGroundContact())
		{
			TemporalLogDeactivation("We are grounded");
			return true;
		}

		if(CurrentDistanceToCeiling > Settings.CeilingClimbAnimationTriggerDistance)
		{
			TemporalLogDeactivation("Distance to ceiling is above CeilingClimbAnimationTriggerDistance");
			return true;
		}

		if(MoveComp.HasCeilingContact())
		{
			TemporalLogDeactivation("We have ceiling contact");
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerSnowMonkeyCeilingMovementActivation Params)
	{
		SnowMonkeyComp.CurrentAnimationCeilingComponent = Params.CurrentCeilingComponent;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraPlayerSnowMonkeyCeilingMovementDeactivatedParams Params)
	{
		CurrentDistanceToCeiling = -1;
		SnowMonkeyComp.CurrentAnimationCeilingComponent = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.Mesh.RequestLocomotion(n"SnowMonkeyCeiling", this);
	}

	void TemporalLogActivation(FString Reason) const
	{
#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("Not Activated Reason", Reason)
		;
#endif
	}

	void TemporalLogDeactivation(FString Reason) const
	{
#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("Deactivation Reason", Reason)
		;
#endif
	}

	FVector GetTopOfPlayerCapsule() const property
	{
		return Player.ActorLocation + FVector::UpVector * TundraShapeshiftingStatics::SnowMonkeyCollisionSize.Y * 2.0;
	}
}