struct FGeckoDodgeWhipParams
{
	FVector DodgeDestination;
}

class USkylineGeckoDodgeWhipBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineGeckoComponent GeckoComp;
	UGravityWhipUserComponent ZoeWhipComp;
	
	USkylineGeckoSettings Settings;
	FVector Destination;
	AHazeActor Attacker;
	float DodgeDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
		ZoeWhipComp = UGravityWhipUserComponent::Get(Game::Zoe);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	bool IsAttackedByWhip() const
	{
		if (!IsValid(ZoeWhipComp)) 
			return false;

		if (!ZoeWhipComp.bIsAirGrabbing && !ZoeWhipComp.IsGrabbingAny())
			return false; // No whoppah
		
		FVector OwnLoc = Owner.ActorCenterLocation;
		FVector ZoeLoc = Game::Zoe.ActorCenterLocation;
		if (!ZoeLoc.IsWithinDist(OwnLoc, Settings.DodgeWhipThreatRange))
			return false; // Far away

		FVector ViewFwd = Game::Zoe.ViewRotation.ForwardVector;
		if (ViewFwd.DotProduct(OwnLoc - ZoeLoc) < 0.0)
			return false; // Behind

		FVector WhipStart = (Game::Zoe.FocusLocation + ViewFwd * 300.0);
		FVector WhipEnd = Game::Zoe.FocusLocation + ViewFwd * (Settings.DodgeWhipThreatRange - 300.0);
		FVector LineLoc; float Dummy;
		Math::ProjectPositionOnLineSegment(WhipStart, WhipEnd, OwnLoc, LineLoc, Dummy);
		if (!LineLoc.IsWithinDist(OwnLoc, 200.0))
			return false;	// Not near danger line

		return true;
	}

	bool FindDodgeDestination(AHazeActor CurAttacker, FVector& OutDest) const
	{
		FVector OwnLoc = Owner.ActorCenterLocation;
		FVector OwnNormal = Owner.ActorUpVector;
		FVector AttackerLoc = CurAttacker.ActorCenterLocation;
		FVector AwayDir = (OwnLoc - AttackerLoc).ConstrainToPlane(OwnNormal).GetSafeNormal();
		FVector DodgeDir = AwayDir;

		if (CurAttacker == Game::Zoe)
		{
			// Dodge to the side in view space
			FVector ViewFwd = Game::Zoe.ViewRotation.ForwardVector;
			if (Math::Abs(ViewFwd.DotProduct(OwnNormal)) > 0.866) 
				DodgeDir = Game::Zoe.ViewRotation.RightVector.ConstrainToPlane(OwnNormal).GetSafeNormal(); // View fwd is close to parallell to our plane normal, just use view right
			else
				DodgeDir = ViewFwd.CrossProduct(OwnNormal).GetSafeNormal();

			// Make sure we dodge away from view center
			FVector ViewIntersection = Math::RayPlaneIntersection(Game::Zoe.ViewLocation, ViewFwd, FPlane(OwnLoc, OwnNormal));
			if (DodgeDir.DotProduct(ViewIntersection - OwnLoc) > 0.0)
				DodgeDir *= -1.0;

			// Add some direction away from attacker when close or towards attacker when far away
			if (OwnLoc.IsWithinDist(AttackerLoc, Settings.DodgeWhipThreatRange * 0.4))
				DodgeDir = DodgeDir * 0.8 + AwayDir * 0.2;
			else
				DodgeDir = DodgeDir * 0.8 - AwayDir * 0.2;
		}

		FVector DodgeDest = Owner.ActorLocation + DodgeDir * Settings.DodgeWhipDistance;
		FVector PathDest;
		if (!Pathfinding::FindNavmeshLocation(DodgeDest, Settings.DodgeWhipDistance * 2.0, 2000.0, PathDest))
			return false;

		OutDest = PathDest;	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGeckoDodgeWhipParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!GeckoComp.bCanDodge.Get())
			return false;
		if (GeckoComp.bIsLeaping.Get())
			return false;
		if (GeckoComp.CurrentClimbSpline != nullptr)
			return false;

		if (!IsAttackedByWhip())
			return false;

		FVector DodgeDest;
		if (!FindDodgeDestination(Game::Zoe, DodgeDest))
			return false; 		
		OutParams.DodgeDestination = DodgeDest;	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > DodgeDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGeckoDodgeWhipParams Params)
	{
		Super::OnActivated();
		Attacker = Game::Zoe;
		Destination = Params.DodgeDestination;
		GeckoComp.bAllowBladeHits.Apply(false, this);
		DodgeDuration = Settings.DodgeDuration;
		
		// Start with a push-off
		FVector ImpulseDir = (Destination - Owner.ActorLocation).GetSafeNormal() * 0.4 + Owner.ActorUpVector * 0.6;
		Owner.AddMovementImpulse(ImpulseDir * Settings.DodgeSpeed * 0.25);

		AnimComp.RequestFeature(FeatureTagGecko::Dodge, EBasicBehaviourPriority::Medium, this);

		GeckoComp.LastDodgeStartTime = Time::GameTimeSeconds;

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSphere(Owner.ActorLocation, 100, 12, FLinearColor::Yellow, 3.0, 1.0);		
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GeckoComp.bAllowBladeHits.Clear(this);
		if (TargetComp.IsValidTarget(Attacker))
			TargetComp.SetTarget(Attacker); // Payback time!

		// if (ActiveDuration > DodgeDuration * 0.5)
		// 	Cooldown.Set(Settings.DodgeCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		DestinationComp.MoveTowardsIgnorePathfinding(Destination, Settings.DodgeSpeed);
		DestinationComp.RotateTowards(Attacker);
	}
}