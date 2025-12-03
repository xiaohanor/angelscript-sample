UCLASS(Abstract)
class AIslandRedBlueGrappleSlidePoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UIslandRedBlueGrappleSlidePointComponent GrappleSlidePoint;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UGrapplePointDrawComponent DrawComp;
#endif

	UPROPERTY()
	FOnPlayerInitiatedGrappleToPointEventSignature OnPlayerInitiatedGrappleToPointEvent;
	UPROPERTY()
	FOnPlayerFinishedGrapplingToPointEventSignature OnPlayerFinishedGrapplingToPointEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrappleSlidePoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		GrappleSlidePoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrappleToPoint");
	}

	UFUNCTION()
	void OnPlayerInitiatedGrappleToPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent TargetedGrapplePoint)
	{
		OnPlayerInitiatedGrappleToPointEvent.Broadcast(Player, TargetedGrapplePoint);
	}

	UFUNCTION()
	void OnPlayerFinishedGrappleToPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent ActivatedGrapplePoint)
	{
		OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, ActivatedGrapplePoint);
	}
}

UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/SlideIconBillboardGradient.SlideIconBillboardGradient", EditorSpriteOffset="X=0 Y=0 Z=75"))
class UIslandRedBlueGrappleSlidePointComponent : UGrappleSlidePointComponent
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