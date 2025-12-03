
class USnowMonkeyLedgeGrabCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeGrab);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMovement);
	default CapabilityTags.Add(PlayerLedgeGrabTags::LedgeGrabShimmy);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default TickGroupSubPlacement = 15;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	USnowMonkeyLedgeGrabComponent LedgeGrabComp;

	// float ShimmySpeed = 0.0;
	bool bReachedAcceleratedLocation = false;
	bool bSnappedOffset = false;

	//Accelerated Vector offset between player location on activation and traced player location
	FHazeAcceleratedVector AcceleratedLedgeOffset;
	FVector RelativePlayerLocation;

	UPrimitiveComponent CurrentlyFollowedComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		LedgeGrabComp = USnowMonkeyLedgeGrabComponent::GetOrCreate(Player);
	}

	// Commented out because the TraceForLedgeGrab will reset the ledge grab data which will make the monkey be rotated towards world forward if not hitting anything during the ledge grab.
	// UFUNCTION(BlueprintOverride)
	// void PreTick(float DeltaTime)
	// {
	// 	if(IsActive() && HasControl())
	// 	{
	// 		FSnowMonkeyLedgeGrabData LedgeGrabData;
	// 		LedgeGrabComp.TraceForLedgeGrabAtLocation(Player, -LedgeGrabComp.Data.WallImpactNormal.ConstrainToPlane(MoveComp.WorldUp), Player.ActorLocation, LedgeGrabData, IsDebugActive());
	// 		LedgeGrabComp.Data = LedgeGrabData;
	// 	}
	// }

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSnowMonkeyLedgeGrabData& LedgeGrabActivationData) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!LedgeGrabComp.Data.HasValidData())
			return false;
		
		// Just be absolutely sure that the enter data is the same on both sides
		LedgeGrabActivationData = LedgeGrabComp.Data;
  		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!LedgeGrabComp.Data.HasValidData())
			return true;
		
		if (LedgeGrabComp.State != ESnowMonkeyLedgeGrabState::LedgeGrab)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSnowMonkeyLedgeGrabData LedgeGrabActivationData)
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeGrab, this);

		// if(LedgeGrabComp.GetState() != ESnowMonkeyLedgeGrabState::Dash)
		// {
			//If we didnt enter from dash then we should initiate settling into the correct location
			bReachedAcceleratedLocation = false;
			FVector PlayerLedgeOffset = Player.ActorLocation - LedgeGrabActivationData.PlayerLocation;
			AcceleratedLedgeOffset.SnapTo(PlayerLedgeOffset, MoveComp.Velocity);
		// }
		// else
		// {
		// 	//We came from dash so blend out from dash into our correct shimmy velocity
		// 	ShimmySpeed = Math::Clamp(MoveComp.GetHorizontalVelocity().Size(), LedgeGrabComp.Settings.ShimmySpeedMin, 500.0);
		// 	ShimmySpeed = ShimmySpeed * LedgeGrabComp.DashDirectionSign;
		// }

		LedgeGrabComp.SetState(ESnowMonkeyLedgeGrabState::LedgeGrab);
		LedgeGrabComp.Data = LedgeGrabActivationData;

		//Assign a primitive to follow and set our relative location offset to make sure we align correctly with moving objects.
		MoveComp.FollowComponentMovement(LedgeGrabComp.Data.FollowComponent, this);
		CurrentlyFollowedComponent = LedgeGrabComp.Data.FollowComponent;
		RelativePlayerLocation = LedgeGrabComp.Data.ComponentRelativePlayerLocation;

		//We successfully entered LedgeGrab, Reset relevant mobility options
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		UCameraSettings::GetSettings(Player).PivotLagAccelerationDuration.Apply(FVector(0.5, 0.5, 0.5), LedgeGrabComp);
		UCameraSettings::GetSettings(Player).PivotLagMax.Apply(FVector(UCameraSettings::GetSettings(Player).PivotLagMax.Value.X,UCameraSettings::GetSettings(Player).PivotLagMax.Value.Y, 0), LedgeGrabComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeGrab, this);

		// ShimmySpeed = 0.0;

		//Unfollow whichever component this capability has set to follow
		MoveComp.UnFollowComponentMovement(this);

		if (LedgeGrabComp.State == ESnowMonkeyLedgeGrabState::LedgeGrab)
			LedgeGrabComp.ResetLedgeGrab();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				//Shimmy Along ledge
				// FVector MoveInput = LedgeGrabComp.Data.LedgeRightVector * GetAttributeFloat(AttributeNames::MoveRight);
				// MoveInput = MoveInput.ConstrainToDirection(LedgeGrabComp.Data.LedgeRightVector);
				
				// const float DeadzoneSize = 0.4;			
				// if (MoveInput.Size() < DeadzoneSize)
				// 	MoveInput = FVector::ZeroVector;

				// // Normalize the move speed between 0 and 1
				// const float MoveAlpha = Math::Clamp((MoveInput.Size() - DeadzoneSize) / (1.0 - DeadzoneSize), 0.0, 1.0);
				// const float MoveDirection = Math::Sign(MoveInput.DotProduct(Owner.ActorRightVector));
				// const float TargetSpeed = Math::Lerp(LedgeGrabComp.Settings.ShimmySpeedMin, LedgeGrabComp.Settings.ShimmySpeedMax, MoveAlpha) * MoveDirection;
				// ShimmySpeed = Math::FInterpConstantTo(ShimmySpeed, TargetSpeed, DeltaTime, 1600.0);

				// // Convert actual speed into DeadzoneSize -> 1.0
				// FVector ShimmyVelocity;
				// FVector ShimmyDelta;			

				// if(LedgeGrabComp.Settings.bShimmyAllowed)
				// {
				// 	ShimmyVelocity = LedgeGrabComp.Data.LedgeRightVector * ShimmySpeed;
				// 	ShimmyDelta = ShimmyVelocity * DeltaTime;	
				// }

				// Test how far the ledge continues in the shimmy direction
				// FHazeTraceSettings ShimmyTraceSettings = Trace::InitProfile(n"PlayerCharacter");
				// ShimmyTraceSettings.UseLine();
				// {
					// if (IsDebugActive())
					// 	ShimmyTraceSettings.DebugDrawOneFrame();
						
					// FVector ShimmyTraceEnd = LedgeGrabComp.Data.LedgeLocation;
					// ShimmyTraceEnd -= LedgeGrabComp.Data.WallImpactNormal * LedgeGrabComp.Settings.TopTraceDepth;
					// ShimmyTraceEnd -= MoveComp.WorldUp * 24.0;
					// ShimmyTraceEnd += ShimmyDelta.GetSafeNormal() * Player.CapsuleComponent.CapsuleRadius;
					// ShimmyTraceEnd += ShimmyDelta;

					//FVector ShimmyTraceStart = ShimmyTraceEnd - ShimmyDelta;

					//FHitResult ShimmyHit = ShimmyTraceSettings.QueryTraceSingle(ShimmyTraceStart, ShimmyTraceEnd);
					
					//if (!ShimmyHit.bBlockingHit)
					
					
					// if (ShimmyHit.bBlockingHit && !ShimmyHit.bStartPenetrating)
					// {
					// 	//Debug::DrawDebugLine(Owner.ActorCenterLocation, Owner.ActorCenterLocation + ShimmyHit.ImpactNormal * 500.0, FLinearColor::Green, 3, 5.0);
					// 	if (!ShimmyHit.bStartPenetrating)
					// 	{
					// 		FVector ToImpactPoint = ShimmyHit.ImpactPoint - ShimmyTraceEnd;
					// 		ShimmyDelta = MoveInput.GetSafeNormal() * ToImpactPoint.Size();

					// 		ShimmySpeed = 0.0;
					// 	}
					// }
					// else
					// {
					// 	// ShimmyDelta = FVector::ZeroVector;
					// 	// ShimmyTraceEnd = FVector::ZeroVector;
					// 	// LedgeGrabComp.AnimData.ShimmyScale = 0.0;
					// 	// ShimmySpeed = 0.0;
					// }				
				// }

				// FVector ShimmyDeltaMove;
				// FSnowMonkeyLedgeGrabData LedgeGrabData;

				//Once we have settled into ledgegrab
				// if(bReachedAcceleratedLocation)
				// {
				// 	//Trace for updated ledge information at player location + Shimmy translation
				// 	if(LedgeGrabComp.TraceForLedgeGrabAtLocation(Player, -LedgeGrabComp.Data.WallImpactNormal.ConstrainToPlane(MoveComp.WorldUp), Player.ActorLocation + ShimmyDelta, LedgeGrabData, IsDebugActive()))
				// 	{
				// 		//Assign new trace data to Component
				// 		LedgeGrabComp.Data = LedgeGrabData;

				// 		ShimmyDeltaMove = (LedgeGrabComp.Data.PlayerLocation) - Player.ActorLocation;
				// 		Movement.AddDelta(ShimmyDeltaMove);

				// 		if(ShimmyDelta.IsNearlyZero())
				// 			LedgeGrabComp.AnimData.ShimmyScale = 0.0;
				// 		else
				// 		{
				// 			LedgeGrabComp.AnimData.ShimmyScale = (ShimmyDeltaMove.ConstrainToDirection(LedgeGrabComp.Data.LedgeRightVector) / DeltaTime).Size();
				// 			LedgeGrabComp.AnimData.ShimmyScale = Math::Abs(LedgeGrabComp.AnimData.ShimmyScale) / (LedgeGrabComp.Settings.ShimmySpeedMax - LedgeGrabComp.Settings.ShimmySpeedMin);
				// 			LedgeGrabComp.AnimData.ShimmyScale = Math::Clamp(LedgeGrabComp.AnimData.ShimmyScale, 0.0, 1.0);
				// 			LedgeGrabComp.AnimData.ShimmyScale *= Math::Sign(ShimmyDeltaMove.DotProduct(LedgeGrabComp.Data.LedgeRightVector));
				// 		}
				// 	}
				// }

				// Ease into ledge grab position
				//TODO [AL]: We might want a smoother transition into shimmying (allowing / Recalculating offset to include the shimmy target = Easing into a position offset by input and going directly into shimmy)
				if (!AcceleratedLedgeOffset.Value.IsNearlyZero(SMALL_NUMBER))
				{
					AcceleratedLedgeOffset.AccelerateTo(FVector::ZeroVector, 0.1, DeltaTime);

					// FVector PlayerLedgeOffset = Player.ActorLocation - LedgeGrabComp.Data.PlayerLocation;	
					// FVector LedgeOffsetDelta = AcceleratedLedgeOffset.Value - PlayerLedgeOffset - ShimmyDeltaMove;

					//Convert the Relative Player Location to world space to make sure we are offseting correctly on moving targets
					FVector TransformedPlayerLocation = LedgeGrabComp.Data.FollowComponent.WorldTransform.TransformPosition(RelativePlayerLocation);
					FVector PlayerLedgeOffset = Player.ActorLocation - TransformedPlayerLocation;
					FVector LedgeOffsetDelta = AcceleratedLedgeOffset.Value - PlayerLedgeOffset;
					Movement.AddDeltaWithCustomVelocity(LedgeOffsetDelta, FVector::ZeroVector);
				}
				else if	(!bReachedAcceleratedLocation)
					bReachedAcceleratedLocation = true;
			
				if (IsDebugActive())
				{
					// Debug::DrawDebugLine(LedgeGrabComp.Data.LedgeLocation, LedgeGrabComp.Data.LedgeLocation + (MoveInput * 100.0), FLinearColor::Purple, 3.0, 0.0);
					Debug::DrawDebugCoordinateSystem(LedgeGrabComp.Data.LedgeLocation, LedgeGrabComp.Data.LedgeRotation, 100.0, 2.0, 0.0);

					// PrintToScreenScaled("MoveAlpha: " + MoveAlpha, 0.0, FLinearColor::Green, Scale = 0);
					// PrintToScreenScaled("ShimmySpeed: " + ShimmySpeed, 0.0, FLinearColor::Green, Scale = 0);
					// PrintToScreenScaled("TargetSpeed: " + TargetSpeed, 0.0, FLinearColor::Green, Scale = 0);
					// PrintToScreenScaled("[Shimmy]", 0.0, FLinearColor(1.0, 0.5, 0.0), 0);
				}

				//Verify Currently followed comp (Should this be done in the Component for easy access from other capabilities? [AL])
				if (CurrentlyFollowedComponent != LedgeGrabComp.Data.FollowComponent)
				{
					MoveComp.UnFollowComponentMovement(this);
					MoveComp.FollowComponentMovement(LedgeGrabComp.Data.FollowComponent, this);
				}

				LedgeGrabComp.AnimData.bCanPlantFeet = LedgeGrabComp.Data.bFeetPlanted;
				Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, LedgeGrabComp.Data.PlayerRotation, DeltaTime, 360.0));
			}
			else // Remote
			{
				// We still need to do a local trace to determine whether our feet are still planted or not for remote side animations
				FSnowMonkeyLedgeGrabData RemoteLedgeGrabData;
				if (LedgeGrabComp.TraceForLedgeGrabAtLocation(
						Player, -LedgeGrabComp.Data.WallImpactNormal.ConstrainToPlane(MoveComp.WorldUp),
						Player.ActorLocation, RemoteLedgeGrabData, IsDebugActive()))
				{
					LedgeGrabComp.AnimData.bCanPlantFeet = RemoteLedgeGrabData.bFeetPlanted;

					// Don't show shimmy animation in the first 0.1s, since we will still be moving towards the grab point
					if (ActiveDuration > 0.1)
					{
						FHazeSyncedActorPosition SyncedMovement = MoveComp.GetCrumbSyncedPosition();
						FVector ShimmyDeltaMove = (SyncedMovement.WorldLocation - Player.ActorLocation);

						LedgeGrabComp.AnimData.ShimmyScale = (ShimmyDeltaMove.ConstrainToDirection(RemoteLedgeGrabData.LedgeRightVector) / DeltaTime).Size();
						LedgeGrabComp.AnimData.ShimmyScale = Math::Abs(LedgeGrabComp.AnimData.ShimmyScale) / (LedgeGrabComp.Settings.ShimmySpeedMax - LedgeGrabComp.Settings.ShimmySpeedMin);
						LedgeGrabComp.AnimData.ShimmyScale = Math::Clamp(LedgeGrabComp.AnimData.ShimmyScale, 0.0, 1.0);
						LedgeGrabComp.AnimData.ShimmyScale *= Math::Sign(ShimmyDeltaMove.DotProduct(RemoteLedgeGrabData.LedgeRightVector));
					}
				}
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"LedgeGrab");

			if (IsDebugActive())
			{
				FVector ToLedge = LedgeGrabComp.Data.LedgeLocation - Owner.ActorLocation;
				PrintToScreenScaled("Forward: " + ToLedge.DotProduct(Owner.ActorForwardVector), 0.0, FLinearColor::Green, Scale = 2.0);
				PrintToScreenScaled("Up: " + ToLedge.DotProduct(MoveComp.WorldUp), 0.0, FLinearColor::Green, Scale = 2.0);
				PrintToScreenScaled("[Ledge Distance]", 0.0, FLinearColor(1.0, 0.5, 0.0), 2.0);
			}
		}
	}
}