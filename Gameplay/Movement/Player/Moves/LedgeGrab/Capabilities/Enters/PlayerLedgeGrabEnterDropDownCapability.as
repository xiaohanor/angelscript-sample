class UPlayerLedgeGrabEnterDropDownCapability : UHazePlayerCapability
{
	/*
	 * This Move is cut/suspended until further notice, its not being used / designed for and has issues interacting with other moves unless fixed such as:
	 * - Ledge grabbing close to a ledge / Swim volume will perform some of the move then teleport into water 
	 */

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeGrab);
	default CapabilityTags.Add(PlayerLedgeGrabTags::LedgeGrabEnter);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default TickGroupSubPlacement = 1;

	UPlayerMovementComponent MoveComp;
	UPlayerLedgeGrabComponent LedgeGrabComp;
	UTeleportingMovementData Movement;

	FPlayerLedgeGrabData ActivatedData;

	// How far ahead in seconds to test for a drop
	const float AnticipationDuration = 0.25;

	const float MovementDuration = 0.4;
	const float Duration = 0.6;

	bool bMovementComplete = false;
	FVector StartLocation;
	FVector StartDirection;
	FVector ComponentRelativeTargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		LedgeGrabComp = UPlayerLedgeGrabComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerLedgeGrabData& LedgeGrabActivationData) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (MoveComp.IsInAir())
			return false;

		if (!IsActioning(ActionNames::MovementVerticalDown))
			return false;

		/*
			When the button is pressed, trace in all directions, starting with movement direction
			If the button is still held, keep checking in the direction of travel
		*/
		
		FVector TraceDirectionNorth = Owner.ActorForwardVector;
		if (!MoveComp.MovementInput.IsNearlyZero())
			TraceDirectionNorth = MoveComp.MovementInput.GetSafeNormal();
		else if (!MoveComp.HorizontalVelocity.IsNearlyZero())
			TraceDirectionNorth = MoveComp.HorizontalVelocity.GetSafeNormal();

		FPlayerLedgeGrabData LedgeGrabData;
		if (WasActionStarted(ActionNames::MovementVerticalDown))
		{			
			/*
				Using TraceDirection as north, trace around the player
				Project each trace direction onto the normal of any valid hits
				Test ledge grab in the shortest direction
			*/

			float ResultingDistance = BIG_NUMBER;
			FVector ResultingNormal = FVector::ZeroVector;
			FVector ResultingLocation = FVector::ZeroVector;

			for (int Index = 0; Index < LedgeGrabComp.DropSettings.StationaryTraceSteps; Index++ )
			{
				FVector TraceDirection = TraceDirectionNorth;
				TraceDirection = FQuat(MoveComp.WorldUp, Math::DegreesToRadians(LedgeGrabComp.DropSettings.StationaryStepAngle * Index)) * TraceDirection;

				FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(MoveComp);
				TraceSettings.UseLine();

				FVector TraceEndLocation = Player.ActorLocation + (MoveComp.WorldUp * LedgeGrabComp.DropSettings.StationaryTraceHeightFromPlayer);
				FVector TraceStartLocation = TraceEndLocation + TraceDirection * LedgeGrabComp.DropSettings.StationaryDropDistance;
				FHitResult Hit = TraceSettings.QueryTraceSingle(TraceStartLocation, TraceEndLocation);

				if (!Hit.bBlockingHit)
					continue;
				if (Hit.bStartPenetrating)
					continue;
				const float WorldUpAngularDistance = Math::RadiansToDegrees(MoveComp.WorldUp.AngularDistance(Hit.ImpactNormal));
				if (!Math::IsNearlyEqual(WorldUpAngularDistance, 90.0, LedgeGrabComp.WallSettings.TopRollMaximum))
					continue;

				const FVector ToHit = Hit.ImpactPoint - TraceEndLocation;
				const float Distance = ToHit.DotProduct(Hit.ImpactNormal);

				if (Distance < ResultingDistance)
				{
					ResultingDistance = Distance;
					ResultingNormal = Hit.ImpactNormal;
					ResultingLocation = Hit.ImpactPoint;
				}
			}

			if (ResultingNormal.IsNearlyZero())
				return false;

			LedgeGrabComp.TraceForLedgeGrabAtLocation(Player, -ResultingNormal, ResultingLocation + (ResultingNormal * 50.0) - (MoveComp.WorldUp * 100.0), LedgeGrabData, this, IsDebugActive(), 50.0);		
		}
		else
		{
			//If holding then trace for slide dropdown

			//TODO [AL] following / inherited velocity will affect this, need to separate player local velocity and not inherited and use that to determine if we are "moving" (If we are keeping slide into drop)
			FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
			if (HorizontalVelocity.IsNearlyZero())
				return false;

			if (MoveComp.HasGroundContact())
				HorizontalVelocity = HorizontalVelocity.ConstrainToSlope(MoveComp.GroundContact.ImpactNormal, MoveComp.WorldUp);
			HorizontalVelocity *= AnticipationDuration;

			FVector TraceLocation = Player.ActorLocation;
			TraceLocation -= MoveComp.WorldUp * 120.0;
			TraceLocation += HorizontalVelocity;
			if (!LedgeGrabComp.TraceForLedgeGrabAtLocation(Player, -HorizontalVelocity.GetSafeNormal(), TraceLocation, LedgeGrabData, this, IsDebugActive(), HorizontalVelocity.Size()))
				return false;
			
			// const FVector ToEdge = LedgeGrabData.LedgeLocation - Player.ActorLocation;
			// const float TimeToEdge = ToEdge.Size() / HorizontalVelocity.Size();
			// const float TimeSkip = AnticipationDuration - TimeToEdge;

		}	
		if (!LedgeGrabData.HasValidData())
			return false;

		// if(LedgeGrabData.HitComponents)

		LedgeGrabActivationData = LedgeGrabData;
  		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if (bMovementComplete)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerLedgeGrabData LedgeGrabActivationData)
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeGrab, this);

		LedgeGrabComp.SetState(EPlayerLedgeGrabState::EnterDrop);

		bMovementComplete = false;
		StartLocation = Player.ActorLocation;
		StartDirection = Player.ActorForwardVector;

		LedgeGrabComp.AnimData.bEnterDropTurnRight = LedgeGrabActivationData.WallRotation.ForwardVector.DotProduct(Player.ActorRightVector) < 0.0;
		MoveComp.FollowComponentMovement(LedgeGrabActivationData.FollowComponent, this);
		ComponentRelativeTargetLocation = LedgeGrabActivationData.ComponentRelativePlayerLocation;

		LedgeGrabComp.Data = LedgeGrabActivationData;
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		//Temp fix for data being tainted during runtime causing origo teleporting [AL]
		ActivatedData = LedgeGrabActivationData;

		LedgeGrabComp.AnimData.bEnterDropTurnRight = LedgeGrabActivationData.WallRotation.ForwardVector.DotProduct(Player.ActorRightVector) < 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeGrab, this);
		MoveComp.UnFollowComponentMovement(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if (ActiveDuration > Duration && !bMovementComplete)
		{
			bMovementComplete = true;

			//Perform a new LedgeGrabTrace prior to deactivation as we want up to date data for activations from other capabilities.
			FPlayerLedgeGrabData Data;
			if(LedgeGrabComp.TraceForLedgeGrab(Player, -LedgeGrabComp.Data.WallImpactNormal, Data, this, IsDebugActive()))
			{
				LedgeGrabComp.Data = Data;
			}
			//No valid grab location was detected so clear data = Cancel grab.
			else
				LedgeGrabComp.Data.Reset();
		}

		const float MovePercentage = Math::Min(ActiveDuration / MovementDuration, 1.0);
		FVector TargetLocation = ActivatedData.FollowComponent.WorldTransform.TransformPosition(ComponentRelativeTargetLocation);
		FVector NewLocation = Math::Lerp(StartLocation, TargetLocation, MovePercentage);
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLocation, FVector::ZeroVector);

		FVector NewDirection = StartDirection.SlerpVectorTowardsAroundAxis(-LedgeGrabComp.Data.WallRotation.ForwardVector, MoveComp.WorldUp, MovePercentage);
		FQuat NewRotation = FQuat::MakeFromXZ(NewDirection, MoveComp.WorldUp);
		Movement.SetRotation(NewRotation);		

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"LedgeGrab");
	}
}