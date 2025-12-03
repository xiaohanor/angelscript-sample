UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/SwingIconBillboardGradient.SwingIconBillboardGradient"))
class USlingshotKiteGrapplePointComponent : UGrapplePointBaseComponent
{
	default GrappleType = EGrapplePointVariations::KiteTown_SlingshotPoint;

	default ActivationRange = 1500.0;
	default AdditionalVisibleRange = 1500.0;
	default bTestCollision = true;
	default bVisualizeComponent = true;

	TPerPlayer<bool> bIsPlayerUsingPoint;
	TPerPlayer<float> Cooldown;

	UPROPERTY()
	FOnPlayerAttachedToSwingPointSignature OnPlayerAttachedEvent;
	UPROPERTY()
	FOnPlayerDetachedFromSwingPointSignature OnPlayerDetachedEvent;

	void OnPlayerAttached(AHazePlayerCharacter Player)
	{
		bIsPlayerUsingPoint[Player] = true;
	}

	void OnPlayerDetached(AHazePlayerCharacter Player)
	{
		Cooldown[Player] = ActivationCooldown;
		bIsPlayerUsingPoint[Player] = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (bIsPlayerUsingPoint[Player])
				continue;
			Cooldown[Player] -= DeltaTime;
		}
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(Query.Player.IsCapabilityTagBlocked(PlayerSwingTags::SwingPointQuery))
		{
			Query.Result.Score = 0;
			return false;
		}

		if (!VerifyBaseTargetableConditions(Query))
			return false;

		// Remove the one you are already on
		if (bIsPlayerUsingPoint[Query.Player])
			return false;

		if (Cooldown[Query.Player] > 0.0)
			return false;
		
		Targetable::ScoreLookAtAim(Query, false);
		Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalVisibleRange);
		Targetable::ApplyTargetableRange(Query, ActivationRange);
		Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalVisibleRange, ActivationRange);
		Targetable::RequireCapabilityTagNotBlocked(Query, PlayerMovementTags::Swing);

		if (bTestCollision)
		{
			// Avoid tracing if we are already lower score than the current primary target
			if (!Query.IsCurrentScoreViableForPrimary())
				return false;
			return Targetable::RequireNotOccludedFromCamera(Query, bIgnoreOwnerCollision = bIgnorePointOwner);
		}

		return true;
	}
}

// #if EDITOR
// class UZipKitePointVisualizer : UHazeScriptComponentVisualizer
// {
// 	default VisualizedClass = UZipKitePointComponent;

//     UFUNCTION(BlueprintOverride)
//     void VisualizeComponent(const UActorComponent Component)
//     {
//         UZipKitePointComponent Comp = Cast<UZipKitePointComponent>(Component);
//         if (Comp == nullptr)
//             return;		

// 		if(!Comp.bAlwaysVisualizeRanges)
// 		{
// 			if(Comp.ActivationRange > 0.0)
// 				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange, FLinearColor::Blue, Thickness = 2.0, Segments = 12);	
// 			DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange + Comp.AdditionalVisibleRange, FLinearColor::Purple, 2.0, 12.0);
// 			if(Comp.MinimumRange > 0.0)
// 				DrawWireSphere(Comp.WorldLocation, Comp.MinimumRange, FLinearColor::Red, 2.0, 12.0);
// 		}
//     }
// }
// #endif