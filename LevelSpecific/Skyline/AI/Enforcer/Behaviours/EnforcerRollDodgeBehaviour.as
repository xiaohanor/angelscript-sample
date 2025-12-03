class UEnforcerRollDodgeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UFitnessStrafingComponent FitnessStrafingComp;
	USkylineEnforcerSettings EnforcerSettings;
	UFitnessUserComponent FitnessComp;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		FitnessStrafingComp = UFitnessStrafingComponent::GetOrCreate(Owner);
		EnforcerSettings = USkylineEnforcerSettings::GetSettings(HazeOwner);
		FitnessComp = UFitnessUserComponent::GetOrCreate(Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
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
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > EnforcerSettings.RollDodgeStartDuration + EnforcerSettings.RollDodgeDuration + EnforcerSettings.RollDodgeEndDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector Side = Owner.ActorUpVector.CrossProduct(TargetLoc - OwnLoc).GetSafeNormal() * (FitnessStrafingComp.bStrafeLeft ? -1.0 : 1.0);
		FVector ToLocation = OwnLoc + Side * EnforcerSettings.RollDodgeDistance;

		FVector PathLocation = ToLocation + Side * Radius;
		if(!Pathfinding::FindNavmeshLocation(PathLocation, 0.0, 100.0, ToLocation) || !Pathfinding::StraightPathExists(OwnLoc, ToLocation) || !PerceptionComp.Sight.VisibilityExists(Owner, TargetComp.Target, (ToLocation-OwnLoc)))
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

		auto Durations = FBasicAIAnimationActionDurations();
		Durations.Telegraph = EnforcerSettings.RollDodgeStartDuration;
		Durations.Action = EnforcerSettings.RollDodgeDuration;
		Durations.Recovery = EnforcerSettings.RollDodgeEndDuration;

		FVector Move = ToLocation - OwnLoc;
		AnimComp.RequestAction(n"RollDodge", EBasicBehaviourPriority::Medium, this, Durations, Move);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Owner.ActorLocation, ToLocation, FLinearColor::Yellow, 10, Durations.GetTotal());
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + FVector(0,0,200), FLinearColor::Yellow, 10, Durations.GetTotal());
			Debug::DrawDebugLine(ToLocation, ToLocation + FVector(0,0,200), FLinearColor::Yellow, 10, Durations.GetTotal());
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Math::RandRange(EnforcerSettings.RollDodgeCooldownMin, EnforcerSettings.RollDodgeCooldownMax));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		DestinationComp.RotateTowards(TargetComp.Target);
	}
}