UCLASS(Abstract)
class AMoonMarketAmbientCritter : AHazeSkeletalMeshActor
{
	UPROPERTY(DefaultComponent)
	UMoonMarketThunderStruckComponent ThunderResponseComp;

	UPROPERTY(DefaultComponent)
	UFireworksResponseComponent FireworkResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketBouncyBallResponseComponent CandyResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketTrumpetHonkResponseComponent TrumpetResponseComp;

	UPROPERTY(DefaultComponent)
	UPolymorphResponseComponent PolymorphResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketPolymorphAutoAimComponent PolymorphAutoAimComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketNPCPolymorphCapability");

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams BigReaction;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams SmallReaction;

	UPROPERTY(EditDefaultsOnly)
	FString CritterName;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ThunderResponseComp.OnStruckByThunder.AddUFunction(this, n"OnThunderStruck");
		CandyResponseComp.OnHitByBallEvent.AddUFunction(this, n"OnHitByCandy");
		FireworkResponseComp.OnFireWorksImpact.AddUFunction(this, n"OnHitByFirework");
		TrumpetResponseComp.OnHonkedAt.AddUFunction(this, n"OnHonkedAt");
	}

	UFUNCTION()
	private void OnThunderStruck(FMoonMarketThunderStruckData Data)
	{
		Mesh.PlaySlotAnimation(BigReaction);
		FMoonMarketAmbientCritterEventParams Params;
		Params.CritterName = CritterName;
		UMoonMarketAmbientCritterEventHandler::Trigger_OnBigReaction(this, Params);
	}

	UFUNCTION()
	private void OnHitByFirework(FMoonMarketFireworkImpactData Data)
	{
		Mesh.PlaySlotAnimation(BigReaction);
		FMoonMarketAmbientCritterEventParams Params;
		Params.CritterName = CritterName;
		UMoonMarketAmbientCritterEventHandler::Trigger_OnBigReaction(this, Params);
	}

	UFUNCTION()
	private void OnHonkedAt(AHazePlayerCharacter InstigatingPlayer)
	{
		Mesh.PlaySlotAnimation(SmallReaction);
		FMoonMarketAmbientCritterEventParams Params;
		Params.CritterName = CritterName;
		UMoonMarketAmbientCritterEventHandler::Trigger_OnSmallReaction(this, Params);
	}

	UFUNCTION()
	private void OnHitByCandy(FMoonMarketBouncyBallHitData Data)
	{
		Mesh.PlaySlotAnimation(SmallReaction);
		FMoonMarketAmbientCritterEventParams Params;
		Params.CritterName = CritterName;
		UMoonMarketAmbientCritterEventHandler::Trigger_OnSmallReaction(this, Params);
	}
};
