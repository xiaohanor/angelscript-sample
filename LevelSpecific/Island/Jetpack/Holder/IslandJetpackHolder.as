event void IslandJetpackHolderEventSignature();

class AIslandJetpackHolder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent PowerIndicatorMesh;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractComp;
	default InteractComp.InteractionCapability = n"IslandJetpackHolderInteractionCapability";

	UPROPERTY(DefaultComponent)
	USceneComponent JetpackPlacementLocation;

	UPROPERTY(DefaultComponent, Attach = JetpackPlacementLocation)
	USceneComponent FakeJetpackRoot;

	UPROPERTY(DefaultComponent, Attach = FakeJetpackRoot)
	UHazeSkeletalMeshComponentBase FakeJetpack;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	bool bMio;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UMaterialInterface PoweredMaterial;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bIsDoubleInteract = true;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (EditCondition = bIsDoubleInteract, EditConditionHides))
	AIslandJetpackHolder OtherHolder;

	UPROPERTY(EditAnywhere, Category = "Animation")
	FHazePlaySlotAnimationParams PlacingAnim;

	UPROPERTY(Category = "Events")
	IslandJetpackHolderEventSignature OnJetpackPlaced;

	UPROPERTY(Category = "Events")
	IslandJetpackHolderEventSignature OnBothJetpacksPlaced;

	UPROPERTY(EditDefaultsOnly)
	USkeletalMesh MioJetpackMesh;

	UPROPERTY(EditDefaultsOnly)
	USkeletalMesh ZoeJetpackMesh;

	TArray<UHazeSkeletalMeshComponentBase> JetpackMeshes;

	bool bHasInteracted = false;
	bool bJetpackIsPlaced = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.AddInteractionCondition(this, FInteractionCondition(this, n"CanInteractWith"));

		FakeJetpackRoot.GetChildrenComponentsByClass(UHazeSkeletalMeshComponentBase, true, JetpackMeshes);
		ToggleVisualsOfFakeJetpack(false);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bIsDoubleInteract)
		{
			if(OtherHolder != nullptr)
			{
				OtherHolder.OtherHolder = this;
				OtherHolder.bIsDoubleInteract = true;
			}
		}
		else
		{
			if(OtherHolder != nullptr)
			{
				OtherHolder.OtherHolder = nullptr;
				OtherHolder.bIsDoubleInteract = false;
				OtherHolder = nullptr;
			}
		}

		if(bMio)
		{
			FakeJetpack.SkeletalMeshAsset = MioJetpackMesh;
		}
		else
		{
			FakeJetpack.SkeletalMeshAsset = ZoeJetpackMesh;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private EInteractionConditionResult CanInteractWith(
	                                                    const UInteractionComponent InteractionComponent,
	                                                    AHazePlayerCharacter Player)
	{
		auto JetpackComp = UIslandJetpackComponent::Get(Player);
		if(JetpackComp == nullptr)
			return EInteractionConditionResult::Disabled;

		if(!JetpackComp.IsOn())
			return EInteractionConditionResult::Disabled;

		if(bHasInteracted)
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}

	void ToggleVisualsOfFakeJetpack(bool bToggleOn)
	{
		for(auto Mesh : JetpackMeshes)
		{
			Mesh.ToggleVisibility(bToggleOn);
		}
	}
};