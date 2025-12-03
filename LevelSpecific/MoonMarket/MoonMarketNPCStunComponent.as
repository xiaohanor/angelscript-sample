class UMoonMarketNPCStunComponent : UActorComponent
{
	float StunDuration = 0;

	UPROPERTY(EditDefaultsOnly)
	float BallStunDuration = 1.5;

	UPROPERTY(EditDefaultsOnly)
	float FireworkStunDuration = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(UMoonMarketThunderStruckComponent::Get(Owner) != nullptr)
		{
			UMoonMarketThunderStruckComponent::Get(Owner).OnStruckByThunder.AddUFunction(this, n"ThunderStun");
		}

		if(UFireworksResponseComponent::Get(Owner) != nullptr)
		{
			UFireworksResponseComponent::Get(Owner).OnFireWorksImpact.AddUFunction(this, n"FireworkStun");
		}

		if(UMoonMarketBouncyBallResponseComponent::Get(Owner) != nullptr)
		{
			UMoonMarketBouncyBallResponseComponent::Get(Owner).OnHitByBallEvent.AddUFunction(this, n"BouncyBallStun");
		}

		if(UMoonMarketTrumpetHonkResponseComponent::Get(Owner) != nullptr)
		{
			UMoonMarketTrumpetHonkResponseComponent::Get(Owner).OnHonkedAt.AddUFunction(this, n"TrumpetStun");
		}
	}

	UFUNCTION()
	private void TrumpetStun(AHazePlayerCharacter InstigatingPlayer)
	{
		StunDuration = BallStunDuration;
	}

	UFUNCTION()
	private void ThunderStun(FMoonMarketThunderStruckData Data)
	{
		//StunDuration = 3;
	}

	UFUNCTION()
	private void BouncyBallStun(FMoonMarketBouncyBallHitData Data)
	{
		StunDuration = BallStunDuration;
	}

	UFUNCTION()
	private void FireworkStun(FMoonMarketFireworkImpactData Data)
	{
		StunDuration = FireworkStunDuration;
	}
};