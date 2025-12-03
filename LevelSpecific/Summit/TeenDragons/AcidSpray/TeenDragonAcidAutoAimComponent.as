class UTeenDragonAcidAutoAimComponent : UAutoAimTargetComponent
{
	default UsableByPlayers = EHazeSelectPlayer::Mio;
	default AutoAimMaxAngle = 20.0;
	default MaximumDistance = 5015;
	default TargetShape.Type = EHazeShapeType::Sphere;
	default TargetShape.SphereRadius = 50.0;
	default bOnlyValidIfAimOriginIsWithinAngle = true;
	default TracePullback = 150.0;

	bool CheckPrimaryOcclusion(FTargetableQuery& Query, FVector TargetLocation) const override
	{
		FVector OcclusionTargetLocation = GetAutoAimTargetPointForRay(Query.AimRay, false);
		Targetable::RequireAimToPointNotOccluded(Query, OcclusionTargetLocation, IgnoredComponents, TracePullback, bIgnoreActorCollisionForAimTrace);
		return true;
	}
}