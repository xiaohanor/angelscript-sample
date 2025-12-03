class UVillageStealthOgreBoulderThrowCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AVillageStealthOgre Ogre;
	AHazePlayerCharacter TargetPlayer;

	float MaxDistance = 2500.0;
	float MaxDot = 0.7;

	float ThrowDelay = 0.2;
	bool bBoulderThrown = false;

	float ThrowTimer = 0.0;
	bool bThrowAnimationStarted = false;

	bool bThrowFinished = false;

	bool bBoulderRespawned = false;
	float BoulderRespawnDelay = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ogre = Cast<AVillageStealthOgre>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FVillageStealthOgreBoulderThrowCapabilityActivationParams& ActivationParams) const
	{	
		if (Ogre.CurrentState == EVillageStealthOgreState::TurningAround || Ogre.CurrentState == EVillageStealthOgreState::TurningBack)
			return false;

		AHazePlayerCharacter PlayerInRange = GetPlayerInRange();
		if (PlayerInRange != nullptr)
			ActivationParams.TargetPlayer = PlayerInRange;
		else
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ThrowTimer >= 2.4)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FVillageStealthOgreBoulderThrowCapabilityActivationParams ActivationParams)
	{
		TargetPlayer = ActivationParams.TargetPlayer;
		
		bBoulderThrown = false;
		bThrowFinished = false;
		bBoulderRespawned = false;
		bThrowAnimationStarted = false;
		ThrowTimer = 0.0;

		Ogre.AnimTargetLoc = TargetPlayer.ActorLocation;

		if (TargetPlayer.HasControl())
			CrumbStartThrowAnimation();
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartThrowAnimation()
	{
		bThrowAnimationStarted = true;

		UVillageStealthPlayerComponent PlayerComp = UVillageStealthPlayerComponent::GetOrCreate(TargetPlayer);
		PlayerComp.bBoulderThrownAtPlayer = true;

		Ogre.CurrentState = EVillageStealthOgreState::Throwing;

		UVillageStealthOgreEffectEventHandler::Trigger_ThrowBoulder(Ogre);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Ogre.CurrentState = EVillageStealthOgreState::Idle;
		if (!bBoulderRespawned)
			RespawnBoulder();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bThrowAnimationStarted)
		{
			if (ThrowTimer >= ThrowDelay)
			{
				if (!bBoulderThrown)
					ThrowBoulder();
			}
			else
				Ogre.AnimTargetLoc = TargetPlayer.ActorLocation;

			if (ThrowTimer >= BoulderRespawnDelay)
			{
				RespawnBoulder();
			}

			ThrowTimer += DeltaTime;
		}
	}

	void ThrowBoulder()
	{
		bBoulderThrown = true;
		Ogre.CurrentBoulder.ThrowBoulder(TargetPlayer, 2.0, 50.0);

		UVillageStealthPlayerComponent PlayerComp = UVillageStealthPlayerComponent::GetOrCreate(TargetPlayer);
		PlayerComp.ThrowBoulder(Ogre.CurrentBoulder);
	}

	void RespawnBoulder()
	{
		if (bBoulderRespawned)
			return;

		bBoulderRespawned = true;
		Ogre.RespawnBoulder();

		UVillageStealthOgreEffectEventHandler::Trigger_GrabNewBoulder(Ogre);
	}

	AHazePlayerCharacter GetPlayerInRange() const
	{
		AHazePlayerCharacter ThrowPlayer = nullptr;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (!Ogre.ExclusionTrigger.IsOverlappingActor(Player))
			{
				if (Ogre.GetDistanceTo(Player) <= MaxDistance)
				{
					FVector DirToPlayer = (Player.ActorLocation - Ogre.ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
					FVector Dir = Ogre.bTurnedAround ? -Ogre.ActorForwardVector : Ogre.ActorForwardVector;
					float DotToPlayer = DirToPlayer.DotProduct(Dir);
					if (DotToPlayer >= MaxDot)
					{
						FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
						Trace.IgnoreActor(Ogre);

						FHitResult Hit = Trace.QueryTraceSingle(Ogre.ActorCenterLocation, Player.ActorCenterLocation);

						if (Hit.bBlockingHit)
						{
							AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
							if (HitPlayer != nullptr)
							{
								UVillageStealthPlayerComponent PlayerComp = UVillageStealthPlayerComponent::GetOrCreate(HitPlayer);
								if (!HitPlayer.IsPlayerDead() && !PlayerComp.bBoulderThrownAtPlayer)
									ThrowPlayer = HitPlayer;
							}
						}
					}
				}
			}
		}

		return ThrowPlayer;
	}
}

struct FVillageStealthOgreBoulderThrowCapabilityActivationParams
{
	AHazePlayerCharacter TargetPlayer;
}