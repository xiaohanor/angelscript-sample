enum EMeltdownBossPhaseTwoWorld
{
	LavaRiver,
	Vortex,
	Space,
}

UCLASS(HideCategories = "Debug Activation Collision Cooking Rendering Actor Tags")
class AMeltdownBossPhaseTwoManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(EditAnywhere, EditFixedSize, Meta = (ArraySizeEnum = "/Script/Angelscript.EMeltdownBossPhaseTwoWorld"))
	TArray<UHazePlayerVariantAsset> PlayerVariants;
	default PlayerVariants.SetNum(3);

	bool bAppliedVariant = false;

	UFUNCTION(BlueprintPure)
	AMeltdownBossPhaseTwoLevelAnchor GetAnchorForWorld(EMeltdownBossPhaseTwoWorld AnchorWorld) const
	{
		TListedActors<AMeltdownBossPhaseTwoLevelAnchor> AnchorList;
		for (AMeltdownBossPhaseTwoLevelAnchor Anchor : AnchorList)
		{
			if (Anchor.AnchorWorld == AnchorWorld)
				return Anchor;
		}

		return nullptr;
	}
	
	UFUNCTION(BlueprintPure)
	FVector Position_Convert(FVector Location, EMeltdownBossPhaseTwoWorld SourceWorld, EMeltdownBossPhaseTwoWorld TargetWorld) const
	{
		if (SourceWorld == TargetWorld)
			return Location;

		FVector TargetLocation = Location;
		TListedActors<AMeltdownBossPhaseTwoLevelAnchor> AnchorList;
		for (AMeltdownBossPhaseTwoLevelAnchor Anchor : AnchorList)
		{
			if (Anchor.AnchorWorld == SourceWorld)
				TargetLocation -= Anchor.ActorLocation;
			else if (Anchor.AnchorWorld == TargetWorld)
				TargetLocation += Anchor.ActorLocation;
		}

		return TargetLocation;
	}

	UFUNCTION(BlueprintPure)
	EMeltdownBossPhaseTwoWorld GetCurrentWorld() const
	{
		return GetClosestWorldTo(Game::Mio.ActorLocation);
	}

	UFUNCTION(BlueprintPure)
	EMeltdownBossPhaseTwoWorld GetClosestWorldTo(FVector Location) const
	{
		EMeltdownBossPhaseTwoWorld ClosestWorld = EMeltdownBossPhaseTwoWorld::LavaRiver;
		float ClosestDist = MAX_flt;
		
		TListedActors<AMeltdownBossPhaseTwoLevelAnchor> AnchorList;
		for (AMeltdownBossPhaseTwoLevelAnchor Anchor : AnchorList)
		{
			float Dist = Anchor.ActorLocation.DistSquared(Location);
			if (Dist < ClosestDist)
			{
				ClosestDist = Dist;
				ClosestWorld = Anchor.AnchorWorld;
			}
		}
		return ClosestWorld;
	}

	UFUNCTION(DevFunction)
	void TeleportPlayersToWorld(EMeltdownBossPhaseTwoWorld TargetWorld)
	{
		for (auto Player : Game::Players)
		{
			Player.TeleportActor(
				Position_Convert(
					Player.ActorLocation,
					GetClosestWorldTo(Player.ActorLocation),
					TargetWorld,
				),
				Player.ActorRotation,
				this,
				false,
			);

			auto Variant = PlayerVariants[int(TargetWorld)];
			if (Variant != nullptr)
			{
				auto PlayerVariantComp = UPlayerVariantComponent::Get(Player);
				PlayerVariantComp.ApplyPlayerVariantOverride(Variant, this, EInstigatePriority::High);
			}
		}
	}

	UFUNCTION()
	void TeleportActorToWorld(AActor Actor, EMeltdownBossPhaseTwoWorld TargetWorld)
	{
		if (Actor == nullptr)
			return;
		Actor.ActorLocation = Position_Convert(
			Actor.ActorLocation,
			GetClosestWorldTo(Actor.ActorLocation),
			TargetWorld,
		);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bAppliedVariant)
		{
			bAppliedVariant = true;
			for (auto Player : Game::Players)
			{
				auto Variant = PlayerVariants[int(GetCurrentWorld())];
				if (Variant != nullptr)
				{
					auto PlayerVariantComp = UPlayerVariantComponent::Get(Player);
					PlayerVariantComp.ApplyPlayerVariantOverride(Variant, this, EInstigatePriority::High);
				}
			}
		}
	}
};

UCLASS(HideCategories = "Debug Activation Collision Cooking Rendering Actor Tags")
class AMeltdownBossPhaseTwoLevelAnchor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;

	UPROPERTY(EditAnywhere)
	int EditorOrder;
	UPROPERTY(EditAnywhere)
	FString EditorGlyph;
	UPROPERTY(EditAnywhere)
	FLinearColor EditorColor;

	bool bShowInOverlay = true;
#endif

	UPROPERTY(EditAnywhere)
	EMeltdownBossPhaseTwoWorld AnchorWorld;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}

#if EDITOR
	int opCmp(AMeltdownBossPhaseTwoLevelAnchor Other) const
	{
		if (EditorOrder < Other.EditorOrder)
			return -1;
		else if (EditorOrder > Other.EditorOrder)
			return 1;
		else
			return EditorGlyph.Compare(Other.EditorGlyph);
	}
#endif
};

namespace AMeltdownBossPhaseTwoManager
{
	AMeltdownBossPhaseTwoManager Get()
	{
		return TListedActors<AMeltdownBossPhaseTwoManager>().GetSingle();
	}
}