class UDentistBossToolCupMoveToTargetCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	ADentistBossToolCup Cup;
	ADentistBoss Dentist;

	UDentistBossSettings Settings;

	const float LocationInterpSpeed = 150.0;
	const float RotationInterpSpeedDegrees = 100.0;
	const float TimeAfterResetBeforeAllowedActivation = 5.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cup = Cast<ADentistBossToolCup>(Owner);

		Dentist = TListedActors<ADentistBoss>().GetSingle();
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Cup.bActive)
			return false;

		if(Time::GetGameTimeSince(Cup.TimeLastReset) < TimeAfterResetBeforeAllowedActivation)
			return false;

		if(IsAttached())
			return false;

		if(Cup.bIsFlattened)
			return false;

		if(Cup.bHasBeenOpened)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Cup.bActive)
			return true;

		if(Time::GetGameTimeSince(Cup.TimeLastReset) < TimeAfterResetBeforeAllowedActivation)
			return true;

		if(IsAttached())
			return true;

		if(Cup.bIsFlattened)
			return true;

		if(Cup.bHasBeenOpened)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLocation = Cup.GetTargetLocation();
		FRotator TargetRotation = Cup.GetTargetRotation();

		FVector NewLocation = Math::VInterpConstantTo(Cup.ActorLocation, TargetLocation, DeltaTime, LocationInterpSpeed);
		FRotator NewRotation = Math::RInterpConstantShortestPathTo(Cup.ActorRotation, TargetRotation, DeltaTime, RotationInterpSpeedDegrees);
		Cup.SetActorLocationAndRotation(NewLocation, NewRotation);

		TEMPORAL_LOG(Cup)
			.Sphere("Target Location", TargetLocation, 50, FLinearColor::LucBlue, 10)
			.Rotation("Target Rotation", TargetRotation.Quaternion(), Cup.ActorLocation, 500)
		;
	}

	bool IsAttached() const
	{
		if(Cup.AttachParentActor != nullptr)
			return true;

		return false;
	}
}