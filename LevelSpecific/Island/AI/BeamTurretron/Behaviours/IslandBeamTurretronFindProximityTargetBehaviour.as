// Will find a target and otherwise refocus when a target lingers too long nearby and the current target is out of range or not visible.
class UIslandBeamTurretronFindProximityTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	private AHazeActor ProximityTarget;
	private float ProximityTime;

	UIslandBeamTurretronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandBeamTurretronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		// Skip waiting for proximity duration
		if (!TargetComp.HasValidTarget() && TargetComp.IsValidTarget(ProximityTarget))
			return true;

		if(ProximityTime == 0 || Time::GetGameTimeSince(ProximityTime) <= Settings.RetargetOnProximityDuration)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if (TargetComp.HasValidTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TargetComp.SetTarget(ProximityTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ProximityTime = 0.0;
		ProximityTarget = nullptr;
	}

	float NextCheckTimer;
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		// limit number of checks
		NextCheckTimer -=DeltaTime;
		if (NextCheckTimer > 0)
			return;
		NextCheckTimer = 0.2;

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Owner.ActorCenterLocation, Settings.RetargetOnProximityRange, LineColor = FLinearColor::Red, Duration = 1.0);
			PrintToScreen("ProximityTarget = " + ProximityTarget);
			PrintToScreen("ProximityTime = " + ProximityTime);
			PrintToScreen("TargetComp.Target = " + TargetComp.Target);
		}
#endif
		
		TArray<AHazeActor> ProximityTargets;
		TargetComp.FindAllTargets(Settings.RetargetOnProximityRange, ProximityTargets);
		
		float BestDistSqr = MAX_flt;
		AHazeActor BestTarget;
		for (AHazeActor Target : ProximityTargets)
		{			
			// Keep current target if it is within proximity range and is visible
			if (Target == TargetComp.Target && TargetComp.HasGeometryVisibleTarget())
				return;
			
			// Otherwises, compare
			float Dist = Target.FocusLocation.DistSquared(Owner.FocusLocation);
			if (Dist < BestDistSqr)
			{
				if (PerceptionComp.Sight.VisibilityExists(Owner, Target, CollisionChannel = ECollisionChannel::WorldGeometry))
				{
					BestDistSqr = Dist;
					BestTarget = Target;
				}
			}

		}

		if(BestTarget != nullptr && BestTarget != TargetComp.Target)
		{			
			// Skip setting new timestamp if ProximityTarget is already assigned to best target
			if(ProximityTime > 0 && ProximityTarget == BestTarget)
				return;
			ProximityTarget = BestTarget;
			ProximityTime = Time::GetGameTimeSeconds();
		}
		else
		{			
			ProximityTime = 0.0;
		}
	}
}
