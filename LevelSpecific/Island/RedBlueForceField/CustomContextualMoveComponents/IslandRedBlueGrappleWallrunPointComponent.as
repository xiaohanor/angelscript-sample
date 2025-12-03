UCLASS(Abstract)
class AIslandRedBlueGrappleWallrunPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UIslandRedBlueGrappleWallrunPointComponent GrappleWallrunPoint;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UGrappleWallRunPointDrawComponent DrawComp;
#endif

	UPROPERTY()
	FOnPlayerInitiatedGrappleToPointEventSignature OnPlayerInitiatedGrappleToPointEvent;
	UPROPERTY()
	FOnPlayerFinishedGrapplingToPointEventSignature OnPlayerFinishedGrapplingToPointEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrappleWallrunPoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		GrappleWallrunPoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerFinishedGrappleToPoint");
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

UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/WallRunPointIconBillboardGradient.WallRunPointIconBillboardGradient", EditorSpriteOffset="X=-65 Y=0 Z=0"))
class UIslandRedBlueGrappleWallrunPointComponent : UGrappleWallrunPointComponent
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

#if EDITOR
class UHazeIslandRedBlueGrappleWallrunDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AIslandRedBlueGrappleWallrunPoint;

	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		//If we are in blueprint editor then exit out
		if (GetCustomizedObject().World == nullptr)
		{
			HideCategory(n"AlignWithWall");
			return;
		}

		Drawer = AddImmediateRow(n"Functions");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//If we are in blueprint editor then exit out
		if (GetCustomizedObject().World == nullptr)
			return;

		if (!Drawer.IsVisible())
			return;
		
		auto Section = Drawer.Begin();

		FHazeImmediateButtonHandle Button = Section.Button("Align With Wall");
		
		// If button was clicked
		if(Button)
		{	
			if(ObjectsBeingCustomized.Num() > 1)
				Section.Text("Multiple Actors Selected.").Color(FLinearColor::Gray).Bold();

			for (UObject Object : ObjectsBeingCustomized)
			{
				//Cast to our actor, fetch component and call
				AActor ActorCheck = Cast<AActor>(Object);

				if(ActorCheck == nullptr)
					continue;

				UGrappleWallrunPointComponent PointComp = UGrappleWallrunPointComponent::Get(ActorCheck);
				
				if(PointComp == nullptr)
					continue;

				PointComp.AlignWithWall();
			}
		}

		Drawer.End();
	}

}
#endif