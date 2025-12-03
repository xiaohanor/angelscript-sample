class AIslandSidescrollerCameraFocusActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	bool bUseJumpDelay = true;

	UPROPERTY(EditInstanceOnly)
	float TargetHeightOffset = 0.0;

	UPROPERTY(EditInstanceOnly)
	float TargetHeightOffsetLerpDuration = 0.5;

	UPROPERTY(EditInstanceOnly)
	float VerticalScreenKillMargin = 0.1;

	UPROPERTY(EditInstanceOnly)
	float HorizontalScreenKillMargin = 0.1;

	UPROPERTY(EditInstanceOnly)
	bool bAutoKillWhenOffScreen = true;

	default TickGroup = ETickingGroup::TG_HazeInput;

	TPerPlayer<UPlayerJumpComponent> JumpComp;
	TPerPlayer<UPlayerMovementComponent> MoveComp;
	TPerPlayer<UIslandSidescrollerComponent> SidescrollerComp;

	TPerPlayer<FVector> PlayerLocation;

	TPerPlayer<bool> ShouldFreezeHeightAfterJump;
	TPerPlayer<float> TimeLastJumped;
	TPerPlayer<float> HeightAtJump;
	TPerPlayer<FHazeAcceleratedFloat> AccJumpUpOffset;

	TPerPlayer<bool> IsDead;
	TPerPlayer<float> TimeOtherPlayerLastDied;
	TPerPlayer<FHazeAcceleratedVector> AccOtherDeathOffset;

	TPerPlayer<float> TimeLastRespawned;
	TPerPlayer<FHazeAcceleratedVector> AccRespawnOffset;

	TPerPlayer<bool> HasBeenOnScreen;
	TPerPlayer<bool> HasBeenGrounded;

	const float JumpStayDuration = 1.7;
	const float JumpOffsetAccelerationDuration = 1.5;

	const float DeathStayDuration = 0.5;
	const float DeathOffsetAccelerationDuration = 0.5;

	const float RespawnStayDuration = 0.25;
	const float RespawnOffsetAccelerationDuration = 1.0;

	float StartTime;
	FHazeAcceleratedFloat AcceleratedHeightOffset;
	TPerPlayer<bool> PlayerKillBlocked;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartTime = Time::GameTimeSeconds;

		for(auto Player : Game::Players)
		{
			JumpComp[Player] = UPlayerJumpComponent::Get(Player);
			MoveComp[Player] = UPlayerMovementComponent::Get(Player);
			SidescrollerComp[Player] = UIslandSidescrollerComponent::GetOrCreate(Player);

			PlayerLocation[Player] = Player.ActorCenterLocation;
			ShouldFreezeHeightAfterJump[Player] = false;
			AccJumpUpOffset[Player].SnapTo(0);

			TimeOtherPlayerLastDied[Player] = -MAX_flt;
			IsDead[Player] = false;
			AccOtherDeathOffset[Player].SnapTo(FVector::ZeroVector);

			TimeLastRespawned[Player] = -MAX_flt;
			AccRespawnOffset[Player].SnapTo(FVector::ZeroVector);

			HasBeenOnScreen[Player] = false;
			HasBeenGrounded[Player] = false;

			UPlayerRespawnComponent::GetOrCreate(Player).OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");
		}

		AcceleratedHeightOffset.SnapTo(TargetHeightOffset);
		UpdateLocation(0.0, true);

		DevToggleIslandSidescrollerCamera::DisableJumpStay.MakeVisible();
		DevToggleIslandSidescrollerCamera::DisableStayWhenDied.MakeVisible();
		DevToggleIslandSidescrollerCamera::DisableNoSnappingWhenRespawned.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for(auto Player : Game::Players)
		{
			ValidateDeath(Player);
			if(Time::GetGameTimeSince(TimeOtherPlayerLastDied[Player]) > DeathStayDuration)
				AccOtherDeathOffset[Player].AccelerateTo(FVector::ZeroVector, DeathOffsetAccelerationDuration, DeltaTime);
			
			if(Time::GetGameTimeSince(TimeLastRespawned[Player]) > RespawnStayDuration)
				AccRespawnOffset[Player].AccelerateTo(FVector::ZeroVector, RespawnOffsetAccelerationDuration, DeltaTime);

			if(bUseJumpDelay)
			{
				ValidateJumpHeightFreeze(Player);
				if(!ShouldFreezeHeightAfterJump[Player])
					AccJumpUpOffset[Player].AccelerateTo(0, JumpOffsetAccelerationDuration, DeltaTime);
			}
		}

		ValidatePlayersOnScreen();
		ValidatePlayersHaveBeenGrounded();
		UpdateLocation(DeltaTime);
		if(bAutoKillWhenOffScreen)
			HandleKillWhenOffScreen();
	}

	// Will add a kill blocker that will get automatically cleared when the player is on screen again
	UFUNCTION()
	void BlockPlayerKillUntilOnScreen(AHazePlayerCharacter Player, bool bAlsoBlockEdgeColliders = true)
	{
		PlayerKillBlocked[Player] = true;

		if(bAlsoBlockEdgeColliders)
			SidescrollerComp[Player].AddEdgeColliderBlocker(this);
	}

	/* BlockPlayerKillUntilOnScreen will automatically be unblocked when the player is on screen again, only use this function if you for some reason
	want to unblock player kill before the players are on screen again. */
	UFUNCTION()
	void UnblockPlayerKill(AHazePlayerCharacter Player)
	{
		PlayerKillBlocked[Player] = false;
		SidescrollerComp[Player].RemoveEdgeColliderBlocker(this);
	}

	private void UpdateLocation(float DeltaTime, bool bTeleport = false)
	{
		FVector AveragePositionBetweenPlayers;
		int PositionOfPlayersCounted = 0;
		AHazePlayerCharacter TopMostPlayer = Game::Mio;
		for(auto Player : Game::Players)
		{
			if(IsDead[Player])
				continue;

			if(Player.ActorLocation.Z > TopMostPlayer.ActorLocation.Z)
				TopMostPlayer = Player;

			AveragePositionBetweenPlayers += AccOtherDeathOffset[Player].Value;
			AveragePositionBetweenPlayers += AccRespawnOffset[Player].Value;

			if(ShouldFreezeHeightAfterJump[Player])
			{
				PlayerLocation[Player].X = Player.ActorCenterLocation.X;
				PlayerLocation[Player].Y = Player.ActorCenterLocation.Y;
			}
			else
			{
				PlayerLocation[Player] = Player.ActorCenterLocation + (FVector::UpVector * AccJumpUpOffset[Player].Value);
			}
			
			AveragePositionBetweenPlayers += PlayerLocation[Player];
			PositionOfPlayersCounted++;
		}

		AveragePositionBetweenPlayers /= PositionOfPlayersCounted;
		if(IsAnyPlayerInFullscreen() && AcceleratedHeightOffset.Value != 0.0)
			AveragePositionBetweenPlayers += FVector::UpVector * GetCurrentHeightOffset(DeltaTime);

		// Clamp the lowest position of the camera based on the top most player so it wont get pushed down into the floor by the top edge collider
		if(IsAnyPlayerInFullscreen())
		{
			FVector2D Extents = GetWorldExtentsOfScreen();
			FVector TopOfTopMostPlayerCapsule = TopMostPlayer.CapsuleComponent.WorldLocation + TopMostPlayer.CapsuleComponent.UpVector * TopMostPlayer.CapsuleComponent.ScaledCapsuleHalfHeight;
			float LowestAllowedZ = TopOfTopMostPlayerCapsule.Z - Extents.Y + 50.0;
			if(AveragePositionBetweenPlayers.Z < LowestAllowedZ)
				AveragePositionBetweenPlayers = FVector(AveragePositionBetweenPlayers.X, AveragePositionBetweenPlayers.Y, LowestAllowedZ);
		}
		
		FHitResult Hit;
		SetActorLocation(AveragePositionBetweenPlayers, false, Hit, bTeleport);
#if !RELEASE
		TEMPORAL_LOG(this).Point("Actor Location", ActorLocation, 1.f);
#endif
	}

	private void ValidateJumpHeightFreeze(AHazePlayerCharacter Player)
	{
		if(DevToggleIslandSidescrollerCamera::DisableJumpStay.IsEnabled())
			return;

		if(ShouldFreezeHeightAfterJump[Player])
		{
			if(MoveComp[Player].IsOnAnyGround()
			|| Time::GetGameTimeSince(TimeLastJumped[Player]) > JumpStayDuration
			|| Player.ActorCenterLocation.Z < HeightAtJump[Player])
			{
				float Offset = Player.ActorCenterLocation.Z - PlayerLocation[Player].Z; 
				AccJumpUpOffset[Player].SnapTo(-Offset);
				ShouldFreezeHeightAfterJump[Player] = false;
			}
		}
		else
		{
			if(JumpComp[Player].IsJumping())
			{
				TimeLastJumped[Player] = Time::GameTimeSeconds;
				HeightAtJump[Player] = Player.ActorCenterLocation.Z;
				ShouldFreezeHeightAfterJump[Player] = true;
			}
		}
	}

	private void ValidateDeath(AHazePlayerCharacter Player)
	{
		if(DevToggleIslandSidescrollerCamera::DisableStayWhenDied.IsEnabled())
			return;

		if(!IsDead[Player])
		{		
			if(Player.IsPlayerDead())
			{
				TimeOtherPlayerLastDied[Player.OtherPlayer] = Time::GameTimeSeconds;
				FVector OffsetToOtherPlayer = PlayerLocation[Player.OtherPlayer] - PlayerLocation[Player];
				AccOtherDeathOffset[Player.OtherPlayer].SnapTo(-OffsetToOtherPlayer * 0.5);

				IsDead[Player] = true;
			}
		}
		else
		{
			if(!Player.IsPlayerDead()
			&& !Player.IsPlayerRespawning())
			{
				IsDead[Player] = false;
			}
		}
	}

	private void ValidatePlayersOnScreen()
	{
		if(!IsAnyPlayerInFullscreen())
			return;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.IsPlayerDead())
			{
				HasBeenOnScreen[Player] = false;
				continue;
			}

			bool bIsOnScreen = IsPlayerOnScreen(Player);

			if(bIsOnScreen)
			{
				HasBeenOnScreen[Player] = true;
				if(PlayerKillBlocked[Player])
					SidescrollerComp[Player].RemoveEdgeColliderBlocker(this);

				PlayerKillBlocked[Player] = false;
			}
		}
	}

	bool ValidatePlayersHaveBeenGrounded()
	{
		if(HasBeenGrounded[0] && HasBeenGrounded[1])
			return true;

		bool bResult = true;
		for(AHazePlayerCharacter Current : Game::Players)
		{
			if(HasBeenGrounded[Current])
				continue;

			bool bIsGrounded = MoveComp[Current].HasGroundContact();
			if(bIsGrounded)
			{
				HasBeenGrounded[Current] = true;
				BlockPlayerKillUntilOnScreen(Current);
			}

			if(!HasBeenGrounded[Current])
				bResult = false;
		}

		return bResult;
	}

	private void HandleKillWhenOffScreen()
	{
		// If we aren't in fullscreen we shouldn't kill the player!
		if(!IsCurrentFullscreenCameraFocusingOnThisActor())
			return;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.IsPlayerDead())
				continue;

			if(!HasBeenOnScreen[Player])
				continue;

			if(PlayerKillBlocked[Player])
				continue;

			if(!HasBeenGrounded[Player])
				continue;

			FVector2D ClosestPlayerScreenPos = GetClosestPlayerScreenPos(Player);
			// Don't check with margin above the screen since we want to kill the player as soon as they get outside the screen to not make them be on top of the top collider
			if(ClosestPlayerScreenPos.X > 1.0 + HorizontalScreenKillMargin || ClosestPlayerScreenPos.X < -HorizontalScreenKillMargin ||
				ClosestPlayerScreenPos.Y > 1.0 + VerticalScreenKillMargin || ClosestPlayerScreenPos.Y < 0.0)
			{
				Player.KillPlayer();
				HasBeenOnScreen[Player] = false;
			}
		}
	}

	// The height offset of this object should lerp towards 0 as the distance between the players increases so that both players are always on screen.
	private float GetCurrentHeightOffset(float DeltaTime)
	{
		AcceleratedHeightOffset.AccelerateTo(TargetHeightOffset, TargetHeightOffsetLerpDuration, DeltaTime);

		FVector2D ScreenWorldExtents = GetWorldExtentsOfScreen();
		float ScreenHeight = ScreenWorldExtents.Y * 2.0;
		float HeightDiffBetweenPlayers = Math::Abs(Game::Mio.ActorLocation.Z - Game::Zoe.ActorLocation.Z) + Game::Mio.ScaledCapsuleHalfHeight * 2.0;

		if(ScreenHeight == 0.0)
			return AcceleratedHeightOffset.Value;

		return Math::Lerp(AcceleratedHeightOffset.Value, 0.0, Math::Saturate(HeightDiffBetweenPlayers / ScreenHeight));
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		if(DevToggleIslandSidescrollerCamera::DisableNoSnappingWhenRespawned.IsEnabled())
			return;

		TimeLastRespawned[RespawnedPlayer] = Time::GameTimeSeconds;
		FVector RespawnOffset = PlayerLocation[RespawnedPlayer.OtherPlayer] - RespawnedPlayer.ActorCenterLocation;
		AccRespawnOffset[RespawnedPlayer].SnapTo(RespawnOffset);
	}

	private bool IsAnyPlayerInFullscreen() const
	{
		return SidescrollerComp[0].IsInFullscreen() || SidescrollerComp[1].IsInFullscreen();
	}

	private AHazePlayerCharacter GetFullscreenPlayer() const
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(SidescrollerComp[Player].IsInFullscreen())
				return Player;
		}

		return nullptr;
	}

	private bool IsCurrentFullscreenCameraFocusingOnThisActor() const
	{
		if(!IsAnyPlayerInFullscreen())
			return false;

		AHazePlayerCharacter Player = GetFullscreenPlayer();
		UHazeCameraComponent Camera = Player.GetCurrentlyUsedCamera();
		auto Target = UCameraWeightedTargetComponent::Get(Camera.Owner);
		if(Target == nullptr)
			return false;
		
		for(FHazeCameraWeightedFocusTargetInfo Info : Target.Targets)
		{
			USceneComponent Focus = Info.GetFocusComponent(Player);
			if(Focus == nullptr)
				continue;

			if(Focus.Owner == this)
				return true;
		}

		return false;
	}

	private FVector GetWorldCenterOfScreen() const
	{
		return SidescrollerComp[Game::Mio].GetWorldCenterOfScreen();
	}

	private FVector ScreenPositionToWorldPosition(FVector2D ScreenPos) const
	{
		return SidescrollerComp[Game::Mio].ScreenPositionToWorldPosition(ScreenPos);
	}

	private FVector2D GetWorldExtentsOfScreen() const
	{
		return SidescrollerComp[Game::Mio].GetWorldExtentsOfScreen();
	}

	private FTransform GetSplineTransform() const
	{
		return SidescrollerComp[Game::Mio].SidescrollerTransform;
	}

	private FVector2D GetClosestPlayerScreenPos(AHazePlayerCharacter Player)
	{
		return SidescrollerComp[Player].GetClosestPlayerScreenPos();
	}

	private bool IsPlayerOnScreen(AHazePlayerCharacter Player)
	{
		FVector2D ScreenPos = GetClosestPlayerScreenPos(Player);
		return ScreenPos.X > 0.0 && ScreenPos.X < 1.0 && ScreenPos.Y > 0.0 && ScreenPos.Y < 1.0;
	}
}

namespace DevToggleIslandSidescrollerCamera
{
	const FHazeDevToggleCategory IslandSidescrollerCamera = FHazeDevToggleCategory(n"IslandSidescrollerCamera");
	const FHazeDevToggleBool DisableJumpStay = FHazeDevToggleBool(IslandSidescrollerCamera, n"Disable Jump Stay");
	const FHazeDevToggleBool DisableStayWhenDied = FHazeDevToggleBool(IslandSidescrollerCamera, n"Disable Stay when Died");
	const FHazeDevToggleBool DisableNoSnappingWhenRespawned = FHazeDevToggleBool(IslandSidescrollerCamera, n"Disable No snapping when respawned");
}