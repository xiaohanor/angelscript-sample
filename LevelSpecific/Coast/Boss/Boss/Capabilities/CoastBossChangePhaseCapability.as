struct FCoastBossChangePhaseActivatedParams
{
	bool bShouldSetHealth = false;
	AHazePlayerCharacter RightMostPlayer;
}

class UCoastBossChangePhaseCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);

	// We want to be before the queue capability so we can detect if queue is empty
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 99;
	ACoastBoss CoastBoss;
	ACoastBossActorReferences References;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CoastBoss = Cast<ACoastBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		TryCacheThings();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCoastBossChangePhaseActivatedParams& Params) const
	{
		if (!HasControl())
			return false;

		if (CoastBoss.bDead)
			return false;

		if (CoastBoss.ShouldChangeToDevForcedPhase())
		{
			Params.bShouldSetHealth = true;
			return true;
		}

		if (!IsPhaseOver())
			return false;

		if (CoastBossDevToggles::UseManyDrones.IsEnabled())
		{
			if (CoastBoss.HasWeakpointsLeft())
				return false;
		}
		else if (CoastBoss.IsHealthInCurrentPhase())
			return false;

		if(References == nullptr)
			return false;

		FVector MioPosRelativeToPlane = References.CoastBossPlane2D.ActorTransform.InverseTransformPositionNoScale(Game::Mio.ActorLocation);
		FVector ZoePosRelativeToPlane = References.CoastBossPlane2D.ActorTransform.InverseTransformPositionNoScale(Game::Zoe.ActorLocation);

		AHazePlayerCharacter RightMostPlayer;
		if(Math::IsNearlyEqual(MioPosRelativeToPlane.Y, ZoePosRelativeToPlane.Y, 5.0))
			RightMostPlayer = Game::Zoe;
		else if(MioPosRelativeToPlane.Y < ZoePosRelativeToPlane.Y)
			RightMostPlayer = Game::Zoe;
		else
			RightMostPlayer = Game::Mio;
		
		Params.RightMostPlayer = RightMostPlayer;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCoastBossChangePhaseActivatedParams Params)
	{
		ECoastBossPhase NewPhase = CoastBoss.GetPhase();
		if (NewPhase == CoastBossConstants::LastPhase)
		{
			CoastBoss.BossDied(Params.RightMostPlayer);
		}
		else
		{
			NewPhase++;
			CoastBoss.SetNewPhase(NewPhase, Params.bShouldSetHealth);
		}
	}

	bool IsPhaseOver() const
	{
		if(CoastBoss.IsHealthInLastPhase())
			return true;

		if (!CoastBoss.AttackActionQueue.IsEmpty())
			return false;

		if (CoastBoss.GetPhase() == ECoastBossPhase::Phase3)
		{
			if (CoastBoss.GunBossMovementMode == ECoastBossMovementMode::IdleBobbing)
				return true;

			return false;
		}

		if (CoastBoss.GetPhase() == ECoastBossPhase::Phase4)
		{
			if (CoastBoss.GunBossMovementMode == ECoastBossMovementMode::IdleBobbing)
				return true;

			return false;
		}

		return true;
	}

	bool TryCacheThings()
	{
		if (References == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			if (Refs.Num() > 0)
				References = Refs.Single;
		}
		return References != nullptr;
	}
};