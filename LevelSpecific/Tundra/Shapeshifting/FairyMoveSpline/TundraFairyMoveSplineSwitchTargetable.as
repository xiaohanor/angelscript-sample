class UTundraFairyMoveSplineSwitchTargetableComponent : UTargetableComponent
{
	default TargetableCategory = n"MovementJump";

	UPROPERTY()
	float MaxRange = 5000;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyTargetableRange(Query, MaxRange);
		Targetable::ApplyVisibleRange(Query, MaxRange);
		Targetable::RequirePlayerCanReachUnblocked(Query);

		FVector2D ScreenPosition;
		if(!SceneView::ProjectWorldToViewpointRelativePosition(Query.Player, WorldLocation, ScreenPosition) ||
			ScreenPosition.X < 0.0 ||
			ScreenPosition.X > 1.0 ||
			ScreenPosition.Y < 0.0 ||
			ScreenPosition.Y > 1.0)
			return false;

		if(Query.DistanceToTargetable > MaxRange)
			return false;

		auto TargetableActor = Cast<ATundraFairyMoveSplineSwitchTargetableActor>(Owner);
		auto FairyComp = UTundraPlayerFairyComponent::Get(Query.Player);

		if(FairyComp == nullptr)
			return false;

		if(TargetableActor.ParentSpline == FairyComp.CurrentMoveSpline)
			return false;

		if(!TargetableActor.ParentSpline.IsMoveSplineActive())
			return false;

		if(FairyComp.FocusedSwitchMoveSplineTargetable == this)
			Query.Result.Score = MAX_flt;
		else if(FairyComp.FocusedSwitchMoveSplineTargetable != nullptr)
			Query.Result.Score = 0.0;

		return true;
	}
}

UCLASS(Abstract)
class ATundraFairyMoveSplineSwitchTargetableActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UTundraFairyMoveSplineSwitchTargetableComponent Targetable;

	ATundraFairyMoveSpline ParentSpline;
}