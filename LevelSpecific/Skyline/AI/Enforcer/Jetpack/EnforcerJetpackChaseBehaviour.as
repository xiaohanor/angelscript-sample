class UEnforcerJetpackChaseBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(n"Jetpack");
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 
	default Requirements.Add(EBasicBehaviourRequirement::Weapon); 

	UEnforcerJetpackSettings JetpackSettings;

	float IsWithinDistanceDuration;
	FVector FromLocation;
	FVector ToLocation;
	bool bValidPath = false;
	FRotator RotationDir;
	bool StartedMoving;
	bool StartedLanding;
	float Radius;

	UBasicAICharacterMovementComponent MoveComp;
	UEnforcerJetpackComponent JetpackComp;
	UFitnessStrafingComponent FitnessStrafingComp;
	UArcTraversalComponent TraversalComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		JetpackSettings = UEnforcerJetpackSettings::GetSettings(Owner);		
		JetpackComp = UEnforcerJetpackComponent::Get(Owner);
		FitnessStrafingComp = UFitnessStrafingComponent::GetOrCreate(Owner);
		TraversalComp = UArcTraversalComponent::Get(Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!JetpackComp.CanUseJetpack())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if(Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, JetpackSettings.ChaseTriggerMinDistance))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if(!bValidPath)
			return true;

		if(ActiveDuration > JetpackSettings.ChaseStartDuration + JetpackSettings.ChaseLeapDuration + JetpackSettings.ChaseLandDuration)
			return true;

		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		StartedMoving = false;
		StartedLanding = false;
		FromLocation = Owner.ActorLocation;

		FVector Dir = (TargetComp.Target.ActorLocation - FromLocation).GetSafeNormal();
		ToLocation = FromLocation + Dir * JetpackSettings.ChaseDistance;
		RotationDir = Dir.Rotation();

		FVector PathLocation = ToLocation + (ToLocation - FromLocation).GetSafeNormal() * Radius;
		bValidPath = Pathfinding::FindNavmeshLocation(PathLocation, 0, JetpackSettings.ChaseHeight * 2, ToLocation) && Pathfinding::StraightPathExists(FromLocation, ToLocation);
		if(!bValidPath)
			return;

		// Don't start jetpack if we don't have a valid path
		UEnforcerJetpackEffectHandler::Trigger_JetpackStart(Owner);
		JetpackComp.StartJetpack();
		JetpackComp.OnChaseStart();

		FBasicAIAnimationActionDurations Durations;
		Durations.Anticipation = JetpackSettings.ChaseStartDuration;
		Durations.Action = JetpackSettings.ChaseLeapDuration;
		Durations.Recovery = JetpackSettings.ChaseLandDuration;
		FVector Move = (ToLocation - FromLocation) + Owner.ActorUpVector * JetpackSettings.ChaseHeight;
		AnimComp.RequestAction(LocomotionFeatureAISkylineTags::JetpackLeapForward, EBasicBehaviourPriority::Medium, this, Durations, Move);
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(ToLocation, FromLocation, FLinearColor::Yellow, 10, Durations.GetTotal());
			Debug::DrawDebugLine(FromLocation, FromLocation + FVector(0,0,200), FLinearColor::Yellow, 10, Durations.GetTotal());
			Debug::DrawDebugLine(ToLocation, ToLocation + FVector(0,0,200), FLinearColor::Yellow, 10, Durations.GetTotal());
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
		JetpackComp.StopJetpack();
		IsWithinDistanceDuration = 0;
		Cooldown.Set(JetpackSettings.ChaseCooldownDuration);
		FitnessStrafingComp.OptimizeStrafeDirection();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bValidPath)
			return;

		DestinationComp.RotateInDirection(ToLocation-FromLocation);

		if(ActiveDuration > JetpackSettings.ChaseStartDuration && !StartedMoving)
		{
			UEnforcerJetpackEffectHandler::Trigger_JetpackTravel(Owner);
			StartedMoving = true;
		}

		if(StartLanding() && !StartedLanding)
		{
			UEnforcerJetpackEffectHandler::Trigger_JetpackEnd(Owner);
			StartedLanding = true;
		}	
	}

	private bool StartLanding()
	{
		if(ActiveDuration > JetpackSettings.ChaseLeapDuration + JetpackSettings.ChaseStartDuration)
			return true;

		return false;
	}
}