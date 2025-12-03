UCLASS(Abstract)
class AIslandRedBlueSwingPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UIslandRedBlueSwingPointComponent SwingPointComp;

	#if EDITOR
	UPROPERTY(DefaultComponent)
	USwingPointDrawComponent DrawComp;	
#endif

	UPROPERTY()
	FOnPlayerAttachedToSwingPointSignature OnPlayerAttachedToSwingPointEvent;

	UPROPERTY()
	FOnPlayerDetachedFromSwingPointSignature OnPlayerDetachedFromSwingPointEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingPointComp.OnPlayerAttachedEvent.AddUFunction(this, n"OnPlayerAttached");
		SwingPointComp.OnPlayerDetachedEvent.AddUFunction(this, n"OnPlayerDetached");
	}

	UFUNCTION(BlueprintEvent, Category = Events)
	void OnPlayerAttached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		OnPlayerAttachedToSwingPointEvent.Broadcast(Player, SwingPoint);
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayerDetached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		OnPlayerDetachedFromSwingPointEvent.Broadcast(Player, SwingPoint);
	}
}

UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/SwingIconBillboardGradient.SwingIconBillboardGradient"))
class UIslandRedBlueSwingPointComponent : USwingPointComponent
{
	default ComponentTags.Add(n"Island");

	bool bTrace;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		bTrace = bTestCollision;
		bTestCollision = false;
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(!Super::CheckTargetable(Query))
			return false;

		if(bTrace)
		{
			if (!Query.IsCurrentScoreViableForPrimary())
				return false;

			return IslandContextualMoves::ForceFieldRequirePlayerCanReachTargetable(Query, bIgnoreOwnerCollision = bIgnorePointOwner);
		}

		return true;
	}

	void UpdateWidget(UTargetableWidget Widget, FTargetableResult QueryResult) const override
	{
		Super::UpdateWidget(Widget, QueryResult);
		
		auto TargetingComp = UIslandPlayerContextualMovesTargetingComponent::Get(Widget.Player);
		auto ContextualWidget = Cast<UContextualMovesWidget>(Widget);
		ContextualWidget.bIsInteractive = !TargetingComp.bPrimaryTargetBlockedByForceField;
	}
}