class USanctuaryDarkPortalCompanionLaunchCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalLaunch);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90; // Before atportal

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	USanctuaryDarkPortalCompanionSettings Settings;
	UTeleportingMovementData Movement;
	UHazeCharacterSkeletalMeshComponent Mesh;
	UBasicAIAnimationComponent AnimComp; 
	USanctuaryDarkPortalCompanionAudioComponent AudioComp;

	FVector StartLocation; 
	FVector StartTangent;
	FVector EndTangent; 

	FHazeAcceleratedFloat Speed;
	float CurrentDistance;
	FVector Destination;
	bool bObstructed;

	float FailEffectCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		AudioComp = USanctuaryDarkPortalCompanionAudioComponent::Get(Owner); 
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (CompanionComp.State != EDarkPortalCompanionState::Launched)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (CompanionComp.State != EDarkPortalCompanionState::Launched)
			return true;
		float Range = (CompanionComp.Portal.TargetData.IsValid()) ? 50.0 : 100.0;
		if (Owner.ActorLocation.IsWithinDist(Destination, Range))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = EDarkPortalCompanionState::Launched;

		Destination = CompanionComp.Portal.TargetData.WorldLocation;
		bObstructed = CompanionComp.Portal.TargetData.bObstructed;
		if (!CompanionComp.Portal.TargetData.IsValid())
		{
			// Launch move without target, just move ahead
			FVector LaunchDir = CompanionComp.Player.ViewRotation.ForwardVector;
			FVector AimDest = CompanionComp.Player.ViewLocation + LaunchDir * Settings.LaunchNoTargetRange;
			FDarkPortalTargetData TargetData = CompanionComp.Portal.GetTargetDataFromTrace(Owner.ActorLocation, AimDest);
			bObstructed = TargetData.bObstructed;
			Destination = TargetData.WorldLocation; 
			if (bObstructed)
				Destination -= LaunchDir * 200.0;
		}
		float Distance = Math::Max(Destination.Distance(StartLocation), 1.0);
		FVector DestDir = (Destination - StartLocation) / Distance;

		StartLocation = Owner.ActorLocation;

		// Launch forwards and a bit upwards when we were attached to player
		if (Owner.ActorLocation.IsWithinDist(CompanionComp.Player.Mesh.GetSocketLocation(Settings.LaunchStartSocket), 40.0))
		{
			// Launch towards destination and a bit upwards when we were attached to player
			float UpFactor = Settings.LaunchFromHeldUpFactor;
			StartTangent = ((DestDir * (1.0 - UpFactor) + FVector::UpVector * UpFactor)).GetSafeNormal() * Math::Min(Distance, Settings.LaunchFromHeldMaxTangent);
		}
		else
		{
			// Launch maintaining velocity
			StartTangent = Owner.ActorVelocity.GetClampedToMaxSize(Math::Min(Distance, 2000.0)) * (0.5 + Settings.LaunchNoise * 0.5);
		}

		FVector LandDir = DestDir;
		if (CompanionComp.Portal.TargetData.IsValid())
		{
			FVector LandCenter = -CompanionComp.Portal.TargetData.WorldNormal;
			LandDir = Math::GetRandomHalfConeDirection(LandCenter, -CompanionComp.Player.ActorUpVector, Math::DegreesToRadians(60.0 * Settings.LaunchNoise));
		}
		else if (bObstructed)
		{
			LandDir = CompanionComp.Player.ViewRotation.RightVector;
			if (LandDir.DotProduct(DestDir) < 0.0)
				LandDir *= -1.0;
			LandDir = (LandDir * 0.3 - DestDir).GetSafeNormal2D();
		}
		EndTangent = LandDir * Settings.LaunchSpeed * (0.1 + Settings.LaunchNoise * 0.5);

		Speed.SnapTo(Owner.ActorVelocity.Size());
		CurrentDistance = 0.0;

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);

		AnimComp.RequestFeature(DarkPortalCompanionAnimTags::Launch, EBasicBehaviourPriority::Medium, this);		

		UDarkPortalEventHandler::Trigger_CompanionLaunchStarted(Owner);
		UDarkPortalEventHandler::Trigger_CompanionLaunchStarted(CompanionComp.Player);
		UDarkPortalEventHandler::Trigger_Launched(CompanionComp.Portal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Attach if we have a valid target or react and return as companion sees fit.
		if (CompanionComp.State == EDarkPortalCompanionState::Launched || CompanionComp.State == EDarkPortalCompanionState::LaunchStart)
		{
			// Can we attach to portal?
			if (CompanionComp.Portal.TargetData.IsValid() && CompanionComp.State == EDarkPortalCompanionState::Launched)
			{
				CompanionComp.State = EDarkPortalCompanionState::AtPortal;

				// Note that this attaches portal, not owner. That is handled in proper capability.
				CompanionComp.Portal.AttachPortal(CompanionComp.Portal.TargetData.WorldTransform, CompanionComp.Portal.TargetData.SceneComponent, CompanionComp.Portal.TargetData.SocketName);
				CompanionComp.Portal.SetState(EDarkPortalState::Settle);
				UDarkPortalEventHandler::Trigger_CompanionReachPortal(CompanionComp.Portal);

				FDarkPortalSettledEventData SettleParams;
				SettleParams.PortalTransform = CompanionComp.Portal.ActorTransform;
				UDarkPortalEventHandler::Trigger_Settled(CompanionComp.Portal, SettleParams);
			}
			else if (CompanionComp.State != EDarkPortalCompanionState::LaunchStart)
			{
				CompanionComp.State = EDarkPortalCompanionState::Follow;
				CompanionComp.Portal.SetState(EDarkPortalState::Recall);
				UDarkPortalEventHandler::Trigger_SettleFailed(CompanionComp.Portal);
			}
		}

		CompanionComp.LastLaunchedTime = Time::GameTimeSeconds;

		CompanionComp.TargetMeshPitch.Clear(this);
		AnimComp.ClearFeature(this);

		if (!CompanionComp.Portal.TargetData.IsValid() && Owner.ActorLocation.IsWithinDist(Destination, 400.0) && (Time::GameTimeSeconds > FailEffectCooldown))
		{
			UDarkPortalEventHandler::Trigger_CompanionFailedToOpenPortal(Owner);	
			UDarkPortalEventHandler::Trigger_CompanionFailedToOpenPortal(CompanionComp.Player);	
			FailEffectCooldown = Time::GameTimeSeconds + 0.5;
		}

		AudioComp.LaunchDistanceAlpha = 0.0;

		UDarkPortalEventHandler::Trigger_CompanionLaunchStopped(Owner);
		UDarkPortalEventHandler::Trigger_CompanionLaunchStopped(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
			ComposeMovement(DeltaTime);
		else
			Movement.ApplyCrumbSyncedAirMovement();
		MoveComp.ApplyMove(Movement);

		if (bObstructed && Owner.ActorLocation.IsWithinDist(Destination, 400.0))
			AnimComp.RequestFeature(LightBirdCompanionAnimTags::LaunchBlocked, EBasicBehaviourPriority::Medium, this);

		
		if (CompanionComp.Portal.TargetData.IsValid())
		{
			// Place portal at target location
			CompanionComp.Portal.DetachPortal();	
			FTransform TargetPos = CompanionComp.Portal.TargetData.WorldTransform;
			CompanionComp.Portal.SetActorLocationAndRotation(TargetPos.Location, TargetPos.Rotation);

			// Align companion mesh with portal when close
			if (Owner.ActorLocation.IsWithinDist(Destination, 500.0))
				CompanionComp.TargetMeshPitch.Apply(-TargetPos.Rotation.Rotator().Pitch, this, EInstigatePriority::Normal);
		}
	}

	void ComposeMovement(float DeltaTime)
	{
		if (DeltaTime == 0.0)
			return;

		if (CompanionComp.Portal.TargetData.IsValid())
		{
			// Update destination
			Destination = CompanionComp.Portal.TargetData.WorldLocation;
			bObstructed = CompanionComp.Portal.TargetData.bObstructed;
		}

		FVector StartControl = StartLocation + StartTangent;
		FVector EndControl = Destination - EndTangent;
		float Length = BezierCurve::GetLength_2CP(StartLocation, StartControl, EndControl, Destination);

		if (bObstructed && (CurrentDistance > Length - 120.0))
			Speed.AccelerateTo(200.0, 0.1, DeltaTime); // Brake hard when near obstruction
		else if ((CurrentDistance > Length - 400.0) && !CompanionComp.Portal.TargetData.IsValid())
			Speed.AccelerateTo(Settings.LaunchSpeed * 0.4, 2.0, DeltaTime); // Slow down at end of launch when there is nothing to attach to
		else
			Speed.AccelerateTo(Settings.LaunchSpeed, Settings.LaunchAccelerationDuration, DeltaTime); // Accelerate to target
		CurrentDistance += Speed.Value * DeltaTime;

		float Alpha = Math::Min(1.0, CurrentDistance / Length);
		FVector NewLoc = BezierCurve::GetLocation_2CP(StartLocation, StartControl, EndControl, Destination, Alpha);
		FVector Delta = NewLoc - Owner.ActorLocation;
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, Delta / DeltaTime);

		// Rotate to match velocity
		FRotator Rotation = MoveComp.GetRotationTowardsDirection(Delta, Settings.LaunchTurnDuration, DeltaTime);
		Movement.SetRotation(Rotation);

		AudioComp.LaunchDistanceAlpha = Alpha; // This is net synced by audio component

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			float Interval = 0.01;
			FVector PrevLoc = StartLocation;
			for (float DbgAlpha = Interval; DbgAlpha < 1.0; DbgAlpha += Interval)
			{
				FVector CurveLoc = BezierCurve::GetLocation_2CP(StartLocation, StartControl, EndControl, Destination, DbgAlpha);
				Debug::DrawDebugLine(PrevLoc, CurveLoc, FLinearColor::Yellow, 3.0);
				PrevLoc = CurveLoc;
			} 

			Debug::DrawDebugLine(StartLocation, StartControl, FLinearColor::LucBlue, 1);
			Debug::DrawDebugLine(StartControl, EndControl, FLinearColor::LucBlue, 1);
			Debug::DrawDebugLine(EndControl, Destination, FLinearColor::LucBlue, 1);
			Debug::DrawDebugString(Game::Zoe.FocusLocation + FVector(0,0,20), "" + Time::FrameNumber);
		}
#endif		
	}
};