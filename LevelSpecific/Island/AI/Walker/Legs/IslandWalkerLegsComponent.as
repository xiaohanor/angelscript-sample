event void IslandWalkerLegOnLegDestroyedSignature(AIslandWalkerLegTarget Leg);
event void IslandWalkerLegOnFellSignature();
event void IslandWalkerLegsForVO();

class UIslandWalkerLegsComponent : UActorComponent
{
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIHealthComponent HealthComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	
	IslandWalkerLegOnLegDestroyedSignature OnLegDestroyed;
	
	// Walker has fallen after all the legs got cut off
	IslandWalkerLegOnFellSignature OnFallComplete;

	AAIIslandWalker Walker;

	UPROPERTY()
	TArray<AIslandWalkerLegTarget> LegTargets;
	
	UPROPERTY()
	IslandWalkerLegsForVO LegDestroyed;

	bool bIsUnbalanced;
	float DestroyedLegTime;
	float ShowLegsTime;
	bool bIsPoweredUp = true;

	EIslandWalkerUnbalancedDirection UnbalancedDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Walker = Cast<AAIIslandWalker>(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
	}

	void Reset()
	{
		bIsUnbalanced = false;
	}

	void PowerDownLegs()
	{
		bIsPoweredUp = false;
		for(AIslandWalkerLegTarget Leg : LegTargets)
		{
			Leg.PowerDown();
		}
	}

	void PowerUpLegs()
	{
		bIsPoweredUp = true;
		for(AIslandWalkerLegTarget Leg : LegTargets)
		{
			Leg.PowerUp();
			Leg.OnCoverOpened.AddUFunction(this, n"OnLegCoverOpened");
		}
	}

	UFUNCTION()
	private void OnLegCoverOpened(AIslandWalkerLegTarget OpenedTargetCover)
	{
		// Close all other covers
		for (AIslandWalkerLegTarget LegTarget : LegTargets)
		{
			if (LegTarget != OpenedTargetCover)
				LegTarget.CloseCover();	
		}
	}

	void DisableLegs(FInstigator Instigator)
	{
		for(AIslandWalkerLegTarget Target: LegTargets)
		{
			Target.AddActorDisable(Instigator);
		}
	}

	void EnableLegss(FInstigator Instigator)
	{
		for(AIslandWalkerLegTarget Target: LegTargets)
		{
			Target.RemoveActorDisable(Instigator);
		}
	}

	void ShowLegs()
	{
		ShowLegsTime = Time::GetGameTimeSeconds();
	}

	void HideLegs()
	{
		ShowLegsTime = 0;
	}

	void AddLeg(AIslandWalkerLegTarget Leg)
	{
		LegTargets.Add(Leg);
	}

	void DestroyLeg(AIslandWalkerLegTarget Leg)
	{
		ShowLegsTime = 0;
		if (HasBecomeUnbalanced())
			SetUnbalanced(EIslandWalkerUnbalancedDirection::Forward);
		DestroyedLegTime = Time::GetGameTimeSeconds();			
		HealthComp.TakeDamage(0.1, EDamageType::Default, Game::Zoe);
		OnLegDestroyed.Broadcast(Leg);
		LegDestroyed.Broadcast();
	}

	int NumDestroyedLegs()
	{
		int DestroyedCount = 0;
		for(AIslandWalkerLegTarget Leg : LegTargets)
		{
			if (Leg.bIsDestroyed)
				DestroyedCount++;
		}		
		return DestroyedCount;
	}

	private bool HasBecomeUnbalanced()
	{
		if(bIsUnbalanced)
			return false; // Already unbalanced

		for(AIslandWalkerLegTarget Leg : LegTargets)
		{
			if (!Leg.bIsDestroyed)
				return false; // Found an intact leg
		}

		// All legs are destroyed
		return true;
	}

	private void SetUnbalanced(EIslandWalkerUnbalancedDirection InUnbalancedDirection)
	{
		UnbalancedDirection = InUnbalancedDirection;
		bIsUnbalanced = true;
	}
}

enum EIslandWalkerUnbalancedDirection
{
	Forward,
	Left,
	Right,
	MAX
}