enum ETargetableOutlineParents
{
	None,
	Parent,
	AllParents
}

struct FTargetableOutlinePrimitiveArray
{
	TArray<UPrimitiveComponent> Array;
}

enum ETargetableOutlineType
{
	Target,
	Primary,
	Visible,
	Grabbed
}

class UTargetableOutlineDataAsset : UDataAsset
{
	/**
	 * Targetable category. If NAME_None, we will assume that this is a valid outline for any targetable component.
	 * If you are experiencing issues where the outline appears for the wrong aiming, set this to the same category
	 * as the targetable.
	 */
	UPROPERTY()
	FName TargetableCategory = NAME_None;
	
	/**
	 * Which players to show the outline on.
	 * Both means that the outline can be shown for any targeting player.
	 */
    UPROPERTY()
	EHazeSelectPlayer Player = EHazeSelectPlayer::Both;

	/**
	 * Should the outline be visible on the other player's screen if we are playing in fullscreen.
	 */
    UPROPERTY()
	bool bAlwaysShowInFullscreen = false;
	
	/**
	 * The default OutlineData. If the target is targetable this will be visible.
	 * If no bUsePrimarySpecificOutlineData is false, then this will be used as primary as well.
	 * Note: The asset defines what player can see it. If it's not showing up, make sure that the asset has the correct player assigned.
	 */

    UPROPERTY()
	UMaterialInstance OverlayMaterial;
	 
    UPROPERTY(Category = "Targetable")
	UOutlineDataAsset TargetableOutlineAsset;

	/**
	 * Optional: Use another OutlineData asset for when we are the primary target.
	 */

	UPROPERTY(Category = "Primary")
	bool bUsePrimarySpecificOutline = false;
	
    UPROPERTY(Category = "Primary", Meta = (EditCondition = "bUsePrimarySpecificOutline"))
	UOutlineDataAsset PrimaryOutlineAsset;

	/**
	 * Optional: Use another OutlineData asset for when we are visible, but not targetable
	 */
	UPROPERTY(Category = "Visible")
	bool bUseVisibleSpecificOutline = false;

    UPROPERTY(Category = "Visible", Meta = (EditCondition = "bUseVisibleSpecificOutline"))
	UOutlineDataAsset VisibleOutlineAsset;


	bool GetOutline(ETargetableOutlineType OutlineType, UOutlineDataAsset&out OutlineData, ETargetableOutlineType&out ResultOutlineType) const
	{
		ResultOutlineType = OutlineType;

		switch(OutlineType)
		{
			case ETargetableOutlineType::Primary:
			{
				if(bUsePrimarySpecificOutline)
				{
					OutlineData = PrimaryOutlineAsset;
					ResultOutlineType = ETargetableOutlineType::Primary;
				}
				else
				{
					OutlineData = TargetableOutlineAsset;
					ResultOutlineType = ETargetableOutlineType::Target;
				}

				break;
			}
			case ETargetableOutlineType::Target:
			{
				OutlineData = TargetableOutlineAsset;
				ResultOutlineType = ETargetableOutlineType::Target;
				break;
			}
			case ETargetableOutlineType::Visible:
			{
				if(bUseVisibleSpecificOutline)
				{
					OutlineData = VisibleOutlineAsset;
					ResultOutlineType = ETargetableOutlineType::Visible;
					break;
				}
				else
				{
					return false;
				}
			}
			case ETargetableOutlineType::Grabbed:
			{
				if(bUsePrimarySpecificOutline)
				{
					OutlineData = PrimaryOutlineAsset;
					ResultOutlineType = ETargetableOutlineType::Grabbed;
				}
				else
				{
					OutlineData = TargetableOutlineAsset;
					ResultOutlineType = ETargetableOutlineType::Grabbed;
				}

				break;
			}
			default:
				devError("Unhandled ETargetableOutlineType! in GetOutline()");
				return false;
		}

		return true;
	}
};

/**
 * A component for adding outlines to a TargetableComponent in a similar fashion to how TargetableWidgets can be shown.
 * Use case: Either call Apply each frame, or call ShowOutlinesForTargetables on a PlayerTargetableComponent.
 * That the outline resets itself if not applied every frame is an intentional feature. If a more permanent outline is desired,
 * consider using the Outline:: namespace directly instead.
 */
 UCLASS(HideCategories = "Rendering Debug Activation Cooking LOD Collision ComponentTick Disable")
class UTargetableOutlineComponent : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default TickGroup = ETickingGroup::TG_PostUpdateWork;

	access DefaultAccess = protected, * (editdefaults, readonly);

	UPROPERTY(EditAnywhere, Category = "Targetable Outline")
	bool bStartBlocked = false;

	UPROPERTY(EditAnywhere, Category = "Targetable Outline", Meta = (EditCondition = "bStartBlocked", EditConditionHides))
	FName StartBlockedInstigator = n"StartBlocked";
	
	UPROPERTY(EditAnywhere, Category = "Targetable Outline")
	access:DefaultAccess
	UTargetableOutlineDataAsset TargetableOutlineData;

	UPROPERTY(EditAnywhere, Category = "Targetable Outline")
	access:DefaultAccess
	EInstigatePriority Priority = EInstigatePriority::Normal;

	/**
	 * Should any outlines be allowed when the targetable is only visible, but not a possible target.
	 */
	UPROPERTY(EditAnywhere, Category = "Targetable Outline")
	access:DefaultAccess
	bool bAllowOutlineWhenNotPossibleTarget = true;

	/**
	 * Should we outline ourselves?
	 * Note: Cannot be combined with outlining specific components on this actor!
	 */
	UPROPERTY(EditAnywhere, Category = "Targetable Outline|Actors")
	access:DefaultAccess
	bool bOutlineSelfActor = true;

	/**
	 * Should we outline our parent actors?
	 * Select either just the closest parent, or all parents
	 */
	UPROPERTY(EditAnywhere, Category = "Targetable Outline|Actors")
	access:DefaultAccess
	ETargetableOutlineParents OutlineParents;

	UPROPERTY(EditAnywhere, Category = "Targetable Outline|Actors")
	access:DefaultAccess
	bool bOutlineAttachedActors;

	/**
	 * Specify additional actors to outline.
	 */
	UPROPERTY(EditInstanceOnly, Category = "Targetable Outline|Actors")
	access:DefaultAccess
	TArray<AActor> ActorsToOutline;

	/**
	 * Should all PrimitiveComponents attached to this component be outlined?
	 * Note: Will include all descendants, not just the closest children.
	 * Note: Not available when bOutlineSelfActor is disabled, since otherwise all components will already be outlined.
	 */
	UPROPERTY(EditAnywhere, Category = "Targetable Outline|Components", Meta = (EditCondition = "!bOutlineSelfActor"))
	access:DefaultAccess
	bool bOutlineChildComponents = false;

	/**
	 * Should the PrimitiveComponent this component is attached to be outlined?
	 * Note: This will only outline the direct parent, not the parent of that etc.
	 * Note: Not available when bOutlineSelfActor is disabled, since otherwise all components will already be outlined.
	 */
	UPROPERTY(EditAnywhere, Category = "Targetable Outline|Components", Meta = (EditCondition = "!bOutlineSelfActor"))
	access:DefaultAccess
	bool bOutlineParentComponent = false;

	/**
	 * Specify additional components to outline.
	 */
	UPROPERTY(EditDefaultsOnly, Category = "Targetable Outline|Components")
	access:DefaultAccess
	TArray<FComponentReference> ComponentsToOutline;

	/**
	 * Specify additional components to outline.
	 */
	UPROPERTY(EditInstanceOnly, Category = "Targetable Outline|Components", Meta = (UseComponentPicker, AllowAnyActor, AllowedClasses = "/Script/Engine.PrimitiveComponent"))
	access:DefaultAccess
	TArray<FComponentReference> ComponentsToOutlineInstance;

	UPROPERTY(EditAnywhere, Category = "Targetable Outline")
	float OutlineOpacity = 1;

	private UTargetableComponent TargetComp;
	private TArray<AActor> OutlinedActors;
	private TMap<AActor, FTargetableOutlinePrimitiveArray> OutlinedComponents;
	private bool bInitialized = false;
	private uint LastAppliedFrame = 0;
	private TArray<FInstigator> BlockInstigators;
	private float OverlayMaterialFade = 0;
	private float OverlayMaterialFadeTarget = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bStartBlocked)
			BlockOutline(StartBlockedInstigator);

		Initialize();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Time::FrameNumber > LastAppliedFrame)
		{
			// We did not apply last frame, clear the outline
			ClearOutline();
		}
		
		OverlayMaterialFade = Math::FInterpConstantTo(OverlayMaterialFade, OverlayMaterialFadeTarget, DeltaSeconds, 1);

		if(OverlayMaterialFade == 0)
		{
			SetComponentTickEnabled(false);
		}
		if(OverlayMaterialFade == 0 || (OverlayMaterialFade < 1 && OverlayMaterialFade > OverlayMaterialFadeTarget)) // fading out
		{
			for(auto Actor : OutlinedActors)
			{
				SetOverlayMaterialFadeOnActor(Actor, Game::Mio, nullptr, ETargetableOutlineType::Visible);
				if(OverlayMaterialFade == 0)
					SetOverlayMaterialOnActor(Actor, Game::Mio, nullptr, ETargetableOutlineType::Visible);
			}

			// Clear component outlines
			for(auto ActorAndComponents : OutlinedComponents)
			{
				SetOverlayMaterialFadeOnComponents(ActorAndComponents.Value.Array, Game::Mio, nullptr, ETargetableOutlineType::Visible);
				if(OverlayMaterialFade == 0)
					SetOverlayMaterialOnComponents(ActorAndComponents.Value.Array, Game::Mio, nullptr, ETargetableOutlineType::Visible);
			}
		}
	}

	private void Initialize()
	{
		check(!bInitialized, "TargetableOutlineComponent has already been initialized!");
		bInitialized = true;

		if(TargetableOutlineData == nullptr)
		{
			#if EDITOR
			devError(f"TargetableOutlineComponent attached to {Owner.GetActorLabel()} does not have a TargetableOutlineData asset assigned!");
			#endif
			return;
		}

		TargetComp = UTargetableComponent::Get(Owner);
		if(TargetComp == nullptr)
			return;

		// Add self to outlined actors
		if(bOutlineSelfActor)
			OutlinedActors.Add(Owner);

		OutlinedActors.Append(ActorsToOutline);

		// Add parent(s) to outlined actors
		switch(OutlineParents)
		{
			case ETargetableOutlineParents::None:
				break;

			case ETargetableOutlineParents::Parent:
			{
				if(Owner.AttachParentActor != nullptr)
					OutlinedActors.Add(Owner.AttachParentActor);
				break;
			}

			case ETargetableOutlineParents::AllParents:
			{
				AActor Parent = Owner.AttachParentActor;
				while(Parent != nullptr)
				{
					OutlinedActors.Add(Parent);
					Parent = Parent.AttachParentActor;
				}
				break;
			}
		}

		if(bOutlineAttachedActors)
		{
			TArray<AActor> AttachedActors;
			Owner.GetAttachedActors(AttachedActors, false, true);
			OutlinedActors.Append(AttachedActors);
		}

		// Add child components to outlined components
		if(bOutlineChildComponents)
		{
			TArray<USceneComponent> ChildComponents;
			GetChildrenComponents(true, ChildComponents);
			for(auto ChildComp : ChildComponents)
			{
				UPrimitiveComponent PrimitiveComp = Cast<UPrimitiveComponent>(ChildComp);
				if(PrimitiveComp == nullptr)
					continue;

				AddComponentToOutlined(PrimitiveComp);
			}
		}

		// Add parent component to outlined components
		if(bOutlineParentComponent && AttachParent != nullptr)
		{
			UPrimitiveComponent PrimitiveComp = Cast<UPrimitiveComponent>(AttachParent);

			if(PrimitiveComp != nullptr)
				AddComponentToOutlined(PrimitiveComp);
		}

		// Add component references to outlined components added in Defaults
		for(FComponentReference ComponentRef : ComponentsToOutline)
		{
			UActorComponent Comp = ComponentRef.GetComponent(Owner);
			if(Comp == nullptr)
				continue;

			UPrimitiveComponent PrimitiveComp = Cast<UPrimitiveComponent>(Comp);
			if(PrimitiveComp == nullptr)
				continue;

			AddComponentToOutlined(PrimitiveComp);
		}

		// Add component references to outlined components added on instance
		for(FComponentReference ComponentRef : ComponentsToOutlineInstance)
		{
			UActorComponent Comp = ComponentRef.GetComponent(Owner);
			if(Comp == nullptr)
				continue;

			UPrimitiveComponent PrimitiveComp = Cast<UPrimitiveComponent>(Comp);
			if(PrimitiveComp == nullptr)
				continue;

			AddComponentToOutlined(PrimitiveComp);
		}
	}

	private void Reset()
	{
		bInitialized = false;
		TargetComp = nullptr;
		OutlinedActors.Reset();
		OutlinedComponents.Reset();
		ClearOutline();
	}

	void ForceReinitialize()
	{
		Reset();
		Initialize();
	}

	private void AddComponentToOutlined(UPrimitiveComponent PrimitiveComp)
	{
		FTargetableOutlinePrimitiveArray PrimitiveComponents;
		if(OutlinedComponents.Find(PrimitiveComp.Owner, PrimitiveComponents))
		{
			PrimitiveComponents.Array.Add(PrimitiveComp);
			OutlinedComponents[PrimitiveComp.Owner] = PrimitiveComponents;
		}
		else
		{
			PrimitiveComponents.Array.Add(PrimitiveComp);
			OutlinedComponents.Add(PrimitiveComp.Owner, PrimitiveComponents);
		}
	}

	void ShowOutlines(AHazePlayerCharacter TargetingPlayer, ETargetableOutlineType OutlineType = ETargetableOutlineType::Target)
	{
		if(IsBlocked())
			return;

		// Don't apply if we already have this frame
		if(LastAppliedFrame == Time::FrameNumber)
			return;

		if (!bAllowOutlineWhenNotPossibleTarget && OutlineType == ETargetableOutlineType::Visible)
			return;

		// Make sure that we are initialized
		if(!bInitialized)
			Initialize();

		if (TargetableOutlineData == nullptr)
			return;

		UOutlineDataAsset OutlineData;
		ETargetableOutlineType ResultOutlineType;
		if(!TargetableOutlineData.GetOutline(OutlineType, OutlineData, ResultOutlineType))
			return;

		if(TargetableOutlineData.bAlwaysShowInFullscreen && SceneView::IsFullScreen())
		{
			ApplyOutlineForPlayer(SceneView::FullScreenPlayer, OutlineData, TargetableOutlineData.OverlayMaterial, ResultOutlineType);
		}
		else
		{
			if(ShouldShowOutlineForPlayer(TargetingPlayer))
				ApplyOutlineForPlayer(TargetingPlayer, OutlineData, TargetableOutlineData.OverlayMaterial, ResultOutlineType);
		}
	}

	private bool ShouldShowOutlineForPlayer(AHazePlayerCharacter Player) const
	{
		if(!Player.IsSelectedBy(TargetableOutlineData.Player))
			return false;

		return true;
	}
	
	void SetOverlayMaterialOnActor(AActor Target, AHazePlayerCharacter Player, UMaterialInterface OverlayMaterial, ETargetableOutlineType ResultOutlineType)
	{
		if(Target == nullptr)
			return;
		
		TArray<UPrimitiveComponent> Components;
		Target.GetComponentsByClass(Components);
		SetOverlayMaterialOnComponents(Components, Player, OverlayMaterial, ResultOutlineType);
	}
	void SetOverlayMaterialOnComponents(TArray<UPrimitiveComponent> Components, AHazePlayerCharacter Player, UMaterialInterface OverlayMaterial, ETargetableOutlineType ResultOutlineType)
	{
		for(UPrimitiveComponent Target : Components)
		{
			UStaticMeshComponent MeshComponent = Cast<UStaticMeshComponent>(Target);
			if(MeshComponent == nullptr)
				continue;
			
			if(OverlayMaterial == nullptr) // null means clear
			{
				MeshComponent.SetOverlayMaterial(nullptr);
				continue;
			}
			
			UMaterialInstanceDynamic DynamicMaterial = nullptr;

			// If the overlay material is already a dynamic material instance, use it
			if(DynamicMaterial == nullptr && MeshComponent.OverlayMaterial != nullptr)
				DynamicMaterial = Cast<UMaterialInstanceDynamic>(MeshComponent.OverlayMaterial);
			
			// otherwise create it
			if(DynamicMaterial == nullptr)
				DynamicMaterial = Material::CreateDynamicMaterialInstance(this, OverlayMaterial);
			
			DynamicMaterial.SetScalarParameterValue(n"TargetableOutlineFade", OverlayMaterialFade);
			DynamicMaterial.SetScalarParameterValue(n"TargetableOutlineType", int(ResultOutlineType));
			DynamicMaterial.SetScalarParameterValue(n"TargetableOutlineOpacity", OutlineOpacity);
			MeshComponent.SetOverlayMaterial(DynamicMaterial);
			
		}
	}
	
	void SetOverlayMaterialFadeOnActor(AActor Target, AHazePlayerCharacter Player, UMaterialInterface OverlayMaterial, ETargetableOutlineType ResultOutlineType)
	{
		if(Target == nullptr)
			return;
		
		TArray<UPrimitiveComponent> Components;
		Target.GetComponentsByClass(Components);
		SetOverlayMaterialFadeOnComponents(Components, Player, OverlayMaterial, ResultOutlineType);
	}
	void SetOverlayMaterialFadeOnComponents(TArray<UPrimitiveComponent> Components, AHazePlayerCharacter Player, UMaterialInterface OverlayMaterial, ETargetableOutlineType ResultOutlineType)
	{
		for(UPrimitiveComponent Target : Components)
		{
			UStaticMeshComponent MeshComponent = Cast<UStaticMeshComponent>(Target);
			if(MeshComponent == nullptr)
				continue;
			
			if(MeshComponent.OverlayMaterial == nullptr)
				continue;

			UMaterialInstanceDynamic DynamicMaterial = Cast<UMaterialInstanceDynamic>(MeshComponent.OverlayMaterial);
			
			if(DynamicMaterial == nullptr)
				continue;
			
			DynamicMaterial.SetScalarParameterValue(n"TargetableOutlineFade", OverlayMaterialFade);
			DynamicMaterial.SetScalarParameterValue(n"TargetableOutlineType", int(ResultOutlineType));
			DynamicMaterial.SetScalarParameterValue(n"TargetableOutlineOpacity", OutlineOpacity);
		}
	}

	private void ApplyOutlineForPlayer(AHazePlayerCharacter Player, UOutlineDataAsset OutlineData, UMaterialInterface OverlayMaterial, ETargetableOutlineType ResultOutlineType)
	{
		check(bInitialized);

		// Apply actor outlines
		for(auto Actor : OutlinedActors)
		{
			if(Actor == nullptr)
				continue;
			
			Outline::ApplyOutlineOnActor(Actor, Player, OutlineData, this, Priority);
			SetOverlayMaterialOnActor(Actor, Player, OverlayMaterial, ResultOutlineType);
		}

		// Apply component outlines
		for(auto ActorAndComponents : OutlinedComponents)
		{
			#if EDITOR
			if(OutlinedActors.Contains(ActorAndComponents.Key))
			{
				PrintError(f"Trying to add outline to components attached to actor {ActorAndComponents.Key.GetFullName()}, but that actor is already fully outlined!");
				continue;
			}
			#endif

			if(ActorAndComponents.Key == nullptr)
				continue;

			Outline::ApplyOutlineOnComponents(ActorAndComponents.Value.Array, Player, OutlineData, this, Priority);
			SetOverlayMaterialOnComponents(ActorAndComponents.Value.Array, Player, OverlayMaterial, ResultOutlineType);
		}

		OverlayMaterialFadeTarget = 1;
		// Start ticking to clear the outline next frame if not applied again
		// This enables us to not have to keep clearing old outlined targets
		LastAppliedFrame = Time::FrameNumber;
		SetComponentTickEnabled(true);
	}

	void ClearOutline()
	{
		if(!IsComponentTickEnabled())
			return;
		
		// Clear actor outlines
		for(auto Actor : OutlinedActors)
		{
			Outline::ClearOutlineOnActor(Actor, Game::Mio, this);
			Outline::ClearOutlineOnActor(Actor, Game::Zoe, this);
		}

		// Clear component outlines
		for(auto ActorAndComponents : OutlinedComponents)
		{
			Outline::ClearOutlineOnComponents(ActorAndComponents.Value.Array, Game::Mio, this);
			Outline::ClearOutlineOnComponents(ActorAndComponents.Value.Array, Game::Zoe, this);
		}
		OverlayMaterialFadeTarget = 0;
	}

	const UTargetableOutlineDataAsset GetTargetableOutlineData() const
	{
		return TargetableOutlineData;
	}

	void AddActorToOutline(AActor Actor)
	{
		if(!ActorsToOutline.AddUnique(Actor))
			return;

		if(bInitialized)
			Reset();
	}

	void RemoveActorFromOutline(AActor Actor)
	{
		if(ActorsToOutline.RemoveSingleSwap(Actor) < 0)
			return;

		if(bInitialized)
			Reset();
	}

	void AddComponentToOutline(UPrimitiveComponent Component)
	{
		FComponentReference ComponentRef;
		ComponentRef.OtherActor = Component.Owner;
		ComponentRef.ComponentProperty = Component.Name;

		if(!ComponentsToOutline.AddUnique(ComponentRef))
			return;

		if(bInitialized)
			Reset();
	}

	void RemoveComponentFromOutline(UPrimitiveComponent Component)
	{
		FComponentReference ComponentRef;
		ComponentRef.OtherActor = Component.Owner;
		ComponentRef.ComponentProperty = Component.Name;

		if(ComponentsToOutline.RemoveSingleSwap(ComponentRef) < 0)
			return;

		if(bInitialized)
			Reset();
	}

	UFUNCTION(BlueprintCallable)
	void BlockOutline(FInstigator Instigator)
	{
		if(BlockInstigators.AddUnique(Instigator))
		{
			ClearOutline();
		}
		else
		{
			devError(f"Tried to Block with Instigator {Instigator.ToString()}, but it was already blocking targetable outlines!");
		}
	}

	UFUNCTION(BlueprintCallable)
	void UnblockOutline(FInstigator Instigator)
	{
		int Index = BlockInstigators.RemoveSingleSwap(Instigator);
		devCheck(Index >= 0, f"Tried to Unblock with Instigator {Instigator.ToString()}, but it was not blocking targetable outlines!");
	}

	UFUNCTION(BlueprintPure)
	bool IsBlocked() const
	{
		return BlockInstigators.Num() > 0;
	}
}