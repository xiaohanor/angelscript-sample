

class UScifiGravityGrenadeTargetableComponent : UTargetableComponent
{
	default TargetableCategory = n"GravityGrenade";
	
	UPROPERTY(EditAnywhere)
	float VisibleRange = 10000;
	UPROPERTY(EditAnywhere)
	float TargetRange = 3000;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyVisibleRange(Query, VisibleRange);
		Targetable::ApplyTargetableRange(Query, TargetRange);

		FVector2D ScreenPosition;
		SceneView::ProjectWorldToViewpointRelativePosition(Query.Player, WorldLocation, ScreenPosition);

		if(ScreenPosition.X > 1.0 || ScreenPosition.X < 0.0)
			return false;

		if(ScreenPosition.Y > 1.0 || ScreenPosition.Y < 0.0)
			return false;

		Targetable::ScoreCameraTargetingInteraction(Query);
		Targetable::ApplyDistanceToScore(Query);
		return true;
	}
}

