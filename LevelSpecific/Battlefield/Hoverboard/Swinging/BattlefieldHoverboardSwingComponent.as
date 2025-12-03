
class UBattlefieldHoverboardSwingComponent : UActorComponent
{
	AHazePlayerCharacter OwningPlayer;
	UBattlefieldHoverboardSwingSettings Settings;
	UPlayerWallSettings WallSettings;

	FPlayerSwingData Data;
	FPlayerSwingAnimData AnimData;

	FVector SwingForward;

	// Niagara will draw the rope using this instance.
	UNiagaraComponent VisualRopeInstance;
	UBattlefieldHoverboardComponent HoverboardComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(OwningPlayer);

		Settings = UBattlefieldHoverboardSwingSettings::GetSettings(Cast<AHazeActor>(Owner));
		WallSettings = UPlayerWallSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	void StartSwinging(USwingPointComponent SwingPoint)
	{
		Data.ActiveSwingPoint = SwingPoint;
		Data.ActiveSwingPoint.OnPlayerAttached(OwningPlayer);

		if(Data.SwingPointToForceActivate != nullptr && Data.SwingPointToForceActivate == SwingPoint)
			Data.SwingPointToForceActivate = nullptr;

		SwingPoint.ApplySettings(OwningPlayer, this);
		Data.AcceleratedTetherLength.SnapTo(SwingPointToPlayer.Size());
	}

	void StopSwinging()
	{
		if (!Data.HasValidSwingPoint())
			return;

		Data.ActiveSwingPoint.OnPlayerDetached(OwningPlayer);
		OwningPlayer.ClearSettingsByInstigator(this);
		Data.ResetData();
	}

	bool TraceForWall(AHazePlayerCharacter Player, FVector Velocity, FPlayerSwingData& WallData, bool bDebug = false) const
	{	
		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);

		FVector TraceDirection;
		if (Data.HasValidWall())
			TraceDirection = -Data.WallNormal;
		else if(!Velocity.IsNearlyZero())
			TraceDirection = Velocity.GetSafeNormal();
		else
			TraceDirection = Player.ActorForwardVector;

		WallData.ResetWallData();
		
		FHazeTraceSettings TraceSettings;
		FVector TraceStart = Player.ActorLocation;
		FVector TraceEnd = TraceStart + TraceDirection * Math::Max(WallSettings.WallTraceForwardReach - Player.CapsuleComponent.CapsuleRadius, 0.0);

		TraceSettings = Trace::InitFromMovementComponent(MoveComp);

		if (bDebug)
			TraceSettings.DebugDrawOneFrame();

		FHitResult WallHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
		if (!WallHit.bBlockingHit)
			return false;

		if (!WallHit.Component.HasTag(ComponentTags::WallRunnable))
			return false;
		
		// Don't stick to the wall if the wall hit is away from the swing point
		FVector ToHit = WallHit.ImpactPoint - PlayerLocation;
		float Dot = ToHit.DotProduct(PlayerToSwingPoint.ConstrainToPlane(MoveComp.WorldUp));
		if (Dot < 0.0)
			return false;

		FVector WallRight = MoveComp.WorldUp.CrossProduct(WallHit.ImpactNormal).GetSafeNormal();
		WallData.WallRotation = FRotator::MakeFromXY(WallHit.ImpactNormal, WallRight);
		
		// Check for the verticality of the surface
		float WallPitch = 90.0 - Math::RadiansToDegrees(WallData.WallNormal.AngularDistance(MoveComp.WorldUp));
		if (WallPitch > WallSettings.WallPitchMaximum + KINDA_SMALL_NUMBER || WallPitch < WallSettings.WallPitchMinimum - KINDA_SMALL_NUMBER)
			return false;

		// Foot tracing is needed so you release from the wall

		WallData.WallComponent = WallHit.Component;
		WallData.WallLocation = WallHit.ImpactPoint;

		return true;
	}

	// Takes Velocity and DeltaMove, and constrains it around the active swing point
	void ConstrainVelocityToSwingPoint(FVector& Velocity, FVector& DeltaMove)
	{
		// The first time you are going away from the tether, we should update the length of the tether so you get a juicy smooth attach
		if (!Data.bTetherTaut)
		{
			// Don't constrain if you are going towards the swing point
			if (SwingPointToPlayer.DotProduct(Velocity) < 0.0)
				return;

			// if (SwingPointToPlayer.Size() < Settings.TetherLength)
			// 	return;

			float SpeedAwayFromPoint = SwingPointToPlayer.GetSafeNormal().DotProduct(Velocity);
			Data.AcceleratedTetherLength.SnapTo(SwingPointToPlayer.Size(), SpeedAwayFromPoint);
			Data.bTetherTaut = true;
		}

		// Remove velocity in the direction of the swing point
		FVector RopeTension = PlayerToSwingPoint.GetSafeNormal() * PlayerToSwingPoint.GetSafeNormal().DotProduct(Velocity);
		Velocity -= RopeTension;

		// Move the delta around the sphere
		FVector RotationAxis = Velocity.CrossProduct(PlayerToSwingPoint).GetSafeNormal();
		FQuat VelocityRotation = FQuat(RotationAxis, DeltaMove.Size() / Data.TetherLength);

		// Calculate the new location, and ensure the tether is the correct length
		FVector SwingPointToTargetLocation = SwingPointToPlayer.GetSafeNormal() * Data.TetherLength;
		SwingPointToTargetLocation = VelocityRotation * SwingPointToTargetLocation;
		FVector TargetPlayerLocation = SwingPointLocation + SwingPointToTargetLocation;

		DeltaMove = TargetPlayerLocation - PlayerLocation;
		Velocity = VelocityRotation * Velocity;
	}

	void UpdateTetherTautness(FVector Velocity)
	{
		if (!Data.bTetherTaut)
		{
			// Don't constrain if you are going towards the swing point
			if (SwingPointToPlayer.DotProduct(Velocity) < 0.0)
				return;

			// if (SwingPointToPlayer.Size() < Settings.TetherLength)
			// 	return;

			float SpeedAwayFromPoint = SwingPointToPlayer.GetSafeNormal().DotProduct(Velocity);
			Data.AcceleratedTetherLength.SnapTo(SwingPointToPlayer.Size(), SpeedAwayFromPoint);
			Data.bTetherTaut = true;
		}
	}


	bool HasActivateSwingPoint() const
	{
		return Data.HasValidSwingPoint();
	}
	
	FVector GetSwingPointLocation() const property
	{
		return Data.ActiveSwingPoint.WorldLocation;
	}

	FVector GetPlayerLocation() const property
	{
		return OwningPlayer.ActorCenterLocation;
	}

	FVector GetSwingPointToPlayer() const property
	{
		return GetPlayerLocation() - GetSwingPointLocation();
	}

	FVector GetPlayerToSwingPoint() const property
	{
		return GetSwingPointLocation() - GetPlayerLocation();
	}

	float GetSwingAngle() const property
	{
		return Math::RadiansToDegrees(PlayerToSwingPoint.AngularDistance(OwningPlayer.MovementWorldUp));
	}

	void DebugDrawVelocity(FVector Velocity, FVector Offset)
	{
		if (Velocity.IsNearlyZero(1.0))
			return;

		Debug::DrawDebugLine(PlayerLocation, PlayerLocation + Velocity, FLinearColor::Red, 2.0);
		Debug::DrawDebugString(PlayerLocation + Velocity.GetSafeNormal() * Math::Min(Velocity.Size(), 150.0) + Offset, "Velocity ["
		+ String::Conv_IntToString(int(Velocity.X)) + ", "
		+ String::Conv_IntToString(int(Velocity.Y)) + ", "
		+ String::Conv_IntToString(int(Velocity.Z)) + "]", FLinearColor(1.0, 0.1, 0.1), 0.0, 1.2);
	}

	void DebugDrawGravity(FVector Gravity, FVector Offset)
	{
		if (Gravity.IsNearlyZero(1.0))
			return;

		Debug::DrawDebugLine(PlayerLocation, PlayerLocation + Gravity, FLinearColor::LucBlue, 2.0);
		Debug::DrawDebugString(PlayerLocation + Gravity.GetSafeNormal() * Math::Min(Gravity.Size(), 150.0) + Offset, "Gravity", FLinearColor::LucBlue, 0.0, 1.2);
	}

	void DebugDrawTether()
	{
		FLinearColor TetherColor = FLinearColor(0.15, 0.10, 0.10);
		Debug::DrawDebugLine(SwingPointLocation, OwningPlayer.Mesh.GetSocketLocation(n"LeftAttach"), TetherColor, 3.0);		
		Debug::DrawDebugLine(OwningPlayer.Mesh.GetSocketLocation(n"LeftAttach"), OwningPlayer.Mesh.GetSocketLocation(n"RightAttach"), TetherColor, 3.0);		
		Debug::DrawDebugLine(OwningPlayer.Mesh.GetSocketLocation(n"RightAttach"), OwningPlayer.Mesh.GetSocketLocation(n"Hips"), TetherColor, 3.0);	
	}

	void ActivateRopeVisuals()
	{
		// destroy the previous instance if it hasn't already
		if(VisualRopeInstance != nullptr)
		{
			VisualRopeInstance.DeactivateImmediate();
			VisualRopeInstance.DestroyComponent(this);
		}

		// clear any previous handles since we can guarantee that any previous niagara comp is deactivated.
		RetractRopeTimerHandle.ClearTimerAndInvalidateHandle();

		// for now we'll spawn and delete the visuals upon need. Perhaps its more performant to always have the rope on the actor and handle this via Activation/deactivation instead.
		VisualRopeInstance = Niagara::SpawnLoopingNiagaraSystemAttached(HoverboardComp.VisualRopeAsset, OwningPlayer.RootComponent, n"Hips");
		VisualRopeInstance.SetNiagaraVariableFloat("ExtendRopeDuration", Settings.ExtendRopeDuration);
		VisualRopeInstance.SetNiagaraVariableFloat("RetractRopeDuration", Settings.RetractRopeDuration);

		VisualRopeInstance.SetTickGroup(ETickingGroup::TG_LastDemotable);
		VisualRopeInstance.TickBehavior = ENiagaraTickBehavior::UseComponentTickGroup;
	}

	void DeactivateRopeVisuals()
	{
		if(VisualRopeInstance == nullptr)
			return;

		// flag niagara that it should retract the rope.
		VisualRopeInstance.SetVariableBool(n"RetractRope", true);
		VisualRopeInstance.SetVariableFloat(n"RetractTimeStamp", Time::GetGameTimeSeconds());

		RetractRopeTimerHandle.ClearTimerAndInvalidateHandle();

		// have the niagara comp deactivate slightly after it has retracted
		RetractRopeTimerHandle = Timer::SetTimer(this, n"HandleVisualRopeRetracted", Settings.RetractRopeDuration + 0.1);
	}

	FTimerHandle RetractRopeTimerHandle;

	UFUNCTION()
	private void HandleVisualRopeRetracted()
	{
		if(VisualRopeInstance != nullptr)
		{
			// this will deactivate the visuals immediately, as long as the elapsed activation time > Particle.lifetime.
			VisualRopeInstance.Deactivate();
		}
	}

	UFUNCTION()
	void VisualRopeFullyExtended()
	{
		// const FVector FinalSwingPointLocation = Data.ActiveSwingPoint.GetWorldLocation() + Data.RopeOffset;
		// Debug::DrawDebugPoint(FinalSwingPointLocation, 20.0, FLinearColor::Red, 5);

		Data.ActiveSwingPoint.OnGrappleHookReachedSwingPointEvent.Broadcast(OwningPlayer, Data.ActiveSwingPoint);
	}

	void UpdateRopeVisuals()
	{
		if(VisualRopeInstance == nullptr)
			return;

		// we will draw the rope between 4 points; SwingPoint, both Hands and hip.
		FVector HandRight = OwningPlayer.Mesh.GetSocketLocation(n"RightAttach");
		FVector HandLeft = OwningPlayer.Mesh.GetSocketLocation(n"LeftAttach");
		FVector Hips = OwningPlayer.Mesh.GetSocketLocation(n"Hips");

		// need to handle cases when the hands are blocked.
		const bool bLeftBlocked = false;
		const bool bRightBlocked = false;
		if(bLeftBlocked && bRightBlocked)
		{
			HandLeft = Hips;
			HandRight = Hips;
		}
		else if(bLeftBlocked || bRightBlocked)
		{
			if(bLeftBlocked)
			{
				HandLeft = HandRight;
			}
			else
			{
				HandRight = HandLeft;
			}
		}

		// For this to work, without the rope lagging behind, this function, UpdateRopeVisuals(), needs to be executed 
		// in a tickgroup that is before the NiagaraComponent instance tickgroup.  For example: 
		// UpdateRopeVisuals() in ::PostWork and have the component tick in ::LastDemotable.
		// And also make sure that the niagara system itself is forced to tick 
		// in the same tickgroup as the Niagaracomponent.
		const FVector FinalSwingPointLocation = Data.ActiveSwingPoint.GetWorldLocation() + Data.RopeOffset;
		VisualRopeInstance.SetNiagaraVariablePosition("WorldSwingPos", FinalSwingPointLocation);
		// Debug::DrawDebugPoint(FinalSwingPointLocation, 10.0, FLinearColor::Red);

		// change rope visuals based on variant type
		const EHazePlayerVariantType CurrentVariantType = UPlayerVariantComponent::Get(Owner).GetPlayerVariantType();
		VisualRopeInstance.SetNiagaraVariableBool("UseScifiRope", CurrentVariantType != EHazePlayerVariantType::Fantasy);
		VisualRopeInstance.SetNiagaraVariableBool("UseFantasyRope", CurrentVariantType == EHazePlayerVariantType::Fantasy);

		// these positions need to be local to the Niagara system for them not to lag behind when swinging
		const FTransform NiagaraTransform = VisualRopeInstance.WorldTransform;

		TArray<FVector> AttachmentPoints;
		AttachmentPoints.Reserve(4);

		// we add a zero here for convenience sake. Rebuilding an array in niagara is not straight forward.
		// this makes it easier for us to replace the 0th index with the swingpoint location instead, in niagara.
		AttachmentPoints.Add(FVector::ZeroVector);

		AttachmentPoints.Add(NiagaraTransform.InverseTransformPosition(HandLeft));
		AttachmentPoints.Add(NiagaraTransform.InverseTransformPosition(HandRight));
		AttachmentPoints.Add(NiagaraTransform.InverseTransformPosition(Hips));

		NiagaraDataInterfaceArray::SetNiagaraArrayVector(VisualRopeInstance, n"AttachmentPoints", AttachmentPoints);
	}
}