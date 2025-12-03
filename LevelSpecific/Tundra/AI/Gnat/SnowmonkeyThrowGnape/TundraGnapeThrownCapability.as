class UTundraGnapeThrownCapabilty : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"GnapeThrow");
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 110; // After grab

	UBasicAICharacterMovementComponent MoveComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UTundraGnatComponent GnapeComp;
	UBasicAIDestinationComponent DestComp;
	UBasicAIAnimationComponent AnimComp;
	UTundraGnatHostComponent HostComp;
	UBasicAIHealthComponent HealthComp;
	UPlayerSnowMonkeyThrowGnapeComponent ThrowerComp;
	UTundraGnapeAnnoyedPlayerComponent ZoeAnnoyedComp;	
	UTundraGnatSettings Settings;
	USimpleMovementData Movement;

	FVector CurveStart;
	FVector CurveApexControl;
	FVector CurveDestination;
	float CurveAlphaPerSecond;
	float CurveAlpha;

	FVector PrevLocation;
	FRotator HackMeshRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner); 
		GnapeComp = UTundraGnatComponent::Get(Owner);
		DestComp = UBasicAIDestinationComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ZoeAnnoyedComp = UTundraGnapeAnnoyedPlayerComponent::GetOrCreate(Game::Zoe);
		Settings = UTundraGnatSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraGnatMovementParams& OutParams) const
	{
		if (!GnapeComp.bThrownByMonkey)
			return false;
		if (DestComp.bHasPerformedMovement)
			return false;
		OutParams.HostComp = UTundraGnatHostComponent::Get(GnapeComp.Host);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.ThrownMaxDuration) 
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraGnatMovementParams Params)
	{
		// Player throw capability will network what targets to throw at etc
		ThrowerComp = UPlayerSnowMonkeyThrowGnapeComponent::Get(Game::Mio);
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		AnimComp.RequestFeature(TundraGnatTags::ThrownByMonkey, EBasicBehaviourPriority::Medium, this);

		GnapeComp.Host = Params.HostComp.Owner;
		HostComp = Params.HostComp;

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
		MoveComp.FollowComponentMovement(HostComp.Body, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Normal);
	
		FVector TargetLoc = Owner.ActorLocation + Game::Mio.ActorForwardVector * Settings.ThrownDefaultRange;
		if (IsValid(GnapeComp.ThrownAtTarget)) 
			TargetLoc = GnapeComp.ThrownAtTarget.ActorLocation; 
		
		FTransform WorldToHostTransform = HostComp.Body.WorldTransform.Inverse();
		CurveStart = WorldToHostTransform.TransformPositionNoScale(Owner.ActorLocation);
		CurveDestination = WorldToHostTransform.TransformPositionNoScale(TargetLoc);
		float HorizontalDist = CurveStart.Dist2D(CurveDestination);
		CurveApexControl = (CurveStart + CurveDestination) * 0.5; // Note that this is not true for a correct parabola, but it's fine for our purpose
		float ApexHeight = Math::GetMappedRangeValueClamped(FVector2D(400.0, Settings.ThrownSpeed), FVector2D(0.0, Settings.ThrownHeight), HorizontalDist); 
		CurveApexControl.Z = Math::Max(CurveStart.Z, CurveDestination.Z) + ApexHeight;
		CurveAlphaPerSecond = Settings.ThrownSpeed / Math::Max(1.0, HorizontalDist); 
		CurveAlpha = 0.0;

		UMovementGravitySettings::SetGravityAmount(Owner, Settings.ThrownGravity, this, EHazeSettingsPriority::Gameplay);
		UMovementGravitySettings::SetGravityScale(Owner, 1.0, this, EHazeSettingsPriority::Gameplay);

		HackMeshRot = Cast<AHazeCharacter>(Owner).Mesh.RelativeRotation;

		UTundraGnatEffectEventHandler::Trigger_OnThrownByMonkey(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		GnapeComp.bThrownByMonkey = false;

		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
		Owner.ClearSettingsByInstigator(this);

		// Die at end of throw, regardless of where we end up for now
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::MeleeBlunt, Game::Mio);

		Cast<AHazeCharacter>(Owner).Mesh.RelativeRotation = FRotator::ZeroRotator;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			ComposeMovement(DeltaTime);
		}
		else
		{
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, TundraGnatTags::ThrownByMonkey);
		DestComp.bHasPerformedMovement = true;

		// Check if we hit another gnape
		GnapeComp.CheckGnapeImpacts(ThrowerComp, ZoeAnnoyedComp);

		// HACK rotate until we have proper anim
		UHazeCharacterSkeletalMeshComponent Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		HackMeshRot.Pitch += DeltaTime * -480.0;
		Mesh.RelativeRotation = HackMeshRot;

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSphere(Owner.ActorLocation, 50.0, 4, FLinearColor::Red);
#endif		
	}

	void ComposeMovement(float DeltaTime)
	{
		if ((MoveComp.AllGroundImpacts.Num() > 0) && (CurveAlpha > 0.3))
		{
			float BounceSpeed = MoveComp.Velocity.Size() * 0.5;
			Movement.AddVelocity(MoveComp.AllGroundImpacts[0].ImpactNormal * BounceSpeed);	
			CurveAlpha = 1.0; // Bounces will interrupt curve
		}

		// Move along curve for the first ascending half, to get a nicely controllable trajectory
		if (CurveAlpha < 0.8)
		{
			CurveAlpha += CurveAlphaPerSecond * DeltaTime;
			FVector LocalLoc = BezierCurve::GetLocation_1CP(CurveStart, CurveApexControl, CurveDestination, CurveAlpha);
			FVector WorldLoc = HostComp.Body.WorldTransform.TransformPositionNoScale(LocalLoc);
			if (DeltaTime > 0.0)
			{
				FVector Velocity = (WorldLoc - Owner.ActorLocation) / DeltaTime;
				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(WorldLoc, Velocity);
			}

#if EDITOR
			if (Owner.bHazeEditorOnlyDebugBool)
				BezierCurve::DebugDraw_1CP(HostComp.Body.WorldTransform.TransformPositionNoScale(CurveStart), HostComp.Body.WorldTransform.TransformPositionNoScale(CurveApexControl), HostComp.Body.WorldTransform.TransformPositionNoScale(CurveDestination), FLinearColor::Yellow, 5.0);
#endif
		}
		else
		{
			Movement.AddVelocity(MoveComp.Velocity);
			Movement.AddGravityAcceleration();
			Movement.AddPendingImpulses();
		}
	}
}

