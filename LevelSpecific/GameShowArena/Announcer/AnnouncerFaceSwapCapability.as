class UGameShowArenaAnnouncerFaceSwapCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Visibility);
	default CapabilityTags.Add(n"FaceSwap");
	default CapabilityTags.Add(n"BlockedByCutscene");
	default TickGroup = EHazeTickGroup::Gameplay;
	AGameShowArenaAnnouncer Announcer;
	UGameShowArenaAnnouncerFaceComponent AnnouncerFaceComp;

	TPerPlayer<UGameShowArenaBombTossPlayerComponent> PlayerComps;

	AGameShowArenaBomb ActiveBomb;
	AHazePlayerCharacter PlayerHoldingBomb;

	bool bWantsNewFace = true;
	float TimeWhenNextAutoFaceChange;
	float MinTimeBetweenAutoFaceChange = 1.0;
	float MaxTimeBetweenAutoFaceChange = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Announcer = Cast<AGameShowArenaAnnouncer>(Owner);
		AnnouncerFaceComp = UGameShowArenaAnnouncerFaceComponent::Get(Announcer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Announcer.bIsControlledByCutscene)
			return false;

		if (Announcer.State.Get() == EGameShowArenaAnnouncerState::PermanentGlitching)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Announcer.bIsControlledByCutscene)
			return true;

		if (Announcer.State.Get() == EGameShowArenaAnnouncerState::PermanentGlitching)
			return true;


		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComps[Game::Mio] = UGameShowArenaBombTossPlayerComponent::Get(Game::Mio);
		PlayerComps[Game::Zoe] = UGameShowArenaBombTossPlayerComponent::Get(Game::Zoe);

		PlayerComps[Game::Mio].OnPlayerCaughtBomb.AddUFunction(this, n"OnPlayerCaughtBomb");
		PlayerComps[Game::Zoe].OnPlayerCaughtBomb.AddUFunction(this, n"OnPlayerCaughtBomb");
		TimeWhenNextAutoFaceChange = 0;
	}

	UFUNCTION()
	private void OnPlayerCaughtBomb(AHazePlayerCharacter Player, AGameShowArenaBomb Bomb)
	{
		ActiveBomb = Bomb;
		PlayerHoldingBomb = Player;
		Announcer.AddLookAtTargetOverride(ActiveBomb, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Announcer.ClearLookAtTargetOverride(this);
		PlayerComps[Game::Mio].OnPlayerCaughtBomb.Unbind(this, n"OnPlayerCaughtBomb");
		PlayerComps[Game::Zoe].OnPlayerCaughtBomb.Unbind(this, n"OnPlayerCaughtBomb");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		int CurrentFace = AnnouncerFaceComp.InstigatedFace.Get();
		int NewFace = CurrentFace;
		ActiveBomb = GameShowArena::GetClosestEnabledBombToLocation(Announcer.ActorLocation);
		if (ActiveBomb == nullptr)
		{
			// New Happy Face
			if (!AnnouncerFaceComp.HasFaceFromRange(AnnouncerFaceComp.HappyFacesRange, CurrentFace))
				NewFace = AnnouncerFaceComp.GetRandomNewFaceFromRange(AnnouncerFaceComp.HappyFacesRange, CurrentFace);
		}
		else
		{
			if (ActiveBomb.State.Get() == EGameShowArenaBombState::Exploding)
			{
				if (!AnnouncerFaceComp.HasFaceFromRange(AnnouncerFaceComp.SymbolFacesRange, CurrentFace))
					NewFace = AnnouncerFaceComp.GetRandomNewFaceFromRange(AnnouncerFaceComp.SymbolFacesRange, CurrentFace);
			}
			else if (ActiveBomb.State.Get() == EGameShowArenaBombState::Thrown && PlayerHoldingBomb.OtherPlayer.IsPlayerDead())
			{
				// About to explode due to mistake == Angry
				if (!AnnouncerFaceComp.HasFaceFromRange(AnnouncerFaceComp.AngryFacesRange, CurrentFace))
					NewFace = AnnouncerFaceComp.GetRandomNewFaceFromRange(AnnouncerFaceComp.AngryFacesRange, CurrentFace);
			}
			else if (ActiveBomb.TimeUntilExplosion < ActiveBomb.GetMaxExplodeTimerDuration() * 0.5 || ActiveBomb.State.Get() == EGameShowArenaBombState::Thrown)
			{
				// New Sad Face
				if (!AnnouncerFaceComp.HasFaceFromRange(AnnouncerFaceComp.SadFacesRange, CurrentFace))
					NewFace = AnnouncerFaceComp.GetRandomNewFaceFromRange(AnnouncerFaceComp.SadFacesRange, CurrentFace);
			}
			else if (ActiveBomb.State.Get() == EGameShowArenaBombState::Caught || ActiveBomb.State.Get() == EGameShowArenaBombState::Frozen || ActiveBomb.State.Get() == EGameShowArenaBombState::Held)
			{
				// New Happy Face
				if (!AnnouncerFaceComp.HasFaceFromRange(AnnouncerFaceComp.HappyFacesRange, CurrentFace))
					NewFace = AnnouncerFaceComp.GetRandomNewFaceFromRange(AnnouncerFaceComp.HappyFacesRange, CurrentFace);
			}
		}

		AnnouncerFaceComp.ApplyFace(NewFace, this, EInstigatePriority::Low);
	}
};