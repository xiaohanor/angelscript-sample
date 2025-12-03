namespace IceKingBossTargetable
{
	//ugly hack to only show action widget when mio is inside action shape
	void UpdatePossibleTarget(FTargetableQuery& Query, bool bMioInsideActionShape)
	{
		Query.Result.bPossibleTarget = bMioInsideActionShape;
	}
}

UCLASS(NotBlueprintable, NotPlaceable)
class UTundraSnowMonkeyIceKingBossPunchTargetableComponent : UTargetableComponent
{
	default UsableByPlayers = EHazeSelectPlayer::Mio;
	default TargetableCategory = ActionNames::PrimaryLevelAbility;

	UPROPERTY(EditAnywhere)
	float VisibleRange = 1800.0;

	UPROPERTY(EditAnywhere)
	float TargetableRange = 800.0;

	UPROPERTY(EditAnywhere)
	bool bVisualizeRanges = false;

	UPROPERTY(EditAnywhere, meta = (MakeEditWidget))
	FTransform ActionTransform;

	UPROPERTY(EditAnywhere)
	float ActionRadius = 500;

	UPROPERTY(EditAnywhere)
	FHazeShapeSettings ActionShape;
	default ActionShape.BoxExtents = FVector(200, 200, 200);
	default ActionShape.Type = EHazeShapeType::Box;

	UPrimitiveComponent Shape;

	bool bMioInsideActionShape = false;
	TInstigated<bool> MioInstigatedConsideration;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Shape = Shape::CreateTriggerShape(
			Owner, this, ActionShape, ActionTransform, n"TriggerOnlyPlayer", FName(GetName() + "_ActionArea"));

		Shape.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlapActionArea");
		Shape.OnComponentEndOverlap.AddUFunction(this, n"EndOverlapActionArea");
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyVisibleRange(Query, VisibleRange);
		Targetable::ApplyTargetableRange(Query, TargetableRange);
		IceKingBossTargetable::UpdatePossibleTarget(Query, bMioInsideActionShape);

		FVector StartLocation = Query.Player.ActorLocation;
		FVector EndLocation = Query.TargetableLocation;

		if (StartLocation.Equals(EndLocation))
			return false;

		return true;
	}

	UFUNCTION()
	private void EndOverlapActionArea(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
							  UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr || Player.IsZoe())
			return;

		bMioInsideActionShape = false;
	}

	UFUNCTION()
	private void BeginOverlapActionArea(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
								UPrimitiveComponent OtherComp, int OtherBodyIndex,
								bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr || Player.IsZoe())
			return;

		bMioInsideActionShape = true;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if (!bVisualizeRanges)
			return;

		Debug::DrawDebugSphere(WorldLocation, VisibleRange, 12, FLinearColor::Yellow, 5);
		//Debug::DrawDebugSphere(WorldLocation, TargetableRange, 12, FLinearColor::Green, 5);

		Debug::DrawDebugShape(ActionShape.CollisionShape, Owner.ActorTransform.TransformPosition(ActionTransform.Location), Owner.ActorTransform.TransformRotation(ActionTransform.Rotator()), FLinearColor::Purple, 8);
	}
#endif
}

event void FOnPunchInteractionStarted();
event void FOnTeleportZoeNotify();

UCLASS(Abstract)
class ATundraSnowMonkeyIceKingBossPunchInteractionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraSnowMonkeyIceKingBossPunchTargetableComponent Targetable;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase PreviewMesh;
	default PreviewMesh.bIsEditorOnly = true;
	default PreviewMesh.bHiddenInGame = true;

	UPROPERTY()
	FOnPunchInteractionStarted OnPunchInteractionStarted;

	UPROPERTY()
	FOnTeleportZoeNotify OnTeleportZoeNotify;

	UPROPERTY(EditAnywhere)
	ETundraPlayerSnowMonkeyIceKingBossPunchType Type = ETundraPlayerSnowMonkeyIceKingBossPunchType::FirstPunch;

	UFUNCTION()
	void Enable(FInstigator Instigator)
	{
		Targetable.Enable(Instigator);
	}

	UFUNCTION()
	void Disable(FInstigator Instigator)
	{
		Targetable.Disable(Instigator);
	}

	UFUNCTION()
	void ForceEnterBossPunch()
	{
		UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Game::Mio).ForcedBossPunchActor = this;
	}

	UFUNCTION()
	void ResetSnowMonkeyAnimation()
	{
		UTundraPlayerSnowMonkeyComponent::Get(Game::Mio).GetShapeMesh().ResetSubAnimationInstance(EHazeAnimInstEvalType::Feature);
	}
}