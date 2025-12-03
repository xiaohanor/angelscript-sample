class UAdultDragonAcidAutoAimComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"Acid";
	default UsableByPlayers = EHazeSelectPlayer::Mio;
	default AutoAimMaxAngle = 5;
	default MaximumDistance = 40000;
	default TargetShape.Type = EHazeShapeType::Sphere;
	default TargetShape.SphereRadius = 5000;

	UPROPERTY(EditAnywhere)
	bool bWidgetFollowsAutoAimPoint = true;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyTargetableRange(Query, MaximumDistance);		
		Targetable::ApplyVisibleRange(Query, MaximumDistance);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.UseLine();
		Trace.IgnorePlayers();
		Trace.IgnoreCameraHiddenComponents(Query.Player);

		bool bHasHitOwner = false;
		auto AimComp = UPlayerAimingComponent::Get(Query.Player);
		auto Hits = Trace.QueryTraceMulti(Query.PlayerLocation, Query.PlayerLocation + AimComp.GetPlayerAimingRay().Direction * MaximumDistance);
		for (auto Hit : Hits)
		{
			if (Hit.bBlockingHit)
			{
				auto DissolveSphere = Cast<AAcidDissolveSphere>(Hit.Actor);
				if (DissolveSphere != nullptr)
				{
					if (DissolveSphere.ActorToMaskCollision == Owner)
						return false;
				}
				if (Hit.Actor == Owner)
					bHasHitOwner = true;
			}
		}
		
		return bHasHitOwner;
	}

	FVector CalculateWidgetVisualOffset(AHazePlayerCharacter Player, UTargetableWidget Widget) const override
	{
		if (bWidgetFollowsAutoAimPoint)
		{
			auto AimComp = UPlayerAimingComponent::Get(Player);
			if (AimComp != nullptr && AimComp.IsAiming())
			{
				FAimingRay AimingRay = AimComp.GetPlayerAimingRay();
				FVector TargetPoint = GetAutoAimTargetPointForRay(AimingRay);
				return WorldTransform.InverseTransformPosition(TargetPoint);
			}
		}

		return Super::CalculateWidgetVisualOffset(Player, Widget);
	}
}