enum EStoneBeastHeadShakeState
{
	None,
	Ready,
	ShakeTelegraph,
	Shake,
	Reset
}

struct FStoneBeastHeadThrowParams
{
	FStoneBeastHeadThrowParams(bool bWasThrown, float ThrowTime)
	{
		bIsThrown = bWasThrown;
		TimeWhenThrown = ThrowTime;
	}

	void Throw()
	{
		bIsThrown = true;
		TimeWhenThrown = Time::GameTimeSeconds;
	}

	void Reset()
	{
		bIsThrown = false;
		TimeWhenThrown = -1;
	}

	bool bIsThrown;
	float TimeWhenThrown;
}

class UStoneBeastHeadShakeComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset ShakeCameraSettings;

	EStoneBeastHeadShakeState State = EStoneBeastHeadShakeState::None;

	AStoneBeastHead StoneBeast;

	bool bIsInitialized = false;

	TPerPlayer<FStoneBeastHeadThrowParams> ThrownPlayers;
	TPerPlayer<bool> MovementBlockedPlayers;
	TPerPlayer<bool> PinnedPlayers;
	TPerPlayer<bool> RagdollingPlayers;

	FHazeAcceleratedRotator AccRotationOffset;
	FRotator StartingRotation;
	FVector CurrentRotationOffset;
	URagdollComponent RagdollComp;

	ECollisionEnabled PlayerCollisionEnabled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StoneBeast = Cast<AStoneBeastHead>(Owner);
		PlayerCollisionEnabled = Game::Mio.Mesh.CollisionEnabled;
	}

	// returns new amplitude sine-value
	float UpdateSineOffset(float DeltaTime, float Frequency, float Amplitude, float& InOutCurrentOffset) const
	{
		const float TotalAmplitude = Amplitude;
		if (TotalAmplitude != 0)
		{
			InOutCurrentOffset += DeltaTime * Frequency * (2 * PI);
			return TotalAmplitude * Math::Sin(InOutCurrentOffset);
		}
		return 0;
	}

	void ThrowUnpinnedPlayers(FVector UpDir, FVector ThrowDir)
	{
		for (auto Player : Game::GetPlayers())
		{
			if (Player.IsPlayerDead() || Player.IsPlayerRespawning())
				continue;

			auto PinToGroundComp = UDragonSwordPinToGroundComponent::Get(Player);
			if (!PinToGroundComp.IsPlayerPinnedToGround() && !ThrownPlayers[Player].bIsThrown)
			{
				if (HasControl())
				{
					CrumbThrowPlayer(Player, (UpDir * StoneBeastHead::Throw::Impulse * 0.75) + (ThrowDir * StoneBeastHead::Throw::Impulse * 0.25));
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbThrowPlayer(AHazePlayerCharacter Player, FVector ThrowImpulse)
	{
		StoneBeast.FocusTargets[Player].bIsFollowing = false;

		ThrownPlayers[Player].Throw();
		auto PinToGroundComp = UDragonSwordPinToGroundComponent::Get(Player);

		if (!MovementBlockedPlayers[Player])
		{
			if (PinToGroundComp.bIsExitFinished)
			{
				ApplyRagdoll(Player, ThrowImpulse);
			}
			else
			{
				BlockMovementForPlayer(Player);
				Player.AddMovementImpulse(ThrowImpulse * 0.3);
			}
		}
	}

	void ForceKillThrownPlayers()
	{
		if (!HasControl())
			return;

		for (auto Player : Game::GetPlayers())
		{
			if (Player.IsPlayerDead() || Player.IsPlayerRespawning())
				continue;

			if (ThrownPlayers[Player].bIsThrown)
			{
				CrumbKillPlayer(Player);
			}
		}
	}

	void TryKillThrownPlayers()
	{
		if (!HasControl())
			return;

		for (auto Player : Game::GetPlayers())
		{
			if (Player.IsPlayerDead() || Player.IsPlayerRespawning())
				continue;

			if (ThrownPlayers[Player].bIsThrown && Time::GetGameTimeSince(ThrownPlayers[Player].TimeWhenThrown) >= StoneBeastHead::Throw::TimeBeforeKillPlayers)
			{
				CrumbKillPlayer(Player);
			}
		}
	}

	void ApplyRagdoll(AHazePlayerCharacter Player, FVector Impulse)
	{
		if (RagdollingPlayers[Player])
			return;

		RagdollingPlayers[Player] = true;
		Player.BlockCapabilities(CapabilityTags::Movement, n"Ragdoll");
		Player.BlockCapabilities(CapabilityTags::GameplayAction, n"Ragdoll");
		RagdollComp = URagdollComponent::GetOrCreate(Player);
		RagdollComp.ApplyRagdoll(Player.Mesh, Player.CapsuleComponent);
		RagdollComp.ApplyRagdollImpulse(Player.Mesh, FRagdollImpulse(ERagdollImpulseType::WorldSpace, Impulse, Player.ActorCenterLocation));
	}

	void ClearRagdoll(AHazePlayerCharacter Player)
	{
		if (!RagdollingPlayers[Player])
			return;

		RagdollingPlayers[Player] = false;
		Player.UnblockCapabilities(CapabilityTags::Movement, n"Ragdoll");
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, n"Ragdoll");
		RagdollComp = URagdollComponent::GetOrCreate(Player);
		RagdollComp.ClearRagdoll(Player.Mesh, Player.CapsuleComponent);
	}

	UFUNCTION(CrumbFunction)
	void CrumbKillPlayer(AHazePlayerCharacter Player)
	{
		Player.KillPlayer();
	}

	private void BlockMovementForPlayer(AHazePlayerCharacter Player)
	{
		check(!MovementBlockedPlayers[Player]);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		MovementBlockedPlayers[Player] = true;
	}

	private void UnblockMovementForPlayer(AHazePlayerCharacter Player)
	{
		check(MovementBlockedPlayers[Player]);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		MovementBlockedPlayers[Player] = false;
	}

	void ResetThrownPlayers()
	{
		ThrownPlayers[Game::Mio].Reset();
		ThrownPlayers[Game::Zoe].Reset();

		StoneBeast.FocusTargets[Game::Mio].bIsFollowing = true;
		StoneBeast.FocusTargets[Game::Zoe].bIsFollowing = true;

		ClearRagdoll(Game::Mio);
		ClearRagdoll(Game::Zoe);

		if (MovementBlockedPlayers[Game::Mio])
		{
			UnblockMovementForPlayer(Game::Mio);
		}
		if (MovementBlockedPlayers[Game::Zoe])
			UnblockMovementForPlayer(Game::Zoe);
	}
};