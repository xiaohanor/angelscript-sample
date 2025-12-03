UCLASS(Abstract)
class APrisonStealthEnemy : AHazeActor
{
	access VisionInternal = private, UPrisonStealthVisionCapability;
	access DetectionInternal = private, UPrisonStealthDetectionCapability;

	UPROPERTY(DefaultComponent)
	UPrisonStealthDetectionComponent MioDetectionComp;
	default MioDetectionComp.PlayerToDetect = EHazePlayer::Mio;
	default MioDetectionComp.bIsEnabled = false;

	UPROPERTY(DefaultComponent)
	UPrisonStealthDetectionComponent ZoeDetectionComp;
	default ZoeDetectionComp.PlayerToDetect = EHazePlayer::Zoe;
	default ZoeDetectionComp.bIsEnabled = true;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere, Category = "Color")
	FLinearColor StunnedSpotlightColor = FLinearColor(1, 1, 0);

	UPROPERTY(EditAnywhere, Category = "Color")
	FLinearColor DetectedSpotlightColor = FLinearColor(1, 0, 0);

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	FLinearColor InitialSpotlightColor;

	TPerPlayer<UPrisonStealthDetectionComponent> DetectionComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Control on SwarmDrone side for immediate hit feedback
		SetActorControlSide(Drone::SwarmDronePlayer);

		DetectionComponents[Game::Mio] = MioDetectionComp;
		DetectionComponents[Game::Zoe] = ZoeDetectionComp;

		auto SpotLight = USpotLightComponent::Get(this);
		if(SpotLight != nullptr)
			InitialSpotlightColor = SpotLight.LightColor;
	}

	bool IsDetectionEnabledForPlayer(const AHazePlayerCharacter Player) const
	{
		return DetectionComponents[Player].bIsEnabled;
	}

	TArray<AHazePlayerCharacter> GetPlayersInSight() const
	{
		TArray<AHazePlayerCharacter> PlayersInSight;

		for(auto Player : Game::Players)
		{
			if(IsPlayerInSight(Player))
				PlayersInSight.Add(Player);
		}

		return PlayersInSight;
	}

	bool IsPlayerInSight(const AHazePlayerCharacter Player) const
	{
		if(!IsDetectionEnabledForPlayer(Player))
			return false;

		const UPrisonStealthDetectionComponent DetectionComp = DetectionComponents[Player];
		return DetectionComp.IsPlayerInSight();
	}

	access:VisionInternal
	void SetIsPlayerInSight(const AHazePlayerCharacter Player, bool bIsPlayerInSight)
	{
		UPrisonStealthDetectionComponent DetectionComp = DetectionComponents[Player];
		DetectionComp.SetIsPlayerInSight(bIsPlayerInSight);
	}

	bool IsAnyPlayerInSight() const
	{
		return IsPlayerInSight(Game::Mio) || IsPlayerInSight(Game::Zoe);
	}

	bool HasDetectedPlayer(const AHazePlayerCharacter Player) const
	{
		if(!IsDetectionEnabledForPlayer(Player))
			return false;
		
		const UPrisonStealthDetectionComponent DetectionComp = DetectionComponents[Player];
		return DetectionComp.HasDetectedPlayer();
	}

	access:DetectionInternal
	void SetHasDetectedPlayer(const AHazePlayerCharacter Player, bool bHasDetectedPlayer)
	{
		if(!IsDetectionEnabledForPlayer(Player))
			return;

		UPrisonStealthDetectionComponent DetectionComp = DetectionComponents[Player];
		DetectionComp.SetHasDetectedPlayer(bHasDetectedPlayer);
	}

	UFUNCTION(BlueprintPure)
	bool HasDetectedAnyPlayer() const
	{
		return HasDetectedPlayer(Game::Mio) || HasDetectedPlayer(Game::Zoe);
	}

	TArray<AHazePlayerCharacter> GetDetectedPlayers() const
	{
		TArray<AHazePlayerCharacter> DetectedPlayers;

		for(auto Player : Game::Players)
		{
			if(HasDetectedPlayer(Player))
				DetectedPlayers.Add(Player);
		}

		return DetectedPlayers;
	}

	FPrisonStealthPlayerLastSeen GetLastSeenData(const AHazePlayerCharacter Player) const
	{
		if(!IsDetectionEnabledForPlayer(Player))
			return FPrisonStealthPlayerLastSeen();

		const UPrisonStealthDetectionComponent DetectionComp = DetectionComponents[Player];
		return DetectionComp.GetLastSeenData();
	}

	void SetLastSeenData(const AHazePlayerCharacter Player, FPrisonStealthPlayerLastSeen LastSeenData)
	{
		UPrisonStealthDetectionComponent DetectionComp = DetectionComponents[Player];
		DetectionComp.SetLastSeenData(LastSeenData);
	}

	float GetMaxLastSeenTime() const
	{
		const FPrisonStealthPlayerLastSeen MioLastSeen = GetLastSeenData(Game::Mio);
		const FPrisonStealthPlayerLastSeen ZoeLastSeen = GetLastSeenData(Game::Zoe);

		if(MioLastSeen.IsValid() && ZoeLastSeen.IsValid())
		{
			return Math::Max(MioLastSeen.Time, ZoeLastSeen.Time);
		}
		else if(MioLastSeen.IsValid())
		{
			return MioLastSeen.Time;
		}
		else if(ZoeLastSeen.IsValid())
		{
			return ZoeLastSeen.Time;
		}
		else
		{
			return -1;
		}
	}

	float GetDetectionAlpha(const AHazePlayerCharacter Player) const
	{
		if(!IsDetectionEnabledForPlayer(Player))
			return 0;

		const UPrisonStealthDetectionComponent DetectionComp = DetectionComponents[Player];
		return DetectionComp.GetDetectionAlpha();
	}

	void SetDetectionAlpha(const AHazePlayerCharacter Player, float DetectionAlpha, bool bSnap)
	{
		if(!IsDetectionEnabledForPlayer(Player))
			return;

		UPrisonStealthDetectionComponent DetectionComp = DetectionComponents[Player];
		DetectionComp.SetDetectionAlpha(DetectionAlpha, bSnap);
	}

	float GetMaxDetectionAlpha() const
	{
		return Math::Max(GetDetectionAlpha(Game::Mio), GetDetectionAlpha(Game::Zoe));
	}

	bool HasSpottedPlayer(AHazePlayerCharacter Player) const
	{
		if(!IsDetectionEnabledForPlayer(Player))
			return false;

		return GetDetectionAlpha(Player) > 0.0;
	}

	bool HasSpottedAnyPlayer() const
	{
		return HasSpottedPlayer(Game::Mio) || HasSpottedPlayer(Game::Zoe);
	}

	FLinearColor GetLightColor() const
	{
		if(HasDetectedAnyPlayer())
			return DetectedSpotlightColor;

		const float Alpha = GetLightColorAlpha();
		return FLinearColor::LerpUsingHSV(InitialSpotlightColor, DetectedSpotlightColor, Alpha);
	}

	UFUNCTION(BlueprintPure)
	FVector GetLightColorVector() const
	{
		FLinearColor LightColor = GetLightColor();
		return FVector(LightColor.R, LightColor.G, LightColor.B);
	}

	UFUNCTION(BlueprintPure)
	float GetLightColorAlpha() const
	{
		// The light should go from yellow to red quickly when the player is first spotted
		// and only return once DetectionAlpha is low.
		return Math::Saturate(Math::NormalizeToRange(GetMaxDetectionAlpha(), 0.0, 0.2));
	}

	void Reset()
	{
		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			SetDetectionAlpha(Player, 0, true);
		}
	}
};