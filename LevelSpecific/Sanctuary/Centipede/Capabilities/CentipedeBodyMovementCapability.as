// This resolves centipede's body
class UCentipedeBodyMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CentipedeTags::Centipede);

	default TickGroup = EHazeTickGroup::LastMovement;

	ACentipede Centipede;

	int RespawnCount;

	TArray<FVector> ControlHalfSegmentLocations;
	TArray<FVector> RemoteHalfSegmentLocations;

	AHazePlayerCharacter ControlPlayer;

	const int ReplicatedSegmentCount = 5;

	FVector CentipedeActorMoveDelta;

	bool bFirstTick;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Centipede = Cast<ACentipede>(Owner);
		ControlPlayer = Game::Mio.HasControl() ? Game::Mio : Game::Zoe;

		if (!Network::IsGameNetworked())
			Centipede.ApplyBodyReplicationBlock(this, EInstigatePriority::Override);

		for (int i = 0; i < ReplicatedSegmentCount; i++)
		{
			ControlHalfSegmentLocations.Add(FVector());
			RemoteHalfSegmentLocations.Add(FVector());
		}

		UPlayerRespawnComponent::Get(Centipede::GetHeadPlayer()).OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawn");
		UPlayerRespawnComponent::Get(Centipede::GetTailPlayer()).OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawn");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Reset capability (centi body) when both players have respawned
		if (RespawnCount == 2)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Segment location is absolute so moving the centipede actor doesn't also move them
		// The segments are moved every frame to a world position anyway so they don't need to be relative
		for (auto Segment : Centipede.Segments)
		{
			FTransform SegmentTransform = Segment.WorldTransform;
			Segment.SetAbsolute(true, true, true);
			Segment.SetWorldTransform(SegmentTransform);
		}

		RespawnCount = 0;

		// Last cutscene set centipede up (CentipedeCutsceneCapability deactivation), don't mess with body
		if (!Centipede.bWasControlledByCutsceneLastFrame)
		{
			ResetBody();
			bFirstTick = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Reset segments back to being relative once we aren't moving them with this capability anymore
		for (auto Segment : Centipede.Segments)
		{
			FTransform SegmentTransform = Segment.WorldTransform;
			Segment.SetAbsolute(false, false, false);
			Segment.SetWorldTransform(SegmentTransform);
		}

		bFirstTick = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// We have to wait for mesh to update first before attacking it
		if (bFirstTick)
		{
			bFirstTick = false;
			return;
		}

		// Move centipede actor to a location between both players
		FVector TargetLocation = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
		CentipedeActorMoveDelta = (TargetLocation - Centipede.ActorLocation) * DeltaTime;
		Centipede.SetActorLocation(TargetLocation);

		// Add delta instead of removing it if we are inheriting movement
		if (Centipede.bBodyInheritsActorMovement)
			CentipedeActorMoveDelta = -CentipedeActorMoveDelta;

		StartSegmentSimulation();
		TickCollisions();

		// Smooth-in body resolver
		int Iterations = int(Math::Lerp(1, 20, Math::Saturate(ActiveDuration / 0.2))); // $$$
		for (int i = 0; i < Iterations; i++)
		{
			TickMovement(DeltaTime);

			TickConstraints();
			TickStifness();
		}

		if (!Centipede.IsBodyReplicationBlocked())
		{
			// Send control locations
			{
				for (int i = 0; i < ReplicatedSegmentCount; i++)
					ControlHalfSegmentLocations[i] = Centipede.GetSlaveSegmentForPlayer(ControlPlayer.Player, uint(i)).SimulateLocation;

				NetSyncHalfPlayerSegments(ControlHalfSegmentLocations, ControlPlayer.Player);
			}

			// Lerp and sync remote locations
			{
				for (int i = 0; i < ReplicatedSegmentCount; i++)
				{
					UCentipedeSegmentComponent Segment = Centipede.GetSlaveSegmentForPlayer(ControlPlayer.OtherPlayer.Player, uint(i));
					FVector Location = Math::VInterpConstantTo(Segment.SimulateLocation, RemoteHalfSegmentLocations[i], DeltaTime, 2000);
					Segment.SimulateLocation = Location;

					// FLinearColor Color = ControlPlayer.IsMio() ? FLinearColor::Purple : FLinearColor::Green;
					// Debug::DrawDebugSphere(RemoteHalfSegmentLocations[i], LineColor = Color);
				}
			}
		}

		FinishSegmentSimulation();
		AnimateLegs(DeltaTime);

		Centipede.bJustTeleported = false;
	}

	void ResetBody()
	{
		// Move centipede actor to a location between both players
		FVector TargetLocation = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
		Centipede.SetActorLocation(TargetLocation);

		Centipede.ResetBody();
	}

	void StartSegmentSimulation()
	{
		for (auto Segment : Centipede.Segments)
		{
			Segment.bIsSimulating = true; 
			Segment.SimulateLocation = Segment.WorldLocation;
			Segment.SimulateRotation = Segment.ComponentQuat;
		}
	}

	void FinishSegmentSimulation()
	{
		for (auto Segment : Centipede.Segments)
		{
			Segment.bIsSimulating = false;

			// Add actor delta when inheriting centipede movement
			FVector SegmentLocation = Segment.SimulateLocation;
			if (Centipede.bBodyInheritsActorMovement && !Segment.bIsHead && !Segment.bIsHeadBody)
				SegmentLocation -= (CentipedeActorMoveDelta / Time::GetActorDeltaSeconds(Centipede)) * 0.5;

			Segment.SetWorldLocationAndRotation(SegmentLocation, Segment.SimulateRotation);
			Segment.QueueComponentForUpdateOverlaps();

			if (SanctuaryCentipedeDevToggles::Draw::Body.IsEnabled())
				Debug::DrawDebugSphere(Segment.SimulateLocation, Segment.BoundsRadius, bDrawInForeground = true);
		}
	}

	void TickMovement(float DeltaTime)
	{
		for (auto Segment : Centipede.Segments)
		{
			// Update special bones with mesh data
			if (Segment.bIsHead || Segment.bIsHeadBody)
			{
				FVector MeshBoneLocation = Centipede.Mesh.GetSocketLocation(Segment.Name);
				Segment.SimulateLocation = (MeshBoneLocation - CentipedeActorMoveDelta);
				continue;
			}

			if (Segment.PreviousLocation.IsZero() || Centipede.bJustTeleported || Centipede.bBodyInheritsActorMovement)
				Segment.PreviousLocation = Segment.SimulateLocation;

			FVector Gravity = -FVector::UpVector * 800;
			FVector MoveDelta = (Segment.SimulateLocation - Segment.PreviousLocation) + Gravity * DeltaTime;
			Segment.PreviousLocation = Segment.SimulateLocation;

			// Add some friction
			MoveDelta -= MoveDelta * 0.98;

			FVector NextLocation = Segment.SimulateLocation + MoveDelta;
			Segment.SimulateLocation = (NextLocation - CentipedeActorMoveDelta);

			// Segment.DebugDraw();
		}
	}

	void TickConstraints()
	{
		for (auto Constraint : Centipede.Constraints)
		{
			float Length = Constraint.Start.BoundsRadius * 2.0;
			float Delta = Length - Constraint.Start.SimulateLocation.Distance(Constraint.End.SimulateLocation);
			float Multiplier = (Delta / Constraint.Start.SimulateLocation.Distance(Constraint.End.SimulateLocation)) * 0.5;

			FVector StartToEnd = Constraint.End.SimulateLocation - Constraint.Start.SimulateLocation;

			// We don't want the body moving the player; player will handle its own movement
			if (Constraint.Start.bIsMasterJoint)
			{
				Constraint.End.SimulateLocation += (StartToEnd * Multiplier * 2);
			}
			else if (Constraint.End.bIsMasterJoint)
			{
				Constraint.Start.SimulateLocation += (-StartToEnd * Multiplier);
				Constraint.Start.SimulateRotation = StartToEnd.ToOrientationQuat();
			}
			else if (!Constraint.Start.bIsHeadBody && !Constraint.End.bIsHeadBody)
			{
				Constraint.Start.SimulateLocation += (-StartToEnd * Multiplier);
				Constraint.End.SimulateLocation += (StartToEnd * Multiplier);

				Constraint.Start.SimulateRotation = StartToEnd.ToOrientationQuat();
			}

			// Debug::DrawDebugLine(Constraint.Start.ActorLocation, Constraint.End.ActorLocation, FLinearColor::Green, 10);
		}
	}

	// Solve for every other segment
	void TickStifness()
	{
		// Add this offset so the first segment doesn't get awkardly
		// squeezed between hips and second segment
		const int Offset = int(Centipede.SpecialBoneCount) - 1;

		for (int i = Offset; i < Centipede.Constraints.Num() - 1 - Offset; i++)
		{
			const FCentipedeSegmentConstraint& Constraint = Centipede.Constraints[i];
			const FCentipedeSegmentConstraint& NextConstraint = Centipede.Constraints[i + 1];

			float Length = Constraint.Start.BoundsRadius * 4.0;
			float Delta = Length - Constraint.Start.SimulateLocation.Distance(NextConstraint.End.SimulateLocation);
			float Multiplier = (Delta / Constraint.Start.SimulateLocation.Distance(NextConstraint.End.SimulateLocation)) * 0.5;

			FVector StartToEnd = NextConstraint.End.SimulateLocation - Constraint.Start.SimulateLocation;

			// Don't displace important bone
			if (!Constraint.Start.bIsHead && !Constraint.Start.bIsHeadBody)
			{
				Constraint.Start.SimulateLocation += (-StartToEnd * Multiplier);
				Constraint.Start.SimulateRotation = StartToEnd.ToOrientationQuat();
			}

			// Don't displace important bone
			if (!NextConstraint.End.bIsHead && !NextConstraint.End.bIsHeadBody)
				NextConstraint.End.SimulateLocation += (StartToEnd * Multiplier);
		}
	}

	void TickCollisions()
	{
		// Don't mess around with important bones
		for (auto Segment : Centipede.Segments)
		{
			if (Segment.bIsHead)
				continue;

			if (Segment.bIsHeadBody)
				continue;

			if (Segment.bIsMasterJoint)
				continue;

			FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(Segment);
			FOverlapResultArray OverlapResults = Trace.QueryOverlaps(Segment.SimulateLocation);

			FVector Offset;
			for (auto OverlapResult : OverlapResults)
			{
				// WTF is this and why is it here?!
				if (OverlapResult.Actor.IsA(ADarkPortalActor))
					continue;

				if (OverlapResult.Actor != nullptr && OverlapResult.Actor.ActorHasTag(CentipedeTags::IgnoreCentipedeBody))
					continue;

				if (OverlapResult.Component.HasTag(CentipedeTags::IgnoreCentipedeBody))
					continue;

				Offset += OverlapResult.GetDepenetrationDelta(Trace.Shape, Segment.SimulateLocation);
			}

			Segment.SimulateLocation += Offset;
		}
	}

	void AnimateLegs(float DeltaTime)
	{
		float MioInput = Centipede.PlayerMovementInput[Game::Mio].Size();
		float ZoeInput = Centipede.PlayerMovementInput[Game::Zoe].Size();

		// Don't overshoot if both players are moving
		float ExclusiveMultiplier = Math::Lerp(1, 0.75, Math::Square((MioInput + ZoeInput) * 0.5));

		// We want to have a base movement only if players are not moving
		float RestlessLegSyndromeAdditive = Math::IsNearlyEqual(ExclusiveMultiplier, 1.0) ? (DeltaTime * 0.03) : 0.0;

		// Do Mio (giggity)
		auto MioSegment = Centipede.GetSlaveSegmentForPlayer(EHazePlayer::Mio, 0);
		MioSegment.LegAnimationTime += MioInput * DeltaTime * ExclusiveMultiplier + RestlessLegSyndromeAdditive;
		Centipede.Mesh.SetScalarParameterValueOnMaterials(n"SegmentTime0", MioSegment.LegAnimationTime);

		// Do Zoe (giggity goo)
		auto ZoeSegment = Centipede.GetSlaveSegmentForPlayer(EHazePlayer::Zoe, 0);
		ZoeSegment.LegAnimationTime += ZoeInput * DeltaTime * ExclusiveMultiplier + RestlessLegSyndromeAdditive;
		Centipede.Mesh.SetScalarParameterValueOnMaterials(n"SegmentTime1", ZoeSegment.LegAnimationTime);
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSyncHalfPlayerSegments(TArray<FVector> SyncedHalfSegmentLocations, EHazePlayer Player)
	{
		if (Game::GetPlayer(Player).HasControl())
			return;

		RemoteHalfSegmentLocations = SyncedHalfSegmentLocations;
	}

	UFUNCTION()
	private void OnPlayerRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		RespawnCount++;
	}
}