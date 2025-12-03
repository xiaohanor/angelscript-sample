UCLASS(HideCategories = "Rendering Collision Debug Actor Cooking")
class AIslandRedBlueStickyGrenadeKillTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UIslandRedBlueStickyGrenadeKillTriggerComponent Trigger;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;
}

class UIslandRedBlueStickyGrenadeKillTriggerContainerComponent : UActorComponent
{
	TArray<UIslandRedBlueStickyGrenadeKillTriggerComponent> KillTriggers;

	bool CheckHitKillTrigger(AIslandRedBlueStickyGrenade Grenade, FVector LineStart, FVector LineEnd)
	{
		UIslandRedBlueStickyGrenadeKillTriggerComponent HitKillTrigger;
		for(auto Trigger : KillTriggers)
		{
			switch(Trigger.Shape.Type)
			{
				case EHazeShapeType::None:
				{
					return false;
				}
				case EHazeShapeType::Box:
				{
					FVector LocalLineStart = Trigger.WorldTransform.InverseTransformPosition(LineStart);
					FVector LocalLineEnd = Trigger.WorldTransform.InverseTransformPosition(LineEnd);
					FBox Bounds = FBox::BuildAABB(FVector::ZeroVector, Trigger.Shape.BoxExtents);

					if(Math::LineBoxIntersection(Bounds, LocalLineStart, LocalLineEnd, LocalLineEnd - LocalLineStart))
						HitKillTrigger = Trigger;
				
					break;
				}
				case EHazeShapeType::Sphere:
				{
					FVector StartToEnd = LineEnd - LineStart;
					float StartToEndLength = StartToEnd.Size();

					if(Math::LineSphereIntersection(LineStart, StartToEnd / StartToEndLength, StartToEndLength, Trigger.WorldLocation, Trigger.Shape.SphereRadius))
						HitKillTrigger = Trigger;

					break;
				}
				case EHazeShapeType::Capsule:
				{
					devError("Not implemented capsule grenade kill trigger logic!");
					return false;
				}
			}

			if(HitKillTrigger != nullptr)
				break;
		}

		if(HitKillTrigger == nullptr)
			return false;

		HitKillTrigger.TriggerFor(Grenade);
		return true;
	}
}

UCLASS(HideCategories = "Physics Collision Lighting Rendering Navigation Debug Activation Cooking Tags Lod TextureStreaming")
class UIslandRedBlueStickyGrenadeKillTriggerComponent : UHazeEditorRenderedComponent
{
	default SetHiddenInGame(true);
	
	UPROPERTY(EditAnywhere)
	FHazeShapeSettings Shape = FHazeShapeSettings::MakeBox(FVector(100.0, 100.0, 100.0));

	// If true, the grenade will explode, if false, it will despawn and play the fail effect
	UPROPERTY(EditAnywhere)
	bool bGrenadeShouldExplode = false;

	UPROPERTY(EditAnywhere)
	bool bTriggerForRedGrenade = true;

	UPROPERTY(EditAnywhere)
	bool bTriggerForBlueGrenade = true;

	UPROPERTY(EditAnywhere, Category = "Editor Rendering")
	bool bAlwaysShowShapeInEditor = true;

	UPROPERTY(EditAnywhere, Category = "Editor Rendering")
	float EditorLineThickness = 2.0;

	private TPerPlayer<FIslandRedBlueStickyGrenadeBlocker> DisableInstigators;
	private TPerPlayer<AIslandRedBlueStickyGrenade> Grenades;
	private bool bRegistered = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		WorldScale3D = FVector::OneVector;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TryRegister();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		TryUnregister();
	}

	// We trace against this trigger in the grenade move code but we need this also in case the volume moves into the grenade while attached to something. Should probably be done proper with traces though since this can fail with low frame rate or high speeds.
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(IsDisabledForPlayer(Player))
				continue;

			if(Grenades[Player] == nullptr)
			{
				auto GrenadeUserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
				if(GrenadeUserComp == nullptr)
					continue;

				if(GrenadeUserComp.Grenade == nullptr)
					continue;

				Grenades[Player] = GrenadeUserComp.Grenade;
			}

			if(Grenades[Player].IsActorDisabled())
				continue;

			AIslandRedBlueStickyGrenade CurrentGrenade = Grenades[Player];

			if(Overlap::QueryShapeOverlap(CurrentGrenade.Collision.GetCollisionShape(), CurrentGrenade.Collision.WorldTransform, Shape.GetCollisionShape(), WorldTransform))
			{
				if(bGrenadeShouldExplode)
					CurrentGrenade.DetonateGrenade();
				else
					CurrentGrenade.ResetGrenade();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		DisableTrigger(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		EnableTrigger(Owner);
	}

	void DisableTrigger(FInstigator Instigator)
	{
		DisableTriggerForPlayer(Instigator, Game::Mio);
		DisableTriggerForPlayer(Instigator, Game::Zoe);
	}

	void EnableTrigger(FInstigator Instigator)
	{
		EnableTriggerForPlayer(Instigator, Game::Mio);
		EnableTriggerForPlayer(Instigator, Game::Zoe);
	}

	void DisableTriggerForPlayer(FInstigator Instigator, AHazePlayerCharacter Player)
	{
		DisableInstigators[Player].Blockers.AddUnique(Instigator);
		if(IsDisabledForBoth())
			TryUnregister();
	}

	void EnableTriggerForPlayer(FInstigator Instigator, AHazePlayerCharacter Player)
	{
		DisableInstigators[Player].Blockers.RemoveSingleSwap(Instigator);
		if(!IsDisabledForBoth())
			TryRegister();
	}

	bool IsDisabledForPlayer(AHazePlayerCharacter Player) const
	{
		return DisableInstigators[Player].IsActive();
	}

	bool IsDisabledForBoth() const
	{
		return IsDisabledForPlayer(Game::Mio) && IsDisabledForPlayer(Game::Zoe);
	}

	void TriggerFor(AIslandRedBlueStickyGrenade Grenade)
	{
		if(bGrenadeShouldExplode)
			Grenade.DetonateGrenade();
		else
			Grenade.ResetGrenade(true);
	}

	private void TryRegister()
	{
		if(bRegistered)
			return;

		UIslandRedBlueStickyGrenadeKillTriggerContainerComponent::GetOrCreate(Game::Mio).KillTriggers.AddUnique(this);
		bRegistered = true;
	}

	private void TryUnregister()
	{
		if(!bRegistered)
			return;

		UIslandRedBlueStickyGrenadeKillTriggerContainerComponent::GetOrCreate(Game::Mio).KillTriggers.RemoveSingleSwap(this);
		bRegistered = false;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void CalcBounds(FVector& OutOrigin, FVector& OutBoxExtent, float& OutSphereRadius) const
	{
		OutOrigin = WorldLocation;
		OutSphereRadius = Shape.GetEncapsulatingSphereRadius();
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		if(!bAlwaysShowShapeInEditor)
			return;

		SetActorHitProxy();
		DrawWireShapeSettings(Shape, WorldLocation, ComponentQuat, FLinearColor::Green, EditorLineThickness, false);
	}
#endif
}