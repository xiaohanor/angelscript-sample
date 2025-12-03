class UEnforcerJetpackRetreatBehaviour : UBasicBehaviour
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
		if (!JetpackComp.CanUseJetpack())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if(IsWithinDistanceDuration < JetpackSettings.RetreatWaitDuration)
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

		if(ActiveDuration > JetpackSettings.RetreatStartDuration + JetpackSettings.RetreatLeapDuration + JetpackSettings.RetreatLandDuration)
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

		ToLocation = GetToLocation(Math::RandRange(-1.0, 1.0) * JetpackSettings.RetreatMaxAngle);
		FVector PathLocation = ToLocation + (ToLocation - FromLocation).GetSafeNormal() * Radius;
		
		bValidPath = Pathfinding::FindNavmeshLocation(PathLocation, 0, JetpackSettings.RetreatHeight * 2, ToLocation) && Pathfinding::StraightPathExists(FromLocation, ToLocation);
		if(!bValidPath)
		{
			TArray<float> StandardRotations;
			StandardRotations.Add(0);
			StandardRotations.Add(JetpackSettings.RetreatMaxAngle);
			StandardRotations.Add(-JetpackSettings.RetreatMaxAngle);

			for(float StandardRotation: StandardRotations)
			{
				ToLocation = GetToLocation(StandardRotation);	
				PathLocation = ToLocation + (ToLocation - FromLocation).GetSafeNormal() * Radius;			
				if(Pathfinding::FindNavmeshLocation(PathLocation, 0, JetpackSettings.RetreatHeight * 2, ToLocation) && Pathfinding::StraightPathExists(FromLocation, ToLocation))
				{
					bValidPath = true;
					break;
				}
			}				
		}

		if(!bValidPath)
			return;

		// Don't start jetpack if we don't have a valid path
		UEnforcerJetpackEffectHandler::Trigger_JetpackStart(Owner);
		JetpackComp.StartJetpack();
		JetpackComp.OnRetreatStart();

		FBasicAIAnimationActionDurations Durations;
		Durations.Anticipation = JetpackSettings.RetreatStartDuration;
		Durations.Action = JetpackSettings.RetreatLeapDuration;
		Durations.Recovery = JetpackSettings.RetreatLandDuration;
		FVector Move = (ToLocation - FromLocation) + Owner.ActorUpVector * JetpackSettings.RetreatHeight;
		AnimComp.RequestAction(LocomotionFeatureAISkylineTags::JetpackLeapBackward, EBasicBehaviourPriority::Medium, this, Durations, Move);
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

	private FVector GetToLocation(float Rotation)
	{
		FVector Dir = (FromLocation - TargetComp.Target.ActorLocation).GetSafeNormal();
		FRotator Rotate; 
		Rotate.Yaw = Rotation;
		Dir = Rotate.RotateVector(Dir);
		return TargetComp.Target.ActorLocation + Dir * JetpackSettings.RetreatDistance;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
		JetpackComp.StopJetpack();
		IsWithinDistanceDuration = 0;		
		Cooldown.Set(JetpackSettings.RetreatCooldownDuration);
		FitnessStrafingComp.OptimizeStrafeDirection();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bValidPath)
			return;

		DestinationComp.RotateInDirection(FromLocation - ToLocation);

		if(ActiveDuration > JetpackSettings.RetreatStartDuration && !StartedMoving)
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
		if(ActiveDuration > JetpackSettings.RetreatLeapDuration + JetpackSettings.RetreatStartDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive())
			return;

		if(TargetComp.HasValidTarget() && Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, JetpackSettings.RetreatTriggerDistance))
		{
			IsWithinDistanceDuration += DeltaTime;
		}
		else
		{
			IsWithinDistanceDuration = 0;
		}
	}
}