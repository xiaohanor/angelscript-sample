// Find any target in awareness range.
class UIslandBeamTurretronFindClosestTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	private AHazeActor ClosestTarget;

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

		if (TargetComp.HasValidTarget())
			return false;
		
		if (ClosestTarget == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TargetComp.SetTarget(ClosestTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ClosestTarget = nullptr;
	}

	float NextCheckTimer;
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;
		
		if (TargetComp.HasValidTarget())
			return;

		// limit number of checks
		NextCheckTimer -=DeltaTime;
		if (NextCheckTimer > 0)
			return;
		NextCheckTimer = 0.1 + Math::RandRange(0.01, 0.1);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Owner.ActorCenterLocation, Settings.AwarenessRange, LineColor = FLinearColor::Red, Duration = 1.0);			
		}
#endif
		
		// Find any target in awareness range.
		TArray<AHazeActor> TargetsInRange;
		TargetComp.FindAllTargets(Settings.AwarenessRange, TargetsInRange);
		
		float BestDistSqr = MAX_flt;
		AHazeActor BestTarget;
		for (AHazeActor Target : TargetsInRange)
		{
			float Dist = Target.FocusLocation.DistSquared(Owner.FocusLocation);
			if (Dist < BestDistSqr)
			{
				if (!TargetComp.IsValidTarget(Target))
					continue;

				if (!PerceptionComp.Sight.VisibilityExists(Owner, Target, CollisionChannel = ECollisionChannel::WorldGeometry))
					continue;

				BestDistSqr = Dist;
				BestTarget = Target;
			}
		}

		ClosestTarget = BestTarget;
	}
}
