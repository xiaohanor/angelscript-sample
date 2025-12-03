struct FGameShowArenaBombHeldActivatedParams
{
	AHazePlayerCharacter HolderPlayer;
}

class UGameShowArenaBombHeldCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default InterruptsCapabilities(n"GameShowBombMovement");

	default TickGroup = EHazeTickGroup::BeforeMovement;

	AGameShowArenaBomb Bomb;
	float CurrentExplodeDuration;
	float PrevActiveDuration = 0;

	bool bThrowHasStarted = false;

	// negative value as timer ticks down past 0
	float ExtendedThrowWindow = -0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bomb = Cast<AGameShowArenaBomb>(Owner);
		Bomb.OnThrowStarted.AddUFunction(this, n"OnThrowStarted");
	}

	UFUNCTION()
	private void OnThrowStarted(AGameShowArenaBomb _)
	{
		bThrowHasStarted = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGameShowArenaBombHeldActivatedParams& Params) const
	{
		if (Bomb.State.Get() != EGameShowArenaBombState::Held)
			return false;

		Params.HolderPlayer = Bomb.Holder;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Bomb.State.Get() != EGameShowArenaBombState::Held)
			return true;

		if (Bomb.Holder == nullptr)
			return true;

		if (Bomb.Holder.IsPlayerDead() || Bomb.Holder.IsPlayerRespawning())
			return true;

		if (Bomb.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGameShowArenaBombHeldActivatedParams Params)
	{
		bThrowHasStarted = false;
		CurrentExplodeDuration = Bomb.GetMaxExplodeTimerDuration();
		Bomb.Mesh.SetRelativeRotation(FRotator::ZeroRotator);
		Bomb.SimulatedMesh.SetRelativeRotation(FRotator::ZeroRotator);
		Bomb.AttachToActor(Bomb.Holder, n"Backpack");
		Bomb.ActorRelativeRotation = FRotator::MakeFromEuler(FVector(90, 0, -90));
		Bomb.bIsAttached = true;

		// if (Params.HolderPlayer.IsMio())
		// 	Bomb.SetActorControlSide(Game::Mio);
		// else
		// 	Bomb.SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PrevActiveDuration = ActiveDuration;
		Bomb.ActorRelativeRotation = FRotator(0, 0, 0);
		if (Bomb.Holder == nullptr)
			return;

		if (!HasControl())
			return;
		
		if (Bomb.Holder.IsPlayerDead() || Bomb.Holder.IsPlayerRespawning())
			Bomb.CrumbExplode(Bomb.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bThrowHasStarted)
		{
			Bomb.TimeUntilExplosion -= DeltaTime;
			Bomb.BP_OnBombHeldTick();
			float Alpha = Math::Saturate(Bomb.TimeUntilExplosion / CurrentExplodeDuration);
			Bomb.UpdateFillMaterial(Math::Lerp(1, 0, Alpha), Math::Lerp(FVector(50, 0, 0), FVector(0, 0, 50), Alpha));

#if EDITOR
			if (GameShowArena::DisableExplosionTimer.IsEnabled())
				return;
#endif
			if (Bomb.HasExplosionBlock())
				return;

			if (Bomb.TimeUntilExplosion <= ExtendedThrowWindow)
				Bomb.CrumbExplode(Bomb.ActorLocation);
		}
	}
};