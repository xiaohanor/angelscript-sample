event void FGravityBladeCombatGrappleSignature();

enum EGravityBladeCombatAimRayType
{
	MovementDirection,
	Camera
}

class UGravityBladeCombatTargetComponent : UTargetableComponent
{
	default TargetableCategory = GravityBladeCombat::TargetableCategory;
	default UsableByPlayers = EHazeSelectPlayer::Mio;
	default bShowForOtherPlayer = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	FText TargetName;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	EGravityBladeCombatAimRayType AimRayType = EGravityBladeCombatAimRayType::MovementDirection;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Visible")
	bool bOverrideVisibleRange = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Visible", Meta = (EditCondition = "bOverrideVisibleRange", EditConditionHides))
	float MaxVisibleDistance = GravityBladeCombat::MaxVisibleDistance;

	// Whether the player can suction towards this target component.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Rush")
	bool bCanRushTowards = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Rush", Meta = (EditCondition = "bCanRushTowards", EditConditionHides))
	bool bOverrideRushRange = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Rush", Meta = (EditCondition = "bCanRushTowards && bOverrideRushRange", EditConditionHides))
	float MaxRushDistance = GravityBladeCombat::MaxRushDistance;

	// Allows overriding the minimum distance kept when suctioning towards this target.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Suction")
	bool bOverrideSuctionReachDistance = false;

	// Distance to keep from this target component when suctioning towards it.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Suction", Meta = (EditCondition = "bOverrideSuctionReachDistance", EditConditionHides))
	float SuctionReachDistance = GravityBladeCombat::SuctionDistance;

	// Distance to keep from this target component when suctioning towards it.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Suction")
	float SuctionMinimumDistance = GravityBladeCombat::SuctionMinimumDistance;

	// Override from how far away Mio is able to hit this target
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Targeting")
	bool bOverrideTargetRange = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Targeting", Meta = (EditCondition = "bOverrideTargetRange", EditConditionHides))
	float TargetRange = GravityBladeCombat::TargetRange;

	// Use an allowed angle, from the ForwardVector, that the targetable is valid
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Targeting")
	bool bOverrideTargetAngle = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Targeting", Meta = (EditCondition = "bOverrideTargetAngle", EditConditionHides))
	float TargetAngle;

	// If set, the target is invisible, and will not show any widget or outline for targeting
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable|Targeting")
	bool bInvisibleTarget = false;

	UPROPERTY()
	FGravityBladeCombatGrappleSignature OnCombatGrappleActivation;

	private TArray<FInstigator> WidgetBlockers;
	private UBasicAIHealthComponent HealthComp;
	private bool bIsEnemy;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		HealthComp = UBasicAIHealthComponent::Get(Owner);
		bIsEnemy = Cast<ABasicAICharacter>(Owner) != nullptr;
	}

	bool IsEnemy() const
	{
		return bIsEnemy;
	}

	UFUNCTION()
	void AddWidgetBlocker(FInstigator Instigator)
	{
		WidgetBlockers.AddUnique(Instigator);
	}

	UFUNCTION()
	void ClearWidgetBlocker(FInstigator Instigator)
	{
		WidgetBlockers.RemoveSingleSwap(Instigator);
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(HealthComp != nullptr && HealthComp.IsDead())
			return false;

		float VisibleDistance = bOverrideVisibleRange ? MaxVisibleDistance : GravityBladeCombat::MaxVisibleDistance;
		if(Query.Player == Game::Zoe)
			VisibleDistance = GravityBladeCombat::MaxVisibleDistanceZoe;

		Targetable::ApplyVisibleRange(Query, VisibleDistance);

		if (bOverrideTargetRange)
			Targetable::ApplyTargetableRange(Query, TargetRange);
		else
			Targetable::ApplyTargetableRange(Query, GravityBladeCombat::TargetRange);

		const FVector ToTarget = (WorldLocation - Query.Player.ActorCenterLocation);
		const float DistanceFromPlayerToTarget = ToTarget.Size();

		bool bIsInputting = !Query.PlayerMovementInput.IsNearlyZero();

		// Zoe also uses this targetable to show widgets, but don't use the input direction here since it would be confusing.
		if(Query.Player == Game::Zoe)
			bIsInputting = false;

		bool bIsWithinHitDistance = DistanceFromPlayerToTarget < GravityBladeCombat::HitRange;
		if(bIsInputting)
		{
			if(ToTarget.DotProduct(Query.PlayerMovementInput) < 0)
				bIsWithinHitDistance = false;
		}
		
		if(bOverrideTargetAngle)
		{
			FVector TargetDirection = (Query.Player.ActorLocation - WorldLocation).GetSafeNormal2D();
			if(Math::RadiansToDegrees(ForwardVector.AngularDistance(TargetDirection)) > TargetAngle)
			{
				Query.Result.bPossibleTarget = false;
				Query.Result.bVisible = false;
			}
		}

		float AngularAlpha = 0;
		if(!bIsWithinHitDistance)
		{
			FVector AimRayDirection;
			if(AimRayType == EGravityBladeCombatAimRayType::Camera)
			{
				AimRayDirection = Query.Player.ViewRotation.ForwardVector;
			}
			else if(AimRayType == EGravityBladeCombatAimRayType::MovementDirection)
			{
				AimRayDirection = Query.AimRay.Direction;
			}
			else
			{
				AimRayDirection = FVector();
				devError("Forgot to add case in targetable for new air ray type.");
			}

			const float Angle = Math::RadiansToDegrees(AimRayDirection.AngularDistanceForNormals(ToTarget.GetSafeNormal()));

			if (Angle > GravityBladeCombat::MaxHitAngle)
			{
				Query.Result.bPossibleTarget = false;
			}

			AngularAlpha = Math::Saturate(Angle / GravityBladeCombat::MaxHitAngle);
		}

		if (bIsEnemy)
		{
			if(Query.Result.bPossibleTarget && Query.Result.bVisible)
			{
				FVector PlayerNavmeshLocation, TargetableNavmeshLocation;

				bool bNavmeshLocationValid = Pathfinding::FindNavmeshLocation(Query.PlayerLocation, 0.0, 500.0, PlayerNavmeshLocation);
				bNavmeshLocationValid = bNavmeshLocationValid && Pathfinding::FindNavmeshLocation(Query.TargetableLocation, 0.0, 500.0, TargetableNavmeshLocation);
				bool bStraightPathExists = bNavmeshLocationValid && Pathfinding::StraightPathExists(PlayerNavmeshLocation, TargetableNavmeshLocation);

				if(!bStraightPathExists && !Targetable::RequirePlayerCanReachUnblocked(
					Query, true, false,
					100.0))
				{
					Query.Result.bPossibleTarget = false;
				}
			}

			Query.Result.bVisible = false;
		}
		else
		{
			Targetable::RequireAimNotOccluded(Query);
		}

		const float DistanceAlpha = Math::Saturate(DistanceFromPlayerToTarget / GravityBladeCombat::MaxRushDistance);

		Query.Result.Score = (1.0 - DistanceAlpha) * GravityBladeCombat::SuctionDistanceAngleWeight;
		Query.Result.Score += (1.0 - AngularAlpha) * (1.0 - GravityBladeCombat::SuctionDistanceAngleWeight);

		if(DistanceFromPlayerToTarget < GravityBladeCombat::HitRange * 2)
			Query.Result.Score += 1;

		if (bInvisibleTarget)
			Query.Result.bVisible = false;

		return true;
	}

	void UpdateWidget(UTargetableWidget Widget, FTargetableResult QueryResult) const override
	{
		Super::UpdateWidget(Widget, QueryResult);
		
		UGravityBladeCombatMioTargetableWidget MioTargetWidget = Cast<UGravityBladeCombatMioTargetableWidget>(Widget);
		
		if(MioTargetWidget != nullptr)
		{
			if(WidgetBlockers.Num() > 0)
				MioTargetWidget.SetRenderOpacity(0.0);
			else
				MioTargetWidget.SetRenderOpacity(1.0);

			MioTargetWidget.CurrentTargetDisplayName = TargetName.ToString();
		}
	}
}