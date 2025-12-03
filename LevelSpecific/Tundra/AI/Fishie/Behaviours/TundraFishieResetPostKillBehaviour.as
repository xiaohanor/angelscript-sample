// Custom behaviour for last fish: After killing player, we move swiftly away to the side and then teleport to starting position
class UTundraFishieResetPostKillBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport  = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAICharacterMovementComponent MoveComp;
	UTundraFishieComponent FishieComp;

	FVector StartLoc;
	FRotator StartRot;

	FVector ActivationLoc;
	UPlayerHealthComponent PreyHealth;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		FishieComp = UTundraFishieComponent::GetOrCreate(Owner);		
		StartLoc = Owner.ActorLocation;
		StartRot = Owner.ActorRotation;
		PreyHealth = UPlayerHealthComponent::Get(Game::Mio);
		OnRespawn();
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		StartLoc = Owner.ActorLocation;
		StartRot = Owner.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!FishieComp.bIsChaseFish)
			return false;
		if (!PreyHealth.bIsRespawning)
			return false;
		if (Owner.ActorLocation.IsWithinDist(StartLoc, 200.0))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (Owner.ActorLocation.IsWithinDist2D(StartLoc, 400.0))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ActivationLoc = Owner.ActorLocation;
		UBasicAIMovementSettings::SetTurnDuration(Owner, 1.0, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);
		Owner.TeleportActor(StartLoc, StartRot, this);

		// Never trigger this frequently
		Cooldown.Set(0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveTowardsIgnorePathfinding(FVector(StartLoc.X, StartLoc.Y, ActivationLoc.Z), 2000.0);
	}
}
