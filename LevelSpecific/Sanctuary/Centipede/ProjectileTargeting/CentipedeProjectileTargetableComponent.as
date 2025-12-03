class UCentipedeProjectileTargetableComponent : UTargetableComponent
{
	UPROPERTY(EditAnywhere, Category = "Aiming")
	float TargetableRange = 3000.0;

	// How much the player can look away before being auto-aimed
	UPROPERTY(EditAnywhere, Category = "Aiming")
	float MaxPlayerForwardAngleDegrees = 45.0;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyTargetableRange(Query, TargetableRange);
		Targetable::ScoreWantedMovementInput(Query, 200, bAllowWithZeroInput = true);

		if (Query.DistanceToTargetable > TargetableRange)
			return false;

		FVector PlayerToTargetable = (WorldLocation - Query.PlayerLocation).GetSafeNormal();
		float PlayerForwardProjection = PlayerToTargetable.DotProduct(Query.Player.ActorForwardVector);
		float Angle = Math::RadiansToDegrees(Math::Acos(PlayerForwardProjection));

		if (Angle > MaxPlayerForwardAngleDegrees)
			return false;

		return true;
	}
}