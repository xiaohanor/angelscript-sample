class UDesertBreakPerchPointComponent : UPerchPointComponent
{
	UPROPERTY(EditInstanceOnly)
	ADesertBreakPerchPoint StraightJumpNextPerchPoint;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (!VerifyBaseTargetableConditions(Query))
			return false;

		if(!VerifyAirActivationSettings(Query))
			return false;

		if(!VerifyHeightActivationConditions(Query))
			return false;

		// Exclude if grappling towards
		if (bIsPlayerGrapplingToPoint[Query.Player])
			return false;

		if (IsPlayerJumpingToPoint[Query.Player] || IsPlayerLandingOnPoint[Query.Player])
			return false;

		if (CooldownOverAtGameTime[Query.Player] > Time::GameTimeSeconds)
			return false;
		
		//Exclude if already perching on
		if (IsPlayerOnPerchPoint[Query.Player])
			return false;

		const bool bUseAutoJumpTargeting = (Query.QueryCategory == n"Jump");
		if (bUseAutoJumpTargeting)
		{
			if (!bAllowAutoJumpTo)
				return false;

			Targetable::ApplyTargetableRange(Query, ActivationRange);
			Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalVisibleRange);
			Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalVisibleRange, ActivationRange);

			/**
			 * Changes for DesertBreak
			 */
			bool bFoundAutoJumpTarget = false;
			if(Query.PlayerMovementInput.IsNearlyZero())
			{
				auto PerchComp = UPlayerPerchComponent::Get(Query.Player);
				if(PerchComp != nullptr && PerchComp.IsCurrentlyPerching())
				{
					auto OtherPerchPoint = Cast<UDesertBreakPerchPointComponent>(PerchComp.Data.ActivePerchPoint);
					if(OtherPerchPoint != nullptr && OtherPerchPoint.StraightJumpNextPerchPoint != nullptr)
					{
						if(OtherPerchPoint.StraightJumpNextPerchPoint.PerchPointComp == this)
						{
							Query.Result.Score = 1000;
							bFoundAutoJumpTarget = true;
						}
					}
				}
			}
			/**
			 * End changes
			 */

			if(!bFoundAutoJumpTarget)
				Targetable::ScoreWantedMovementInput(Query, MaximumHorizontalJumpToAngle, MaximumVerticalJumpToAngle, bUseNonLockedMovementInput = true);
		}
		else
		{
			if (!bAllowGrappleToPoint)
				return false;

			Targetable::ApplyTargetableRange(Query, ActivationRange + AdditionalGrappleRange);
			Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalGrappleRange + AdditionalVisibleRange);
			Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalGrappleRange + AdditionalVisibleRange, ActivationRange + AdditionalGrappleRange);

			Targetable::ScoreLookAtAim(Query);
		}

		if (bTestCollision)
			return Targetable::RequirePlayerCanReachUnblocked(Query, bIgnorePointOwner);

		return true;
	}
};

UCLASS(NotBlueprintable, NotPlaceable)
class UDesertBreakPerchPointComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDesertBreakPerchPointComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto PerchPoint = Cast<UDesertBreakPerchPointComponent>(Component);
		if(PerchPoint == nullptr)
			return;

		if(PerchPoint.StraightJumpNextPerchPoint != nullptr)
		{
			DrawArrow(PerchPoint.WorldLocation, PerchPoint.StraightJumpNextPerchPoint.PerchPointComp.WorldLocation, FLinearColor::Green, 10, 3);
		}
	}
}