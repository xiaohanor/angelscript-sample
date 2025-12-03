struct FGeckoDodgeBladeParams
{
	AHazeActor Attacker;
	FVector DodgeDestination;
	FSplinePosition SplinePos;
}

class USkylineGeckoDodgeBladeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineGeckoComponent GeckoComp;
	UGravityBladeCombatUserComponent MioBladeComp;
	UPlayerTargetablesComponent MioTargetables;
	UGravityBladeGrappleComponent GrappleComp;
	UGravityBladeCombatTargetComponent BladeTargetComp;
	
	USkylineGeckoSettings Settings;
	FVector Destination;
	FSplinePosition SplineDestination;
	AHazeActor Attacker;
	float DodgeDuration;
	float LastDodgeEndTime = -BIG_NUMBER;
	int NumDodgesInARow = 0;

	USceneComponent GrappleAttachParent;
	FName GrappleAttachSocket;

	float LastCombatGrappleTime = -BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
		MioBladeComp = UGravityBladeCombatUserComponent::Get(Game::Mio);
		MioTargetables = UPlayerTargetablesComponent::Get(Game::Mio);
		GrappleComp = UGravityBladeGrappleComponent::Get(Owner);
		BladeTargetComp = UGravityBladeCombatTargetComponent::Get(Owner);
		BladeTargetComp.OnCombatGrappleActivation.AddUFunction(this, n"OnCombatGrappleStarted");
		Settings = USkylineGeckoSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnCombatGrappleStarted()
	{
		LastCombatGrappleTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && (NumDodgesInARow > 0) && (Time::GetGameTimeSince(LastDodgeEndTime) > 1.0))
			NumDodgesInARow = 0;

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			if (!GeckoComp.bAllowBladeHits.Get())
				Debug::DrawDebugString(Owner.ActorLocation, "NO BLADE HITS", FLinearColor::Green, 0.0, 1.5);
		}
#endif
	}

	AHazePlayerCharacter GetAttacker() const
	{
		FVector OwnLoc = Owner.ActorCenterLocation;
		if (IsValid(MioBladeComp) && (MioBladeComp.HasActiveAttack() || MioBladeComp.HasPendingAttack()))
		{
			// Mio is attacking
			FVector MioLoc = Game::Mio.ActorCenterLocation;
			if (MioLoc.IsWithinDist(OwnLoc, 300.0) && 
				(Game::Mio.ViewRotation.ForwardVector.DotProduct(OwnLoc - MioLoc) > 0.0))
				return Game::Mio;
			if (MioLoc.IsWithinDist(OwnLoc, 600.0) &&
				((MioBladeComp.ActiveAttackData.IsValid() && IsValid(MioBladeComp.ActiveAttackData.Target) && (MioBladeComp.ActiveAttackData.Target.Owner == Owner)) ||
				 (MioBladeComp.PendingAttackData.IsValid() && IsValid(MioBladeComp.PendingAttackData.Target) && (MioBladeComp.PendingAttackData.Target.Owner == Owner))))
				return Game::Mio;
		}

		return nullptr;
	}

	FVector GetDodgeDestination(AHazePlayerCharacter CurAttacker, FSplinePosition& SplinePos) const
	{
		if (NumDodgesInARow >= Settings.DodgeToSplineAfterDodgesInARow)
		{
			// Try to dodge to a spline if possible
			SplinePos = GeckoComp.FindClosestSplinePositionInFrontOfPlayer(CurAttacker, Settings.DodgeBladeDistance * 4.0);
			if (SplinePos.IsValid())
				return SplinePos.WorldLocation;
		}

		FVector OwnLoc = Owner.ActorCenterLocation;
		FVector OwnNormal = Owner.ActorUpVector;
		FVector AttackerLoc = CurAttacker.ActorCenterLocation;
		FVector AwayDir = (OwnLoc - AttackerLoc).ConstrainToPlane(OwnNormal).GetSafeNormal();
		FVector DodgeDir = AwayDir;

		if (CurAttacker == Game::Mio)
		{
			// Blade attack: dodge to the side in view space
			FVector ViewFwd = CurAttacker.ViewRotation.ForwardVector;
			if (Math::Abs(ViewFwd.DotProduct(OwnNormal)) > 0.866) 
				DodgeDir = CurAttacker.ViewRotation.RightVector.ConstrainToPlane(OwnNormal).GetSafeNormal(); // View fwd is close to parallell to our plane normal, just use view right
			else
				DodgeDir = ViewFwd.CrossProduct(OwnNormal).GetSafeNormal();

			// Make sure we dodge away from view center
			FVector ViewIntersection = Math::RayPlaneIntersection(CurAttacker.ViewLocation, ViewFwd, FPlane(OwnLoc, OwnNormal));
			if (DodgeDir.DotProduct(ViewIntersection - OwnLoc) > 0.0)
				DodgeDir *= -1.0;

			// Add some direction away from attacker
			DodgeDir = DodgeDir * 0.4 + AwayDir * 0.6;
		}

		FVector DodgeDest = Owner.ActorLocation + DodgeDir * Settings.DodgeBladeDistance;
		FVector PathDest;
		if (Pathfinding::FindNavmeshLocation(DodgeDest, 80.0, 200.0, PathDest))
			return PathDest;

		// No navmesh near dodge destination, check if we can dodge to a spline instead
		SplinePos = GeckoComp.FindClosestSplinePositionInFrontOfPlayer(CurAttacker, Settings.DodgeBladeDistance * 3.0);
		if (SplinePos.IsValid())
			return SplinePos.WorldLocation;

		// No spline, look further for navmesh
		if (Pathfinding::FindNavmeshLocation(DodgeDest, Settings.DodgeBladeDistance * 2.0, 2000.0, PathDest))
			return PathDest;

		// Ok, there does not seem to be any navmesh. Just hope for the best.
		return DodgeDest;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGeckoDodgeBladeParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		
		if (!GeckoComp.bCanDodge.Get())
			return false;
		if (GeckoComp.bIsLeaping.Get())
			return false;
		if (GeckoComp.CurrentClimbSpline != nullptr)
			return false;
		
		// Only dodge if someone has already been hit by blade recently
		if (Time::GetGameTimeSince(GeckoComp.Team.LastGeckoBladeHitTime) > 0.5)
			return false;

		AHazePlayerCharacter CurAttacker = GetAttacker();
		if (CurAttacker == nullptr)
			return false;

		OutParams.Attacker = CurAttacker;	
		OutParams.DodgeDestination = GetDodgeDestination(CurAttacker, OutParams.SplinePos);	
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
	void OnActivated(FGeckoDodgeBladeParams Params)
	{
		Super::OnActivated();
		Attacker = Params.Attacker;
		Destination = Params.DodgeDestination;
		SplineDestination = Params.SplinePos;
		if (Settings.DodgeBladeInvulnerable)
			GeckoComp.bAllowBladeHits.Apply(false, this);
		DodgeDuration = Settings.DodgeDuration;
		if (SplineDestination.IsValid())
		{
			DodgeDuration *= 2.0;
			SplineDestination.MatchFacingTo((Attacker.FocusLocation - SplineDestination.WorldLocation).Rotation());
			DestinationComp.FollowSplinePosition = SplineDestination;
		}
		else
		{
			GeckoComp.bShouldLeap.Apply(true, this);
		}
		
		if (GrappleComp != nullptr)
		{
			// Grapple comp stays in place, so you'll grapple to where we were
			GrappleAttachParent = GrappleComp.AttachParent;
			GrappleAttachSocket = GrappleComp.AttachSocketName;
			GrappleComp.DetachFromParent(true);
		}
		BladeTargetComp.DetachFromParent(true);

		NumDodgesInARow++;

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
		GeckoComp.bShouldLeap.Clear(this);

		if (TargetComp.IsValidTarget(Attacker))
			TargetComp.SetTarget(Attacker); // Payback time!

		if (GrappleAttachParent != nullptr)
			GrappleComp.AttachTo(GrappleAttachParent, GrappleAttachSocket, EAttachLocation::SnapToTarget);	
		if (GrappleAttachParent != nullptr)
			BladeTargetComp.AttachTo(GrappleAttachParent, GrappleAttachSocket, EAttachLocation::SnapToTarget);	

		if (ActiveDuration > DodgeDuration * 0.5)
			Cooldown.Set(Settings.DodgeBladeCooldown);

		LastDodgeEndTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (SplineDestination.IsValid())
			DestinationComp.MoveAlongSpline(SplineDestination.CurrentSpline, Settings.DodgeSpeed, SplineDestination.IsForwardOnSpline());
		else
			DestinationComp.MoveTowardsIgnorePathfinding(Destination, Settings.DodgeSpeed);
		DestinationComp.RotateTowards(Attacker);
		
		// We can hit gecko in second half of dodge if we're quick enough
		if (ActiveDuration > DodgeDuration * 0.5)
			GeckoComp.bAllowBladeHits.Clear(this);
	}
}