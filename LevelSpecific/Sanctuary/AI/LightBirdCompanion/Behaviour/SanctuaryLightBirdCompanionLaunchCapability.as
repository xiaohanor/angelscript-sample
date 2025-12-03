class USanctuaryLightBirdCompanionLaunchCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdLaunch);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90; // Before launchattached

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	USanctuaryLightBirdCompanionSettings Settings;
	UTeleportingMovementData Movement;
	UBasicAIAnimationComponent AnimComp; 
	USanctuaryLightBirdCompanionAudioComponent AudioComp;

	FVector StartLocation; 
	FVector StartTangent;
	FVector EndTangent; 
	FVector CenterControl;

	FHazeAcceleratedFloat Speed;
	float CurrentDistance;
	FVector Destination;
	bool bObstructed;
	USceneComponent DestinationComp;
	bool bHasTarget;

	float FailEffectCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Settings = USanctuaryLightBirdCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupTeleportingMovementData();
		AudioComp = USanctuaryLightBirdCompanionAudioComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (CompanionComp.State != ELightBirdCompanionState::Launched)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (CompanionComp.State != ELightBirdCompanionState::Launched)
			return true;
		if (DestinationComp != CompanionComp.UserComp.AttachedTargetData.SceneComponent)
			return true; // Changed target
		if (bHasTarget && (CompanionComp.UserComp.State != ELightBirdState::Attached))
			return true; // We've cancelled launch
		float Range = (CompanionComp.UserComp.AttachedTargetData.IsValid()) ? 50.0 : 100.0;
		if (Owner.ActorLocation.IsWithinDist(Destination, Range))
			return true; // We've arrived
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = ELightBirdCompanionState::Launched;

		// We must detach before commencing move
		CompanionComp.Detach();
		
		bHasTarget = (CompanionComp.UserComp.State == ELightBirdState::Attached);

		Destination = CompanionComp.UserComp.AttachedTargetData.WorldLocation;
		DestinationComp = CompanionComp.UserComp.AttachedTargetData.SceneComponent;
		bObstructed = CompanionComp.UserComp.AttachedTargetData.bObstructed;
		if (!bHasTarget)
		{
			// Launch move without target, just move ahead
			FVector LaunchDir = CompanionComp.Player.ViewRotation.ForwardVector;
			FVector AimDest = CompanionComp.Player.ViewLocation + LaunchDir * Settings.LaunchNoTargetRange;
			FLightBirdTargetData TargetData = CompanionComp.UserComp.GetTargetDataFromTrace(Owner.ActorLocation, AimDest, false);
			bObstructed = TargetData.bObstructed;
			Destination = TargetData.WorldLocation; 
			CompanionComp.LaunchObstructionLoc = Destination;
			if (bObstructed)
				Destination -= LaunchDir * 200.0;
		}
		float Distance = Math::Max(Destination.Distance(StartLocation), 1.0);
		FVector DestDir = (Destination - StartLocation) / Distance;

		StartLocation = Owner.ActorLocation;

		if (Owner.ActorLocation.IsWithinDist(CompanionComp.Player.Mesh.GetSocketLocation(Settings.LaunchStartSocket), 40.0))
		{
			// Launch towards destination and a bit upwards when we were attached to player
			float UpFactor = Settings.LaunchFromHeldUpFactor;
			StartTangent = ((DestDir * (1.0 - UpFactor) + FVector::UpVector * UpFactor)).GetSafeNormal() * Math::Min(Distance, Settings.LaunchFromHeldMaxTangent);
		}
		else
		{
			// Launch maintaining velocity
			StartTangent = Owner.ActorVelocity.GetClampedToMaxSize(Math::Min(Distance, 4000.0) * Settings.LaunchNoise);
		}

		FVector LandDir = DestDir;
		if (!bHasTarget && bObstructed)
		{
			LandDir = CompanionComp.Player.ViewRotation.RightVector;
			if (LandDir.DotProduct(DestDir) < 0.0)
				LandDir *= -1.0;
			LandDir = (LandDir * 0.3 - DestDir).GetSafeNormal2D();
		}
		 
		EndTangent = LandDir * Settings.LaunchSpeed * Settings.LaunchNoise;

		FVector SideNoise = CompanionComp.Player.ViewRotation.RightVector * Math::RandRange(-1.0, 1.0) * Math::Min(Distance, 10000.0) * Settings.LaunchNoise;
		CenterControl = StartLocation + (EndTangent * FVector(1.0, 1.0, 0.2)) + SideNoise;

		Speed.SnapTo(Owner.ActorVelocity.Size());
		CurrentDistance = 0.0;

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);

		AnimComp.RequestFeature(LightBirdCompanionAnimTags::Launch, EBasicBehaviourPriority::Medium, this);		

		ULightBirdEventHandler::Trigger_LaunchStarted(Owner);
		ULightBirdEventHandler::Trigger_LaunchStarted(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CompanionComp.State == ELightBirdCompanionState::Launched)
		{
			if (bHasTarget && (CompanionComp.UserComp.AttachedTargetData.SceneComponent == DestinationComp))
			{
				// Should we attach or did we cancel before reaching target?
				if (CompanionComp.UserComp.State == ELightBirdState::Attached)
					CompanionComp.State = ELightBirdCompanionState::LaunchAttached;
				else 
					CompanionComp.State = ELightBirdCompanionState::LaunchExit;
			} 
			else
			{
				// No target or changed target
				CompanionComp.State = ELightBirdCompanionState::Follow;
			}
		}

 		CompanionComp.LastLaunchedTime = Time::GameTimeSeconds;
		
		AnimComp.ClearFeature(this);

		if (!bHasTarget && Owner.ActorLocation.IsWithinDist(Destination, 400.0) && (Time::GameTimeSeconds > FailEffectCooldown))
		{
			ULightBirdEventHandler::Trigger_LaunchFailedToAttach(Owner);
			ULightBirdEventHandler::Trigger_LaunchFailedToAttach(CompanionComp.Player);
			FailEffectCooldown = Time::GameTimeSeconds + 0.5;
		}

		ULightBirdEventHandler::Trigger_LaunchStopped(Owner);
		ULightBirdEventHandler::Trigger_LaunchStopped(CompanionComp.Player);

		AudioComp.LaunchDistanceAlpha = 0.0; // Net synced by component
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
		{			
			AnimComp.RequestFeature(LightBirdCompanionAnimTags::LaunchBlocked, EBasicBehaviourPriority::Medium, this);
			CompanionComp.LaunchObstructionTime = Time::GameTimeSeconds;
		}
	}

	void ComposeMovement(float DeltaTime)
	{
		if (DeltaTime == 0.0)
			return;

		if (bHasTarget)
		{
			// Update destination
			Destination = CompanionComp.UserComp.AttachedTargetData.WorldLocation;
			bObstructed = false;
		}

		FVector StartControl = StartLocation + StartTangent;
		FVector EndControl = Destination - EndTangent;
		float Length = BezierCurve::GetLength_3CP(StartLocation, StartControl, CenterControl, EndControl, Destination);

		if (bObstructed && (CurrentDistance > Length - 120.0))
			Speed.AccelerateTo(Settings.LaunchSpeed * 0.1, 0.1, DeltaTime); // Brake hard when near obstruction
		else if ((CurrentDistance > Length - 400.0) && !bHasTarget)
			Speed.AccelerateTo(Settings.LaunchSpeed * 0.4, 2.0, DeltaTime); // Slow down at end of launch when there is nothing to attach to
		else 
			Speed.AccelerateTo(Settings.LaunchSpeed, Settings.LaunchAccelerationDuration, DeltaTime); // Accelerate!

		CurrentDistance += Speed.Value * DeltaTime;

		float Alpha = Math::Min(1.0, CurrentDistance / Length);
		FVector NewLoc = BezierCurve::GetLocation_3CP_ConstantSpeed(StartLocation, StartControl, CenterControl, EndControl, Destination, Alpha);
		FVector Delta = NewLoc - Owner.ActorLocation;
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, Delta / DeltaTime);

		if (AnimComp.FeatureTag == LightBirdCompanionAnimTags::LaunchBlocked)
		{
			MoveComp.RotateTowardsDirection(CompanionComp.LaunchObstructionLoc - Owner.ActorLocation, 1.0, DeltaTime, Movement);
		}
		else
		{
			// Rotate to match velocity
			FRotator Rotation = MoveComp.GetRotationTowardsDirection(Delta, Settings.LaunchTurnDuration, DeltaTime);
			Movement.SetRotation(Rotation);
		}

		AudioComp.LaunchDistanceAlpha = Alpha;

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			float Interval = 0.01;
			FVector PrevLoc = StartLocation;
			for (float DbgAlpha = Interval; DbgAlpha < 1.0; DbgAlpha += Interval)
			{
				FVector CurveLoc = BezierCurve::GetLocation_3CP_ConstantSpeed(StartLocation, StartControl, CenterControl, EndControl, Destination, DbgAlpha);
				Debug::DrawDebugLine(PrevLoc, CurveLoc, FLinearColor::Yellow, 3.0);
				PrevLoc = CurveLoc;
			} 

			Debug::DrawDebugLine(StartLocation, StartControl, FLinearColor::LucBlue, 1);
			Debug::DrawDebugLine(StartControl, CenterControl, FLinearColor::LucBlue, 1);
			Debug::DrawDebugLine(EndControl, CenterControl, FLinearColor::LucBlue, 1);
			Debug::DrawDebugLine(EndControl, Destination, FLinearColor::LucBlue, 1);
			// Debug::DrawDebugString(CenterControl, "Center");
			// Debug::DrawDebugString(StartControl, "StartControl");
			// Debug::DrawDebugString(EndControl, "EndControl");
		}
#endif		
	}
};