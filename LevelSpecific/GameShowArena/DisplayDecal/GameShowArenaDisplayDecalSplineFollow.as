class AGameShowArenaDisplayDecalSplineFollow : AKineticSplineFollowActor
{
	// UPROPERTY(EditAnywhere)
	// TArray<ABombToss_Platform> TargetPlatforms;

	UPROPERTY(EditInstanceOnly, meta = (Bitmask, BitmaskEnum = "/Script/Angelscript.EBombTossChallenges"))
	int BombTossChallengeUses = 0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditAnywhere)
	UTexture2D Texture;

	UPROPERTY(EditAnywhere)
	FLinearColor Tint = FLinearColor::Green;

	UPROPERTY(EditAnywhere)
	FName MaterialSlotName = n"GameShowPanel_01";

	UPROPERTY(EditAnywhere)
	FVector Scale = FVector::OneVector * 150;

	UPROPERTY(EditAnywhere)
	float Opacity = 100;

	UPROPERTY(EditAnywhere)
	bool bIsAlternateDecal;

	/** Currently we use box overlap to only change material params on overlapped platforms */
	UPROPERTY(DefaultComponent)
	UBoxComponent Box;
	default Box.bHiddenInGame = true;
	default Box.SetBoxExtent(FVector(100, 100, 100));

	TArray<UGameShowArenaDisplayDecalPlatformComponent> PreviouslyOverlappedDisplayComps;

	default DisableComp.AutoDisableRange = 20000;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		for (auto DisplayComp : PreviouslyOverlappedDisplayComps)
		{
			DisplayComp.ClearMaterialParameters(bIsAlternateDecal);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		TArray<AActor> NewOverlaps;
		Box.GetOverlappingActors(NewOverlaps);

		TArray<UGameShowArenaDisplayDecalPlatformComponent> OverlappedDisplayComps;
		for (auto Overlap : NewOverlaps)
		{
			auto DisplayComp = UGameShowArenaDisplayDecalPlatformComponent::Get(Overlap);
			if (DisplayComp == nullptr)
				continue;
			
			if (!DisplayComp.CanUpdateParams())
				continue;

			DisplayComp.UpdateMaterialParameters(FGameShowArenaDisplayDecalParams(FTransform(ActorRotation, ActorLocation, Scale), Texture, DecalOpacity = Opacity, DecalColor = Tint), bIsAlternateDecal, MaterialSlotName);
			OverlappedDisplayComps.AddUnique(DisplayComp);
		}

		for (auto DisplayComp : PreviouslyOverlappedDisplayComps)
		{
			if (OverlappedDisplayComps.Contains(DisplayComp))
				continue;

			DisplayComp.UpdateMaterialParameters(FGameShowArenaDisplayDecalParams(FTransform(ActorRotation, ActorLocation, Scale), Texture, DecalOpacity = 0, DecalColor = Tint), bIsAlternateDecal, MaterialSlotName);
		}
		PreviouslyOverlappedDisplayComps = OverlappedDisplayComps;
	}
}