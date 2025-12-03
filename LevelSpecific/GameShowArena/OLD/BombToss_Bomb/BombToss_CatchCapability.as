struct FBombTossCatchActivatedParams
{
	ABombToss_Bomb ClosestBomb;
}

class UBombTossCatchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BombToss");
	default CapabilityTags.Add(n"BombTossCatch");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;
	float CatchDuration = 0.2;

	UBombTossPlayerComponent BombTossPlayerComponent;

	FVector PlayerLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UBombTossPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		PlayerLoc = Player.ActorLocation;
	}

	ABombToss_Bomb GetClosestBombToLocation(FVector Location) const
	{
		TListedActors<ABombToss_Bomb> ListedBombs;
		ABombToss_Bomb ClosestBomb;
		float ClosestDistance = MAX_flt;
		for (auto Bomb : ListedBombs)
		{
			float SquaredDist = Bomb.ActorLocation.DistSquared(Location);
			if (SquaredDist < ClosestDistance)
			{
				ClosestBomb = Bomb;
				ClosestDistance = SquaredDist;
			}
		}
		return ClosestBomb;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBombTossCatchActivatedParams& Params) const
	{
		auto ClosestBomb = GetClosestBombToLocation(PlayerLoc);

		if (ClosestBomb == nullptr)
			return false;

		if (PlayerLoc.DistSquared(ClosestBomb.ActorLocation) > ClosestBomb.CatchSphereRadius * ClosestBomb.CatchSphereRadius)
			return false;

		Params.ClosestBomb = ClosestBomb;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BombTossPlayerComponent.BombTossBomb == nullptr)
			return true;

		if (PlayerLoc.DistSquared(BombTossPlayerComponent.BombTossBomb.ActorLocation) > BombTossPlayerComponent.BombTossBomb.CatchSphereRadius * BombTossPlayerComponent.BombTossBomb.CatchSphereRadius)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBombTossCatchActivatedParams Params)
	{
		BombTossPlayerComponent.BombTossBomb = Params.ClosestBomb;
		PrintToScreen("Ready!", 0.0, FLinearColor::Green);

		Player.BlockCapabilities(n"BombTossThrow", this);

		// Player ready to catch Animation
		Player.PlayOverrideAnimation(FHazeAnimationDelegate(), BombTossPlayerComponent.CatchReadyAnimation, BombTossPlayerComponent.BoneFilter, PlayRate = 1.5);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"BombTossThrow", this);

		Player.StopOverrideAnimation(BombTossPlayerComponent.CatchReadyAnimation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (BombTossPlayerComponent.CatchBombToss())
		{
			// Play Catch Animation
			Player.PlayOverrideAnimation(FHazeAnimationDelegate(), BombTossPlayerComponent.CatchAnimation, BombTossPlayerComponent.BoneFilter);

			// Spawn Catch VFX
			Niagara::SpawnOneShotNiagaraSystemAttached(BombTossPlayerComponent.CatchVFX, BombTossPlayerComponent.CurrentBombToss.RootComponent);
		}
	}
}