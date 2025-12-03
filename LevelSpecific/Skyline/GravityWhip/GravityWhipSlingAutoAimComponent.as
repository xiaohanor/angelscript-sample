class UGravityWhipSlingAutoAimComponent : UAutoAimTargetComponent
{
	default TargetableCategory = GravityWhip::Grab::SlingTargetableCategory;
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	default MaximumDistance = 4000.0;
	UGravityWhipResponseComponent ResponseComp;

	// The auto aim will only apply if it shared a category with the slingable
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TArray<FName> SlingAutoAimCategories;
	default SlingAutoAimCategories.Add(n"Default");

	UPROPERTY(EditAnywhere)
	bool bWidgetFollowsAutoAimPoint = false;

	// Whether the target should be invisible. The auto-aim will still work, but no target widget will be shown.
	UPROPERTY(EditAnywhere)
	bool bInvisibleTarget = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ResponseComp = UGravityWhipResponseComponent::Get(Owner);
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

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (!bIsAutoAimEnabled)
			return false;

		auto UserComp = UGravityWhipUserComponent::Get(Query.Player);
		if (UserComp != nullptr)
		{
			if (UserComp.HasGrabbedActor(Owner))
				return false;
		}

		bool bAnyMatchingCategories = false;
		for (FName Category : SlingAutoAimCategories)
		{
			if (UserComp.HasGrabbedSlingableWithAutoAimCategory(Category))
			{
				bAnyMatchingCategories = true;
				break;
			}
		}

		if (!bAnyMatchingCategories)
			return false;

		if (bInvisibleTarget)
			Query.Result.bVisible = false;

		if (Query.Is2DTargeting())
		{
			Targetable::ApplyVisibleRange(Query, MaximumDistance);
			Targetable::ApplyTargetableRange(Query, MaximumDistance);
			Targetable::Score2DTargeting(Query);

			if (Query.IsCurrentScoreViableForPrimary())
			{
				return CheckPrimaryOcclusion(Query, Query.Component.WorldLocation);
			}
		}
		else
		{
			return Super::CheckTargetable(Query);
		}

		return true;
	}
}
