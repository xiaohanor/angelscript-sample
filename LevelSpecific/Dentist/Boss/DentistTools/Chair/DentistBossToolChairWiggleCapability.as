struct FDentistBossToolChairWiggleActivationParams
{
	AHazePlayerCharacter RestrainedPlayer;
}

class UDentistBossToolChairWiggleCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolChair Chair;
	ADentistBoss Dentist;
	UDentistBossTargetComponent TargetComp;
	UDentistBossPlayerWiggleRotationComponent WiggleRotationComp;
	UPlayerMovementComponent MoveComp;

	UDentistBossSettings Settings;

	AHazePlayerCharacter RestrainedPlayer;

	FQuat ChairStartRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Chair = Cast<ADentistBossToolChair>(Owner);

		Dentist = TListedActors<ADentistBoss>().GetSingle();
		TargetComp = UDentistBossTargetComponent::Get(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistBossToolChairWiggleActivationParams& Params) const
	{
		if(!Chair.bActive)
			return false;

		if(!Chair.RestrainedPlayer.IsSet())
			return false;

		Params.RestrainedPlayer = Chair.RestrainedPlayer.Value;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Chair.bActive)
			return true;

		if(!Chair.RestrainedPlayer.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistBossToolChairWiggleActivationParams Params)
	{
		RestrainedPlayer = Params.RestrainedPlayer;
		ChairStartRotation = Chair.ActorQuat;

		WiggleRotationComp = UDentistBossPlayerWiggleRotationComponent::GetOrCreate(RestrainedPlayer);

		MoveComp = UPlayerMovementComponent::Get(RestrainedPlayer);
		MoveComp.FollowComponentMovement(Chair.RootComponent, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator ChairRotation = WiggleRotationComp.RelativeWiggleRotation * Settings.ChairWiggleRotationFraction;
		Chair.ActorRotation = ChairStartRotation.Rotator() + ChairRotation;
	}
}