class USanctuaryDoppelGangerMatchPositionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USanctuaryDoppelgangerSettings DoppelSettings;
	USanctuaryDoppelgangerComponent DoppelComp;
	AHazePlayerCharacter StalkingTarget;
	float OffsetUpdateTime = 0.0;
	FVector Destination;
	FVector Offset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DoppelSettings = USanctuaryDoppelgangerSettings::GetSettings(Owner);
		DoppelComp = USanctuaryDoppelgangerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::FullMimic)
			return false;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::Reveal)
			return false;
		if (DoppelComp.MimicTarget == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::FullMimic)
			return true;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::Reveal)
			return true;
		if (DoppelComp.MimicTarget == nullptr)
			return true;
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Offset = GetOffset();
		Destination = DoppelComp.GetMimicLocation() + Offset;
	}

	FVector GetOffset()
	{
		return Math::GetRandomPointInCircle_XY() * Math::RandRange(0.0, DoppelSettings.MatchPositionMaxOffset);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move to where the mimic player is relative to mimic transform
		AnimComp.RequestFeature(LocomotionFeatureAISanctuaryTags::DoppelgangerMimicMovement, EBasicBehaviourPriority::Low, this);

		if (Time::GameTimeSeconds > OffsetUpdateTime)
		{
			Offset = GetOffset();
			Destination = DoppelComp.GetMimicLocation() + Offset;
			OffsetUpdateTime = Time::GameTimeSeconds + Math::RandRange(1.0, DoppelSettings.MatchPositionOffsetUpdateInterval);
		}
		else if (Owner.ActorLocation.DistSquared2D(Destination) < Math::Square(64.0))
		{
			Destination = DoppelComp.GetMimicLocation() + Offset;
		}

		float MoveSpeed = Math::Min(DoppelComp.MimicTarget.ActorVelocity.Size(), DoppelSettings.MatchPositionMaxSpeed);
		DestinationComp.MoveTowards(Destination, MoveSpeed);
	}
}


