class UAdultDragonHomingTailSmashAutoAimComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"Smash";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;
	default AutoAimMaxAngle = 60.0;
	default MaximumDistance = AdultDragonTailSmash::AutoAimMaxDistance;
	default TargetShape.Type = EHazeShapeType::Sphere;
	default TargetShape.SphereRadius = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxRange = 16000;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float AdditionalVisibleRange = 8000;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyTargetableRange(Query, MaxRange);
		Targetable::ApplyVisibleRange(Query, MaxRange + AdditionalVisibleRange);
		return true;
	}
}