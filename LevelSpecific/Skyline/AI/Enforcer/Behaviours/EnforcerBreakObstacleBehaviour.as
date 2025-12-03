class UEnforcerBreakObstacleBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineEnforcerSettings Settings;

	float TelegraphDuration = 0.6;
	float AnticipationDuration = 0.4;
	float AttackDuration = 0.3;
	float RecoveryDuration = 1.0;

	AWhipSlingableObject TargetObstacle;

	bool bHasHit = false;
	float TraceTimer = 0;
	const float TraceTimeInterval = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineEnforcerSettings::GetSettings(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (TargetObstacle == nullptr)
			return false;

		return true;
	}



	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (ActiveDuration > TelegraphDuration + AnticipationDuration + AttackDuration + RecoveryDuration)
			return true;

		if (TargetObstacle == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		FBasicAIAnimationActionDurations AttackDurations;
		AttackDurations.Telegraph = TelegraphDuration;
		AttackDurations.Anticipation = AnticipationDuration;
		AttackDurations.Action = AttackDuration; 
		AttackDurations.Recovery = RecoveryDuration;
		AnimComp.RequestAction(LocomotionFeatureAISkylineTags::EnforcerMeleeAttack, EBasicBehaviourPriority::Medium, this, AttackDurations);	
		
		bHasHit = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);
		TargetObstacle = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		TraceTimer -= DeltaTime;
		if (TraceTimer < 0 && TargetObstacle == nullptr)
		{
			TraceTimer = TraceTimeInterval;
			FVector HitSphereLocation = Owner.ActorLocation + Owner.ActorForwardVector * Settings.MeleeAttackActivationRange;
			float HitSphereRadius = 10;
			AWhipSlingableObject Object = TraceForObstacle(HitSphereLocation, HitSphereRadius);
			if (Object == nullptr)
				return;
			if (Owner.ActorLocation.IsWithinDist(Object.ActorLocation, Settings.MeleeAttackActivationRange))
				CrumbSetTargetObstacle(Object);
		}

	}

	UFUNCTION(CrumbFunction)
	void CrumbSetTargetObstacle(AWhipSlingableObject Target)
	{
		TargetObstacle = Target;
	}

	private AWhipSlingableObject TraceForObstacle(FVector HitSphereLocation, float Radius) const
	{		
		FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::WorldDynamic);
		Trace.UseSphereShape(Radius);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(HitSphereLocation);
		for (FOverlapResult Overlap : Overlaps.OverlapResults)
		{
			if (Overlap.Actor == nullptr)
				continue;
			if (!Overlap.Actor.HasControl())
				continue;
			AWhipSlingableObject Obstacle = Cast<AWhipSlingableObject>(Overlap.Actor);
			if (Obstacle == nullptr)
				continue;			

			return Obstacle;
		}
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraph duration, rotate towards target
		if (ActiveDuration < TelegraphDuration + AnticipationDuration)
		{
			DestinationComp.RotateTowards(TargetObstacle);
		}		
		// Attack phase duration, lock rotation
		else if (ActiveDuration < TelegraphDuration + AnticipationDuration + AttackDuration)
		{
			// Check if target is within attack radius and deal damage, draw debug sphere
			if (bHasHit)
				return;
			
			FVector HitSphereLocation = Cast<AHazeCharacter>(Owner).Mesh.GetSocketTransform(n"RightHand").GetLocation();
			float HitSphereRadius = Settings.MeleeAttackHitSphereRadius;

#if EDITOR
			// Draw hit sphere
			//Owner.bHazeEditorOnlyDebugBool = true;
			if (Owner.bHazeEditorOnlyDebugBool) 
				Debug::DrawDebugSphere(HitSphereLocation, HitSphereRadius, LineColor = FLinearColor::Green, Duration = 0.1);
#endif

			AWhipSlingableObject Obstacle = TraceForObstacle(HitSphereLocation, HitSphereRadius);
			if (Obstacle == nullptr)
				return;

			bHasHit = true;
			Obstacle.OnBreak();

		}
		
		// Recovery duration
		else if (ActiveDuration < TelegraphDuration + AttackDuration + RecoveryDuration)
		{
			DestinationComp.RotateTowards(DestinationComp.Destination);
		}		
	}
}