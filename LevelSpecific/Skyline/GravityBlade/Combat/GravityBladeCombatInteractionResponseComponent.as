enum EGravityBladeCombatInteractionType
{
	LadderKick,
	LockBreak,
	Uppercut,
	HorizontalLeft,
	HorizontalRight,
	VerticalUp,
	VerticalDown,
	VerticalHigh,
	DiagonalUpRight,
	HorizontalSwing,
	BallBossSwing,

	None,
	MAX UMETA(Hidden)
}

class UGravityBladeCombatInteractionResponseComponent : UGravityBladeCombatResponseComponent
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	EGravityBladeCombatInteractionType InteractionType;

	// When set, will smooth teleport to a set location when hitting this
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bSmoothTeleportOnHit = false;

	// When hitting this, the closest actor from this list will be chosen and smooth teleported to
	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bSmoothTeleportOnHit", EditConditionHides))
	TArray<AActor> PossibleSmoothTeleportLocations;

	// How long the smooth teleport lasts
	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bSmoothTeleportOnHit", EditConditionHides))
	float SmoothTeleportDuration = 0.3;

	void TriggerSmoothTeleport(AHazePlayerCharacter Player, float Time = 0.5)
	{
		AActor Closest = nullptr;
		float ClosestDist = MAX_flt;

		for (AActor Actor : PossibleSmoothTeleportLocations)
		{
			if (!IsValid(Actor))
				continue;

			float Distance = Actor.ActorLocation.Distance(Player.ActorLocation);
			if (Distance < ClosestDist)
			{
				ClosestDist = Distance;
				Closest = Actor;
			}
		}

		FVector TargetLocation = Player.ActorLocation;
		FRotator TargetRotation = Player.ActorRotation;
		if (IsValid(Closest))
		{
			TargetLocation = Closest.ActorLocation;
			TargetRotation = Closest.ActorRotation;

			Player.GetRootOffsetComponent().FreezeRelativeTransformAndLerpBackToParent(n"MoveToSmoothTeleport", Closest.RootComponent, Time);
			Player.SetActorLocationAndRotation(TargetLocation, TargetRotation);
		}
	}
}