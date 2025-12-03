class UDragonSwordCombatTargetComponent : UTargetableComponent
{
	default TargetableCategory = DragonSwordCombat::TargetableCategory;
	default UsableByPlayers = EHazeSelectPlayer::Both;
	default bShowForOtherPlayer = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	FText TargetName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Visible")
	bool bOverrideVisibleRange = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Visible", Meta = (EditCondition = "bOverrideVisibleRange", EditConditionHides))
	float MaxVisibleDistance = DragonSwordCombat::MaxVisibleDistance;

	// Whether the player can suction towards this target component.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Rush")
	bool bCanRushTowards = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Rush", Meta = (EditCondition = "bCanRushTowards", EditConditionHides))
	bool bOverrideRushRange = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Rush", Meta = (EditCondition = "bCanRushTowards && bOverrideRushRange", EditConditionHides))
	float MaxRushDistance = DragonSwordCombat::MaxRushDistance;

	// Allows overriding the minimum distance kept when suctioning towards this target.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Suction")
	bool bOverrideSuctionReachDistance = false;

	// Distance to keep from this target component when suctioning towards it.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Suction", Meta = (EditCondition = "bOverrideSuctionReachDistance", EditConditionHides))
	float SuctionReachDistance = DragonSwordCombat::IdealSuctionDistance;

	private UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(HealthComp != nullptr && HealthComp.IsDead())
			return false;

		float VisibleDistance = bOverrideVisibleRange ? MaxVisibleDistance : DragonSwordCombat::MaxVisibleDistance;

		Targetable::ApplyVisibleRange(Query, VisibleDistance);

		const float RushDistance = bOverrideRushRange ? MaxRushDistance : DragonSwordCombat::MaxRushDistance;
		Targetable::ApplyTargetableRange(Query, RushDistance);

		//const FVector ToTarget = (WorldLocation - Query.Player.ActorCenterLocation);
		const FVector ToTarget = (WorldLocation - Query.Player.ActorCenterLocation).VectorPlaneProject(FVector::UpVector);
		const float DistanceFromPlayerToTarget = WorldLocation.Dist2D(Query.Player.ActorCenterLocation);

		bool bIsInputting = !Query.PlayerMovementInput.IsNearlyZero();

		bool bIsWithinHitDistance = DistanceFromPlayerToTarget < DragonSwordCombat::HitRange;
		if(bIsInputting)
		{
			if(ToTarget.DotProduct(Query.PlayerMovementInput) < 0)
				bIsWithinHitDistance = false;
		}

		float AngularAlpha = 0;
		if(!bIsWithinHitDistance)
		{
			const float Angle = Math::RadiansToDegrees(Query.AimRay.Direction.AngularDistanceForNormals(ToTarget.GetSafeNormal()));

			if (Angle > DragonSwordCombat::MaxRushAngle)
			{
				Query.Result.bPossibleTarget = false;
			}

			AngularAlpha = Math::Saturate(Angle / DragonSwordCombat::MaxRushAngle);
		}

		if(Query.Result.bPossibleTarget)
		{
			if(!Targetable::RequirePlayerCanReachUnblocked(Query, true, false))
			{
				Query.Result.bPossibleTarget = false;
			}
		}

		const float DistanceAlpha = Math::Saturate(DistanceFromPlayerToTarget / DragonSwordCombat::MaxRushDistance);

		Query.Result.Score = (1.0 - DistanceAlpha) * DragonSwordCombat::SuctionDistanceAngleWeight;
		Query.Result.Score += (1.0 - AngularAlpha) * (1.0 - DragonSwordCombat::SuctionDistanceAngleWeight);

		if(DistanceFromPlayerToTarget < DragonSwordCombat::HitRange * 2)
			Query.Result.Score += 1;

		return true;
	}

	void UpdateWidget(UTargetableWidget Widget, FTargetableResult QueryResult) const override
	{
		Super::UpdateWidget(Widget, QueryResult);
		
		UDragonSwordCombatMioTargetableWidget MioTargetWidget = Cast<UDragonSwordCombatMioTargetableWidget>(Widget);
		
		if(MioTargetWidget != nullptr)
		{
			MioTargetWidget.CurrentTargetDisplayName = TargetName.ToString();
		}
	}
}