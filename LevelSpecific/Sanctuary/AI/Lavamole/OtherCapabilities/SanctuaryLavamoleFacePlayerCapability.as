
class USanctuaryLavamoleFacePlayerCapability : UHazeCapability
{
	AAISanctuaryLavamole Lavamole;
	USanctuaryLavamoleSettings Settings;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default CapabilityTags.Add(LavamoleTags::LavaMoleFacePlayer);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Lavamole = Cast<AAISanctuaryLavamole>(Owner);
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TowardsPlayer = GetAvarageCentipedeLocation() - Owner.ActorLocation;
		TowardsPlayer.Z = 0.0;
		Owner.SetActorRotation(FRotator::MakeFromXZ(TowardsPlayer.GetSafeNormal(), FVector::UpVector));
	}

	private FVector GetAvarageCentipedeLocation() const
	{
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
		TArray<FVector> BodyLocations;
		if(ensure(CentipedeComp != nullptr, "Can only target centipede players!"))
			BodyLocations = CentipedeComp.GetBodyLocations();
		FVector AttackLocation;
		for(FVector Location: BodyLocations)
			AttackLocation += Location;
		return AttackLocation / BodyLocations.Num();
	}

}
