
enum EPlayerGravityWellGuidanceType
{
	FallingInto,
}

enum EPlayerGravityWellGuidanceRelationType
{
	Individual,
	RelativeToOtherPlayer
}

struct FPlayerGravityWellGuidanceActivationParams
{
	UPROPERTY(EditAnywhere)
	EPlayerGravityWellGuidanceType GuidanceType = EPlayerGravityWellGuidanceType::FallingInto;

	/** Clamp the distance along the spline for the enter */
	UPROPERTY(EditAnywhere)
	float MinDistanceAlongSplineForEnter = -1;

	/** Clamp the distance along the spline for the enter */
	UPROPERTY(EditAnywhere)
	float MaxDistanceAlongSplineForEnter = -1;

	/** How the player will guid her self or the other player to the spline */
	UPROPERTY(EditAnywhere)
	EPlayerGravityWellGuidanceRelationType GuidanceRelationShipType = EPlayerGravityWellGuidanceRelationType::Individual;

	/** Trying to keep a distance to the other player when entering */
	UPROPERTY(EditAnywhere, meta = (EditCondition="GuidanceRelationShipType == EPlayerGravityWellGuidanceRelationType::RelativeToOtherPlayer"))
	float DistanceAlongSplineToOtherPlayerWhenEnter = 0;
}


class UPlayerGravityWellEnterGuidanceCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::GravityWell);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunMovement);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 3;

	UPlayerMovementComponent MoveComp;
	UPlayerGravityWellComponent GravityWellComp;
	UGravityWellMovementData Movement;
	UPlayerAirMotionComponent AirMotionComp;
	bool bDoneMoving = false;
	float ActivationVerticalDistance = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		GravityWellComp = UPlayerGravityWellComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UGravityWellMovementData);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerGravityWellActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (GravityWellComp.GuidedEnterWell == nullptr)
			return false;

		ActivationParams.GravityWell = GravityWellComp.GuidedEnterWell;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (GravityWellComp.GuidedEnterWell == nullptr)
			return true;

		if(bDoneMoving)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerGravityWellActivationParams ActivationParams)
	{
		GravityWellComp.GuidedEnterWell = ActivationParams.GravityWell;
		MoveComp.OverrideResolver(UGravityWellMovementResolver, this, EInstigatePriority::Normal);
		Player.BlockCapabilities(BlockedWhileIn::GravityWell, this);
		ActivationVerticalDistance = -1;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearResolverOverride(UGravityWellMovementResolver, this);
		Player.ClearSettingsByInstigator(this);
		Player.UnblockCapabilities(BlockedWhileIn::GravityWell, this);
		bDoneMoving = false;
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(GravityWellComp.GuidanceSettings.GuidanceType == EPlayerGravityWellGuidanceType::FallingInto)
				{
					UpdateFallingGuidance(DeltaTime);
				}	
				else
				{
					check(false); // Not implemented
				}	
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
			}	
		}		
	}

	void UpdateFallingGuidance(float DeltaTime)
	{
		// Init the movement data
		Movement.CurrentSplinePosition = GravityWellComp.GuidedEnterWell.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorCenterLocation);
		Movement.MaxDistance = GravityWellComp.Settings.Radius - GravityWellComp.Settings.LockPlayerMargin;

		const float TargetMovementSpeed = 500 * MoveComp.MovementSpeedMultiplier;

		float InterpSpeed;
		if(MoveComp.HorizontalVelocity.Size() > TargetMovementSpeed)
			InterpSpeed = 450.0;
		else
			InterpSpeed = Math::Lerp(450.0, 1500.0, MoveComp.MovementInput.Size());

		FVector TargetVelocity = MoveComp.MovementInput * TargetMovementSpeed;
		FVector HorizontalVelocity = Math::VInterpTo(MoveComp.HorizontalVelocity, TargetVelocity, DeltaTime, 2.0);

		FVector UnguidedDelta = HorizontalVelocity * DeltaTime;
		UnguidedDelta += MoveComp.VerticalVelocity * DeltaTime;
		UnguidedDelta += MoveComp.GetGravity() * Math::Square(DeltaTime);

		// Apply potential clamps to the guided distance
		{
			if(GravityWellComp.GuidanceSettings.MinDistanceAlongSplineForEnter >= 0 
				&& Movement.CurrentSplinePosition.CurrentSplineDistance < GravityWellComp.GuidanceSettings.MinDistanceAlongSplineForEnter)
			{
				float Diff = GravityWellComp.GuidanceSettings.MinDistanceAlongSplineForEnter - Movement.CurrentSplinePosition.CurrentSplineDistance;
				Movement.CurrentSplinePosition.Move(Diff);
			}

			if(GravityWellComp.GuidanceSettings.MaxDistanceAlongSplineForEnter >= 0 
				&& Movement.CurrentSplinePosition.CurrentSplineDistance > GravityWellComp.GuidanceSettings.MaxDistanceAlongSplineForEnter)
			{
				float Diff = GravityWellComp.GuidanceSettings.MaxDistanceAlongSplineForEnter - Movement.CurrentSplinePosition.CurrentSplineDistance;
				Movement.CurrentSplinePosition.Move(Diff);
			}

			if(GravityWellComp.GuidanceSettings.GuidanceRelationShipType == EPlayerGravityWellGuidanceRelationType::RelativeToOtherPlayer)		
			{
				auto OtherGravityWellComp = UPlayerGravityWellComponent::Get(Player.GetOtherPlayer());
				if(OtherGravityWellComp.GuidedEnterWell == GravityWellComp.GuidedEnterWell 
					&& OtherGravityWellComp.GetLastUpdatedDistanceFrameNumber() + 1 >= Time::FrameNumber)
				{
					Movement.CurrentSplinePosition = OtherGravityWellComp.GuidedEnterWell.Spline.GetSplinePositionAtSplineDistance(OtherGravityWellComp.DistanceAlongSpline);
					Movement.CurrentSplinePosition.Move(GravityWellComp.GuidanceSettings.DistanceAlongSplineToOtherPlayerWhenEnter);
				}
			}
		}

		GravityWellComp.UpdateDistanceAlongSpline(Movement.CurrentSplinePosition.CurrentSplineDistance); 

		float CurrentVerticalDistance = Player.ActorLocation.ProjectOnToNormal(MoveComp.WorldUp).Distance(Movement.CurrentSplinePosition.WorldLocation.ProjectOnToNormal(MoveComp.WorldUp));
		if(ActivationVerticalDistance < 0)
		{
			ActivationVerticalDistance = Math::Max(CurrentVerticalDistance, 1.0);
		}
		
		const float GuidAlpha = 1.0 - Math::Min(CurrentVerticalDistance / ActivationVerticalDistance, 1.0);
	
		FVector BonusOffset = Math::Lerp(UnguidedDelta, FVector::ZeroVector, GuidAlpha);
		FVector GuidedLocation = Math::VInterpTo(Player.ActorLocation, Movement.CurrentSplinePosition.WorldLocation + BonusOffset, DeltaTime, 20.0);
		FVector UnguidedLocation = Player.ActorLocation + UnguidedDelta;

		FVector FinalLocation = Math::Lerp(UnguidedLocation, GuidedLocation,  Math::EaseIn(0.0, 1.0, GuidAlpha, 1.5));
		Movement.AddDelta((FinalLocation - Player.ActorLocation).VectorPlaneProject(MoveComp.WorldUp));
		Movement.AddDelta(UnguidedDelta.ProjectOnToNormal(MoveComp.WorldUp));
			
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		GravityWellComp.UpdateDistanceAlongSpline(Movement.CurrentSplinePosition.CurrentSplineDistance);
		if(Player.ActorLocation.DistSquared(Movement.CurrentSplinePosition.WorldLocation) < Math::Square(Movement.MaxDistance - 1))
		{
			bDoneMoving = true;		
		}
	}
};