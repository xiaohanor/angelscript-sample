class UGameShowArenaPlatformPlayerReactionCapability : UHazeCapability
{
	UGameShowArenaPlatformPlayerReactionComponent ReactionComp;
	UGameShowArenaDisplayDecalPlatformComponent DecalComp;
	FGameShowArenaDisplayDecalParams DisplayDecalParams;

	float CurrentOpacity;
	float MaxOpacity = 80;

	float CurrentMioTintStrength;
	float CurrentZoeTintStrength;
	float PreviousValidPlayerTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ReactionComp = UGameShowArenaPlatformPlayerReactionComponent::Get(Owner);
		DecalComp = UGameShowArenaDisplayDecalPlatformComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ReactionComp.PlayersOnPlatform[Game::Mio] && !ReactionComp.PlayersOnPlatform[Game::Zoe])
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ReactionComp.PlayersOnPlatform[Game::Mio] || ReactionComp.PlayersOnPlatform[Game::Zoe])
			return false;

		float MioTime = ReactionComp.TimeWhenPlayerOnPlatform[Game::Mio];
		float ZoeTime = ReactionComp.TimeWhenPlayerOnPlatform[Game::Zoe];
		if (Time::GetGameTimeSince(MioTime) < 5.0 || Time::GetGameTimeSince(ZoeTime) < 5.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentOpacity = 0;
		CurrentMioTintStrength = 0;
		CurrentZoeTintStrength = 0;

		DisplayDecalParams.Opacity = CurrentOpacity;
		DisplayDecalParams.Texture = ReactionComp.PlayerReactionTexture;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DecalComp.ClearMaterialParameters(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ZoeTime = ReactionComp.TimeWhenPlayerOnPlatform[Game::Zoe];
		float MioTime = ReactionComp.TimeWhenPlayerOnPlatform[Game::Mio];
		float FadeInTime = MAX_flt;
		float FadeOutTime = MAX_flt;
		if (ReactionComp.PlayersOnPlatform[Game::Mio])
		{
			CurrentMioTintStrength = Math::SmoothStep(0, 0.5, Time::GetGameTimeSince(MioTime));
			FadeInTime = MioTime;
		}
		else
			CurrentMioTintStrength = Math::FInterpTo(CurrentMioTintStrength, 0, DeltaTime, 1.0);

		if (ReactionComp.PlayersOnPlatform[Game::Zoe])
		{
			CurrentZoeTintStrength = Math::SmoothStep(0, 0.5, Time::GetGameTimeSince(ZoeTime));
			FadeInTime = Math::Min(ZoeTime, FadeInTime);
		}
		else
			CurrentZoeTintStrength = Math::FInterpTo(CurrentZoeTintStrength, 0, DeltaTime, 1.0);

		DisplayDecalParams.Tint = PlayerColor::Mio * CurrentMioTintStrength + PlayerColor::Zoe * CurrentZoeTintStrength;
		if (!ReactionComp.PlayersOnPlatform[Game::Mio] && !ReactionComp.PlayersOnPlatform[Game::Zoe])
		{
			FadeOutTime = Math::Max(MioTime, ZoeTime);
			CurrentOpacity = (1 - Math::SmoothStep(0, 0.28, Time::GetGameTimeSince(FadeOutTime))) * MaxOpacity;
		}
		else
		{
			CurrentOpacity = Math::SmoothStep(0, 2, Time::GetGameTimeSince(FadeInTime)) * MaxOpacity;
		}

		DisplayDecalParams.DecalWorldTransform = DecalComp.GetMeshComponent().WorldTransform;
		DisplayDecalParams.DecalWorldTransform.Location = DisplayDecalParams.DecalWorldTransform.Location - FVector::RightVector * 15 - FVector::ForwardVector * 15;
		DisplayDecalParams.DecalWorldTransform.Scale3D = FVector::OneVector * 175;
		DisplayDecalParams.Opacity = CurrentOpacity;
		DecalComp.UpdateMaterialParameters(DisplayDecalParams, true);
	}
};