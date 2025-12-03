class USummitCritterSwarmHurtRecoilBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCritterSwarmComponent SwarmComp;
	UBasicAIHealthComponent HealthComp;
	USummitCritterSwarmSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SwarmComp = USummitCritterSwarmComponent::GetOrCreate(Owner);
		Settings = USummitCritterSwarmSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) > Settings.HurtRecoilDuration) 
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget() && (ActiveDuration > 1.0))
			return true;
		if (ActiveDuration > Settings.HurtRecoilDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (ActiveDuration > Settings.HurtRecoilDuration * 0.25)
			Cooldown.Set(Settings.HurtRecoilCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = OwnLoc; 
		FVector EvadeDest;
		UPlayerSplineLockComponent SplineLockComp = UPlayerSplineLockComponent::Get(Game::Zoe);
		if ((SplineLockComp != nullptr) && (SplineLockComp.CurrentSpline != nullptr))
		{
			// Fly away ahead of player spline when hurt by acid
			FSplinePosition SplinePos = SplineLockComp.GetSplinePosition();
			FVector SplineAheadLoc = SplinePos.WorldLocation + SplinePos.WorldForwardVector * Settings.HurtRecoilRange * 3.0 + FVector(0.0, 0.0, 1000);
			FVector Away = OwnLoc - SplinePos.WorldLocation;
			Away.Z *= 0.1; // Mostly horizontal
			FVector AwayLoc = SplinePos.WorldLocation + Away.GetSafeNormal() * Settings.HurtRecoilRange;
			EvadeDest = Math::Lerp(AwayLoc, SplineAheadLoc, ActiveDuration / Math::Max(Settings.HurtRecoilDuration, 0.5));
		}
		else 
		{
			// Not on spline, fly away and to the side from target
			TargetLoc += Owner.ActorVelocity * 10.0 + Owner.ActorForwardVector * 100.0;
			FVector SideAwayDir = FVector::ZeroVector;
			if (TargetComp.HasValidTarget()) 
			{
				TargetLoc = TargetComp.Target.ActorCenterLocation;
				FVector TargetDir = Cast<AHazePlayerCharacter>(TargetComp.Target).GetViewRotation().Vector();
				SideAwayDir = (OwnLoc - TargetLoc.PointPlaneProject(OwnLoc, TargetDir)).GetSafeNormal();	
			}

			// Evade more to the side when close or past evade range
			FVector EvadeDir = (OwnLoc - TargetLoc) + Owner.ActorVelocity * 1.0;
			if (OwnLoc.IsWithinDist(TargetLoc, Settings.HurtRecoilRange))
				EvadeDir += (SideAwayDir * Settings.HurtRecoilRange) * 0.2;
			else
				EvadeDir = SideAwayDir;
			EvadeDir.Z *= 0.1; // Mostly horizontal
			EvadeDir = EvadeDir.GetSafeNormal();
			EvadeDest = Owner.ActorLocation + EvadeDir * 1000.0;
		}

		DestinationComp.MoveTowards(EvadeDest, Settings.HurtRecoilSpeed);

		SwarmComp.AggroTime = Time::GameTimeSeconds;

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(TargetLoc + FVector(0,0,400), 100, 4, FLinearColor::Yellow, 10);
			Debug::DrawDebugLine(OwnLoc, EvadeDest, FLinearColor::Yellow, 100);
			Debug::DrawDebugSphere(EvadeDest, 200, 5, FLinearColor(1.0, 0.3, 0.0), 10);
		}
#endif
	}
}
