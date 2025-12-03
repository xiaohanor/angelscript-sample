struct FTeenDragonTailGeckoEdgeJumpingParams
{
	FVector JumpToLocation;
	float LandingVelocityMultiplier;
}

class UTeenDragonTailGeckoEdgeJumpingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 39;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;

	UTeenDragonTailClimbableComponent CurrentClimbComp;
	UTeenDragonTailGeckoClimbSettings ClimbSettings;

	float JumpStartVerticalSpeed;
	float LandingVelocityMultiplier;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();

		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);

		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonTailGeckoEdgeJumpingParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!TailDragonComp.IsClimbing())
			return false;

		if(!TailDragonComp.bWantToJump)
			return false;

		for(auto Volume : GeckoClimbComp.EdgeJumpingVolumes)
		{
			if(GeckoClimbComp.EdgeJumpingVolumes.Num() == 0)
				return false;
		
			FVector FirstPoint = Volume.LandingLineFirstPoint.WorldLocation;
			FVector SecondPoint = Volume.LandingLineSecondPoint.WorldLocation;

			FVector BetweenLines = FirstPoint - SecondPoint;

			FVector HalfwayPoint = FirstPoint - (BetweenLines * 0.5);
			FVector DragonToHalfway = HalfwayPoint - Player.ActorLocation;
			// FVector NormalBetweenLines = BetweenLines.GetSafeNormal();

			// Is looking away
			if(Player.ActorForwardVector.DotProduct(DragonToHalfway) < 0)
				return false;

			FVector PlaneNormal = -Volume.LineRoot.UpVector;
			// FVector PlaneNormal = NormalBetweenLines.CrossProduct(GeckoClimbComp.GetClimbUpVector());
			// Edge is on other side
			if(Player.ActorForwardVector.DotProduct(PlaneNormal) > 0)
				return false;

			// Debug::DrawDebugDirectionArrow(Volume.LineRoot.WorldLocation, PlaneNormal, 500, 40, FLinearColor::Red, 20);

			FVector Intersection = Math::LinePlaneIntersection(Player.ActorLocation, 
			Player.ActorLocation + (Player.ActorForwardVector * ClimbSettings.JumpLength),
				Volume.LineRoot.WorldLocation, PlaneNormal);

			FVector LandPoint = Intersection + (PlaneNormal * Volume.EdgeLandingDistance);

			float LandPointDistSqr = Player.ActorLocation.DistSquared(LandPoint);
			// Too long jump
			if(LandPointDistSqr > Math::Square(Volume.EdgeJumpMaxDistance))
				return false;
			
			// Too short jump
			if(LandPointDistSqr < Math::Square(Volume.EdgeJumpMinDistance))
				return false;

			// OPT: Can be calculated at beginplay 
			float FirstDistSqrHalfway = FirstPoint.DistSquared(HalfwayPoint);
			float IntersectionDistSqrHalfway = Intersection.DistSquared(HalfwayPoint);

			// Intersection is not between points
			if(IntersectionDistSqrHalfway > FirstDistSqrHalfway)
				return false;

			Params.JumpToLocation = LandPoint;
			Params.LandingVelocityMultiplier = Volume.LandingVelocityMultiplier;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasGroundContact() ||
			GeckoClimbComp.bMissedGeckoJumping)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonTailGeckoEdgeJumpingParams Params)
	{
		Owner.BlockCapabilities(BlockedWhileIn::Jump, this);

		TailDragonComp.ConsumeJumpInput();
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		TailDragonComp.AnimationState.Apply(ETeenDragonAnimationState::Jump, this);

		FVector NewVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Player.ActorLocation, Params.JumpToLocation, 
			MoveComp.GravityForce, ClimbSettings.JumpHorizontalSpeed, MoveComp.WorldUp);

		Owner.SetActorVelocity(NewVelocity);

		JumpStartVerticalSpeed = Player.ActorVerticalVelocity.DotProduct(MoveComp.WorldUp);
		LandingVelocityMultiplier = Params.LandingVelocityMultiplier;

		GeckoClimbComp.bIsGeckoJumping = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BlockedWhileIn::Jump, this);		
		TailDragonComp.AnimationState.Clear(this);

		GeckoClimbComp.bIsGeckoJumping = false;

		Player.SetActorVelocity(Player.ActorVelocity * LandingVelocityMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				//Movement.AddHorizontalVelocity(TeenDragon.ActorForwardVector * ClimbSettings.JumpHorizontalSpeed);
				Movement.AddOwnerVelocity();
				// Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.InterpRotationToTargetFacingRotation(ClimbSettings.JumpTurnSpeed * MoveComp.MovementInput.Size());
			
				if (MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < -JumpStartVerticalSpeed * 1.1)
				{
					GeckoClimbComp.bMissedGeckoJumping = true;
				}

			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMove(Movement);
			TailDragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::Jump);
		}
	}
};