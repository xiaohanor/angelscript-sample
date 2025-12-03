event void FOnPlayerCaughtBomb(AHazePlayerCharacter Player, AGameShowArenaBomb Bomb);

struct FGameShowArenaBombTossAnimationParams
{
	float ThrowAngle = 0;
	bool bCatch = false;
	bool bThrow = false;
}

class UGameShowArenaBombTossPlayerComponent : UActorComponent
{
	access ReadOnly = private, *(readonly);

	UPROPERTY(EditAnywhere)
	TSubclassOf<UTargetableWidget> BombTargetableWidget;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect CatchFF;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ThrowFF;

	FOnPlayerCaughtBomb OnPlayerCaughtBomb;

	AHazePlayerCharacter Player;

	access: ReadOnly AGameShowArenaBomb CurrentBomb;
	AGameShowArenaBomb CurrentGrapplingBomb;

	UPlayerMovementComponent MoveComp;
	UPlayerAimingComponent AimComp;
	UGameShowArenaBombTargetComponent TargetComp;
	URagdollComponent RagdollComp;

	float CooldownToCatchAfterThrowing = 0.5;
	float CooldownToThrowAfterCatching = 0.5;

	bool bHoldingBomb = false;
	bool bIsRagdolling = false;
	bool bIsInteracting = false;
	bool bHasIncomingBomb = false;
	bool bHasBlockedInteraction = false;

	const float CatchSphereRadius = 550;

	float TimeWhenCaughtBomb = -MAX_flt;
	float TimeWhenThrewBomb = -MAX_flt;

	float TimeWhenLastTriedToCatch = -MAX_flt;


	FGameShowArenaBombTossAnimationParams AnimParams;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		TargetComp = UGameShowArenaBombTargetComponent::GetOrCreate(Player);
		TargetComp.SetWorldLocation(Player.ActorCenterLocation);
		TargetComp.DisableForPlayer(Player, this);
		RagdollComp = URagdollComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("TimeWhenCaughtBomb", TimeWhenCaughtBomb);
		TemporalLog.Value("TimeWhenThrewBomb", TimeWhenThrewBomb);
		TemporalLog.Value("CurrentBomb", CurrentBomb);
		TemporalLog.Value("bIsHoldingBomb", bHoldingBomb);
#endif
	}

	void HandleOnBombStartExploding()
	{
		if (bHasBlockedInteraction)
			return;
		
		UPlayerInteractionsComponent::Get(Player).KickPlayerOutOfAnyInteraction();
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		bHasBlockedInteraction = true;
		Timer::SetTimer(this, n"HandlePostBombExplosion", 1.5);
	}
	
	UFUNCTION()
	private void HandlePostBombExplosion()
	{
		if (!bHasBlockedInteraction)
			return;

		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		bHasBlockedInteraction = false;
	}

	void HandleInteractionStart()
	{
		TargetComp.DisableForPlayer(Player.OtherPlayer, this);
		bIsInteracting = true;
	}

	void HandleInteractionEnd()
	{
		TargetComp.EnableForPlayer(Player.OtherPlayer, this);
		bIsInteracting = false;
	}

	void ApplyExplosionRagdoll(FVector ExplosionLocation)
	{
		if (!RagdollComp.bIsRagdolling)
		{
			Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
			Player.BlockCapabilities(CapabilityTags::Movement, this);
			Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
			RagdollComp.PendingImpulses.Add(this, FRagdollImpulse(ERagdollImpulseType::WorldSpace, (Player.ActorCenterLocation - ExplosionLocation).GetSafeNormal() * 5000 + FVector::UpVector * 1000, ExplosionLocation));
			RagdollComp.ApplyRagdoll(Player.Mesh, Player.CapsuleComponent);
			bIsRagdolling = true;
		}
	}

	void ClearExplosionRagdoll()
	{
		if (RagdollComp.bIsRagdolling)
		{
			RagdollComp.PendingImpulses.Remove(this);
			RagdollComp.ClearRagdoll(Player.Mesh, Player.CapsuleComponent);
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
			Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
			bIsRagdolling = false;
		}
	}

	void AssignBomb(AGameShowArenaBomb Bomb)
	{
		CurrentBomb = Bomb;
	}

	UFUNCTION()
	void RemoveBomb()
	{
		if (CurrentBomb == nullptr)
			return;
		
		if (CurrentBomb.AttachParentActor == Player)
			CurrentBomb.DetachFromActor();

		CurrentBomb = nullptr;
		bHoldingBomb = false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbRemoveBomb()
	{
		RemoveBomb();
	}

	bool HasRecentlyThrownBomb() const
	{
		return Time::GetGameTimeSince(TimeWhenThrewBomb) < CooldownToCatchAfterThrowing;
	}

	bool HasRecentlyCaughtBomb() const
	{
		return Time::GetGameTimeSince(TimeWhenCaughtBomb) < CooldownToThrowAfterCatching;
	}

	bool CanCatchBomb(AGameShowArenaBomb Bomb)
	{
		if (CurrentBomb != nullptr)
			return false;

		if (Bomb.Thrower == Player)
			return false;

		if (Bomb.State.Get() == EGameShowArenaBombState::Exploding)
			return false;

		if (Bomb.IsActorDisabled())
			return false;

		if (HasRecentlyThrownBomb())
			return false;

		if (Bomb.Holder != nullptr)
			return false;

		if (Player.ActorLocation.DistSquared(Bomb.ActorLocation) > CatchSphereRadius * CatchSphereRadius)
			return false;

		return true;
	}

	// bool ShouldGrappleTowardsEachOther(AGameShowArenaBomb Bomb) const
	// {
	// 	if (Bomb.VelocityMagnitude < GrappleSignificantVelocityThreshold)
	// 		return false;

	// 	if (Bomb.bGrappleTowardsEachOtherRequiresAirborne && MoveComp.HasGroundContact())
	// 		return false;

	// 	return true;
	// }
}