class UTundraGnapeAvoidMonkeyBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	AHazePlayerCharacter Monkey;
	UTundraGnatSettings Settings;
	UTundraGnatComponent GnapeComp;

	float ReactTime;
	float ResumeAttackTime;
	const float MaxDuration = 100.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GnapeComp = UTundraGnatComponent::Get(Owner); 
		Monkey = Game::Mio;
		Settings = UTundraGnatSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (GnapeComp.bLatchedOn)
			return false; // Don't let go until actually hit
		if (!GnapeComp.bTargetedByMonkeyThrow)
		{
			// If we're actually targeted by monkey we're in danger regardless of position
			if (!Monkey.ActorLocation.IsWithinDist(Owner.ActorLocation, Settings.AvoidMonkeyRange))
				return false;
			if (!Monkey.IsAnyCapabilityActive(n"ThrowGnape"))
				return false;
			if (Monkey.ActorForwardVector.DotProduct(Owner.ActorLocation - Monkey.ActorLocation) < 0.0)
				return false;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > ResumeAttackTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// Stop and look worried!
		ReactTime = Math::RandRange(0.2, 0.5);
		ResumeAttackTime = MaxDuration;
		UTundraGnatSettings::SetTurnDuration(Owner, 0.8, this);
		UTundraGnatSettings::SetFriction(Owner, 8.0, this);

		if (GnapeComp.bTargetedByMonkeyThrow)
			UTundraGnatEffectEventHandler::Trigger_OnTargetedByMonkey(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GnapeComp.bTargetedByMonkeyThrow = false;
		Owner.ClearSettingsByInstigator(this);
	}

	bool IsDangerOver() const
	{
		if (!GnapeComp.bTargetedByMonkeyThrow && !Monkey.ActorLocation.IsWithinDist(Owner.ActorLocation, Settings.AvoidMonkeyRange * 1.5))
			return true;
		if (!Game::Mio.IsAnyCapabilityActive(n"ThrowGnape"))
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsDangerOver())
		{
			// We're clear, resume attack in a while
			if (ResumeAttackTime > MaxDuration - 1.0)
				ResumeAttackTime = ActiveDuration + Math::RandRange(0.3, 0.7);
		}
		else
		{
			// Still threatened by monkey
			ResumeAttackTime = MaxDuration;
		}

		if (ActiveDuration > ReactTime)
		{
			// We're now aware of the danger!
			ReactTime = BIG_NUMBER;
			AnimComp.RequestFeature(TundraGnatTags::TargetedByMonkeyThrow, EBasicBehaviourPriority::Medium, this);
		}

		FVector ThreatLoc = Game::Mio.ActorLocation;
		if ((ActiveDuration > 0.7) && ThreatLoc.IsWithinDist(Owner.ActorLocation, Settings.AvoidMonkeyRange))
		{
			FVector AvoidLoc = GnapeComp.GetAvoidLocationOnHost(ThreatLoc, Settings.AvoidMonkeyRange);
			DestinationComp.MoveTowardsIgnorePathfinding(AvoidLoc, Settings.AvoidMonkeySpeed);
		}
		DestinationComp.RotateTowards(Game::Mio);
	}
}


