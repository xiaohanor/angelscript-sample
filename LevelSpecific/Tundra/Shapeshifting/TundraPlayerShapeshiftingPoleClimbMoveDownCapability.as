class UTundraPlayerShapeshiftingPoleClimbMoveDownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::Shapeshifting);
	default CapabilityTags.Add(TundraShapeshiftingTags::ShapeshiftingActivation);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 1;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerPoleClimbComponent PoleClimbComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;

	const float LerpDuration = 0.3;

	APoleClimbActor CurrentPole;
	float TotalMoveDownDistance;
	float AccumulatedDistance = 0.0;
	bool bMoveDone = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	}

	// Auto shapeshift to debug specific case (hard to reproduce input)
	// UFUNCTION(BlueprintOverride)
	// void OnLogState(FTemporalLog TemporalLog)
	// {
	// 	TemporalLog.Value("Height", PoleClimbComp.Data.CurrentHeight);
	// 	if(Player.IsMio() && PoleClimbComp.Data.ActivePole != nullptr)
	// 	{
	// 		if(PoleClimbComp.Data.ActivePole.ActorUpVector.DotProduct(MoveComp.WorldUp) > 0.0 && PoleClimbComp.Data.CurrentHeight < 770)
	// 			return;

	// 		if(PoleClimbComp.Data.ActivePole.ActorUpVector.DotProduct(MoveComp.WorldUp) < 0.0 && PoleClimbComp.Data.CurrentHeight > 402)
	// 			return;

	// 		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big);
	// 	}
	// }

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerShapeshiftingPoleClimbMoveDownActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(PoleClimbComp.Data.ActivePole == nullptr)
			return false;

		if(ShapeshiftingComp.FrameOfLastShapeshift == 0)
			return false;

		uint FrameDiff = Time::FrameNumber - ShapeshiftingComp.FrameOfLastShapeshift;
		if(FrameDiff > 2)
			return false;

		FVector2D CapsuleSizeDelta;
		if(!ShapeshiftingComp.IsCurrentShapeCapsuleBigger(CapsuleSizeDelta, false, true))
			return false;
		float HeightDelta = CapsuleSizeDelta.Y * 2.0;


		if(PoleClimbComp.Data.ActivePole.ActorUpVector.DotProduct(MoveComp.WorldUp) > 0.0) // Right side up poles
		{
			float Height = PoleClimbComp.Data.CurrentHeight + HeightDelta;
			if(Height <= PoleClimbComp.Data.MaxHeight)
				return false;

			Params.MoveDownDistance = Height - PoleClimbComp.Data.MaxHeight;

			// Since frame diff is over 1 the min/max height is updated to be the new shape's specific min/max height so remove the height delta since this has already been taken into account!
			if(FrameDiff == 2)
				Params.MoveDownDistance -= HeightDelta;
		}
		else // Upside down poles
		{
			float Height = PoleClimbComp.Data.CurrentHeight - HeightDelta;
			if(Height >= PoleClimbComp.Data.MinHeight)
				return false;

			Params.MoveDownDistance = PoleClimbComp.Data.MinHeight - Height;

			// Since frame diff is over 1 the min/max height is updated to be the new shape's specific min/max height so remove the height delta since this has already been taken into account!
			if(FrameDiff == 2)
				Params.MoveDownDistance -= HeightDelta;
		}

		Params.CurrentPole = PoleClimbComp.Data.ActivePole;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(bMoveDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerShapeshiftingPoleClimbMoveDownActivatedParams Params)
	{
		bMoveDone = false;
		AccumulatedDistance = 0.0;
		CurrentPole = Params.CurrentPole;
		TotalMoveDownDistance = Params.MoveDownDistance + ShapeshiftingComp.GetPoleClimbMaxHeightOffsetForShape(ShapeshiftingComp.CurrentShapeType);
		MoveComp.FollowComponentMovement(CurrentPole.RootComp, this);
		MoveComp.ApplyCrumbSyncedRelativePosition(this, CurrentPole.RootComp);

		Player.BlockCapabilities(PlayerMovementTags::PoleClimb, this);
		// Set the active pole because the sound def (that plays when the pole climb feature is requested needs to get the phys material from it)
		PoleClimbComp.Data.ActivePole = CurrentPole;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearCrumbSyncedRelativePosition(this);
		Player.UnblockCapabilities(PlayerMovementTags::PoleClimb, this);
		PoleClimbComp.StopClimbing();
		PoleClimbComp.ForceEnterPole(CurrentPole, nullptr, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float Alpha = Math::Saturate(ActiveDuration / LerpDuration);
				if(Math::IsNearlyEqual(Alpha, 1.0))
				{
					Alpha = 1.0;
					bMoveDone = true;
				}

				float NewAccumulatedDistance = Math::EaseInOut(0.0, TotalMoveDownDistance, Alpha, 2.0);
				float Delta = NewAccumulatedDistance - AccumulatedDistance;
				Movement.AddDelta(-MoveComp.WorldUp * Delta);

				AccumulatedDistance = NewAccumulatedDistance;
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"PoleClimb");
		}
	}
}

struct FTundraPlayerShapeshiftingPoleClimbMoveDownActivatedParams
{
	float MoveDownDistance;
	APoleClimbActor CurrentPole;
}