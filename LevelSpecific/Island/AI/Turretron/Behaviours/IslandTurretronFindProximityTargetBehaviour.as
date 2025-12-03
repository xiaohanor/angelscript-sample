// Refocus when a target lingers to long nearby and is not the current target
class UIslandTurretronFindProximityTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	AHazeActor ProximityTarget;
	float ProximityTimestamp;

	UIslandTurretronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandTurretronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		// Skip waiting for proximity duration
		if (!TargetComp.HasValidTarget() && TargetComp.IsValidTarget(ProximityTarget))
			return true;

		if(ProximityTimestamp == 0 || Time::GetGameTimeSince(ProximityTimestamp) <= Settings.RetargetOnProximityDuration)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		
		if (TargetComp.Target != ProximityTarget)
			return true; // A new proximity target has entered the fray

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
		ProximityTimestamp = 0.0;
		ProximityTarget = nullptr;
	}

	float NextCheckTimer;
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;
		if (!TargetComp.HasValidTarget()) // Must have some target to switch from.
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
		}
#endif	

		for (AHazePlayerCharacter Target : Game::Players)
		{
			// Skip current target from consideration
			if (Target == TargetComp.Target)
				continue;
			
			// Check that potential target is within range.
			const float RangeSquared = Settings.RetargetOnProximityRange * Settings.RetargetOnProximityRange;
			if(Target.GetSquaredDistanceTo(Owner) > RangeSquared)
				continue;

			// if potential target is further away and we have current target within sight.
			const float SwitchClosestTargetTresholdDistSqr = Settings.SwitchClosestTargetTresholdDist * Settings.SwitchClosestTargetTresholdDist;
			if (Owner.GetSquaredDistanceTo(Target) + SwitchClosestTargetTresholdDistSqr > Owner.GetSquaredDistanceTo(TargetComp.Target) && TargetComp.HasGeometryVisibleTarget())
			{
				ProximityTimestamp = 0.0; // reset timestamp, keep current target
				continue;
			}

			// check that potential target is visible
			if (!PerceptionComp.Sight.VisibilityExists(Owner, Target))
			{
				ProximityTimestamp = 0.0; // reset timestamp
				ProximityTarget = nullptr; // forget proximity target
			}
			else
			{
				if(ProximityTimestamp != 0 && ProximityTarget == Target)
					return;	// already counting down to switching to this target
				// new proximity target found, set timestamp
				ProximityTarget = Target;
				ProximityTimestamp = Time::GetGameTimeSeconds();
			}
		}
	}	
}
