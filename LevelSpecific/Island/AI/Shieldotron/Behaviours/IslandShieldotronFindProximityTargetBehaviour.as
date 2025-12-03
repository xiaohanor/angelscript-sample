// Will find a target and otherwise refocus when a target lingers too long nearby and the current target is out of range or not visible.
class UIslandShieldotronFindProximityTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	private AHazeActor ProximityTarget;
	private float ProximityTime;

	UIslandShieldotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		// Skip waiting for proximity duration
		if (!TargetComp.HasValidTarget() && ProximityTarget != nullptr)
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
		float DrawDuration = 0.2;
		Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Owner.ActorCenterLocation, Settings.RetargetOnProximityRange, LineColor = FLinearColor::Red, Duration = DrawDuration);
			PrintToScreen("ProximityTarget = " + ProximityTarget, Duration = DrawDuration);
			PrintToScreen("ProximityTime = " + ProximityTime, Duration = DrawDuration);
			PrintToScreen("TargetComp.Target = " + TargetComp.Target, Duration = DrawDuration);
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
			
			// Otherwise, compare
			float Dist = Target.FocusLocation.DistSquared(Owner.FocusLocation);
			if (Dist < BestDistSqr)
			{
				if (PerceptionComp.Sight.VisibilityExists(Owner, Target, CollisionChannel = ECollisionChannel::WorldGeometry))
				{
					BestDistSqr = Dist;
					BestTarget = Target;

#if EDITOR
					FVector Origin = Owner.ActorLocation + Owner.ActorUpVector * 100.0;
					float Size = 2.0;			
					Debug::DrawDebugLine(Origin, Target.ActorLocation, FLinearColor::Red, Size, DrawDuration);
					float DistToTarget = Owner.ActorLocation.Distance(Target.ActorLocation);
					Debug::DrawDebugString(Target.ActorLocation - (Target.ActorLocation - Origin).GetSafeNormal() * 80.0 + Target.ActorUpVector * 20.0, "" + Math::RoundToInt(DistToTarget), Scale = Size, Duration = DrawDuration);
#endif
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
