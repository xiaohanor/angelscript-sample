
class UEnforcerJetpackCircleStrafeBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(n"Jetpack");

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	bool bTriedBothDirections = false;
	float Duration;
	bool StartedMoving;
	bool StartedLanding;
	float Radius;

	UEnforcerJetpackComponent JetpackComp;
	UEnforcerJetpackSettings JetpackSettings;
	UBasicAICharacterMovementComponent MoveComp;
	UFitnessStrafingComponent FitnessStrafingComp;
	UFitnessUserComponent FitnessComp;
	UArcTraversalComponent TraversalComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		JetpackSettings = UEnforcerJetpackSettings::GetSettings(Owner);		
		JetpackComp = UEnforcerJetpackComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		FitnessStrafingComp = UFitnessStrafingComponent::GetOrCreate(Owner);
		FitnessComp = UFitnessUserComponent::GetOrCreate(Owner);
		TraversalComp = UArcTraversalComponent::Get(Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!JetpackComp.CanUseJetpack())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Math::Min(BasicSettings.CircleStrafeEnterRange, BasicSettings.CircleStrafeMaxRange)))
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.CircleStrafeMinRange))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;

		if(ActiveDuration > JetpackSettings.CircleStrafeStartDuration + Duration + JetpackSettings.CircleStrafeLandDuration)
			return true;

		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector Side = Owner.ActorUpVector.CrossProduct(TargetLoc - OwnLoc).GetSafeNormal();
		float CircleRadius = TargetLoc.Distance(OwnLoc);
		float Angle = Math::RadiansToDegrees(JetpackSettings.CircleStrafeDistance / CircleRadius) * (FitnessStrafingComp.bStrafeLeft ? 1.0 : -1.0);
		FVector ToLocation = (OwnLoc - TargetLoc).RotateAngleAxis(Angle, Owner.ActorUpVector) + TargetLoc;
		FVector PathLocation = ToLocation + (ToLocation - OwnLoc).GetSafeNormal() * Radius;

		if(!Pathfinding::FindNavmeshLocation(PathLocation, 0, JetpackSettings.CircleStrafeHeight * 2.0, ToLocation) || !Pathfinding::StraightPathExists(OwnLoc, ToLocation) || !PerceptionComp.Sight.VisibilityExists(Owner, TargetComp.Target, (ToLocation-OwnLoc)))
		{
			Cooldown.Set(1.0);
			return;
		}

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player != nullptr && !FitnessComp.ShouldMoveToLocation(Player, ToLocation))
		{
			Cooldown.Set(1.0);
			return;
		}

		JetpackComp.StartJetpack();
		bTriedBothDirections = false;
		StartedLanding = false;
		StartedMoving = false;
		Duration = Math::RandRange(JetpackSettings.CircleStrafeMinLeapDuration, JetpackSettings.CircleStrafeMaxLeapDuration);
		UEnforcerJetpackEffectHandler::Trigger_JetpackStart(Owner);

		FBasicAIAnimationActionDurations Durations;
		Durations.Anticipation = JetpackSettings.CircleStrafeStartDuration;
		Durations.Action = Duration;
		Durations.Recovery = JetpackSettings.CircleStrafeLandDuration;

		FName Tag = (FitnessStrafingComp.bStrafeLeft ? LocomotionFeatureAISkylineTags::JetpackLeapLeft : LocomotionFeatureAISkylineTags::JetpackLeapRight);
		FVector Move = ToLocation - OwnLoc;
		Move += Owner.ActorUpVector * JetpackSettings.CircleStrafeHeight;
		AnimComp.RequestAction(Tag, EBasicBehaviourPriority::Medium, this, Durations, Move);
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + Side * JetpackSettings.CircleStrafeDistance * (FitnessStrafingComp.bStrafeLeft ? -1.0 : 1.0), FLinearColor::Yellow, 10, Durations.GetTotal());
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + FVector(0,0,200), FLinearColor::Yellow, 10, Durations.GetTotal());
			Debug::DrawDebugLine(Owner.ActorLocation + Side * JetpackSettings.CircleStrafeDistance * (FitnessStrafingComp.bStrafeLeft ? -1.0 : 1.0), Owner.ActorLocation + Side * JetpackSettings.CircleStrafeDistance * (FitnessStrafingComp.bStrafeLeft ? -1.0 : 1.0) + FVector(0,0,200), FLinearColor::Yellow, 10, Durations.GetTotal());
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		JetpackComp.StopJetpack();
		Cooldown.Set(Math::RandRange(JetpackSettings.CircleStrafeMinCooldownDuration, JetpackSettings.CircleStrafeMaxCooldownDuration));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		DestinationComp.RotateTowards(TargetComp.Target);

		if(ActiveDuration > JetpackSettings.CircleStrafeStartDuration && !StartedMoving)
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
		if (ActiveDuration > Duration + JetpackSettings.CircleStrafeStartDuration)
			return true;

		return false;
	}
}