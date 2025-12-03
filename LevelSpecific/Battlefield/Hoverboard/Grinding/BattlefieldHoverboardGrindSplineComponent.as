class UBattlefieldHoverboardGrindSplineComponent : USceneComponent
{
	// How far away from the spline that is considered "On it"
	UPROPERTY(EditAnywhere, Category = "Settings")
	float SplineSize = 100.0;

	/* Optional overriding camera settings for when you are on the grind */
	UPROPERTY(EditAnywhere, Category = "Settings")
	UBattlefieldHoverboardCameraControlSettings OverridingCameraSettings;

	/** Grind settings that are applied while you are on the grind */
	UPROPERTY(EditAnywhere, Category = "Settings")
	UBattlefieldHoverboardGrindingSettings GrindSettings;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bForcedDirection = false;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bForcedDirection"))
	bool bForceForward = true;

	/** Please dont change this one at runtime John :) */
	UPROPERTY(EditAnywhere, Category = "Grapple")
	bool bWillEverBeAllowedToGrappleTo = false;

	/* Whether or not it's allowed to grapple to */
	UPROPERTY(EditAnywhere, Category = "Grapple")
	bool bAllowedToGrappleTo = false;

	/** Actors which have the grind component,
	 which should be counted as being on the grind
	 in terms of grapple points being activated and deactivated
	 */
	UPROPERTY(EditAnywhere, Category = "Grapple")
	AActor PairedGrindForGrapplePoint;

	/** If the player should align to the grind */
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bAlignPlayerWithGrind = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bDeactivateTurningTiltWhileGrinding = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bEnableBalancingWhileOnGrind = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bGrindCameraShake = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	EHazeSelectPlayer GrappleUsableByPlayers = EHazeSelectPlayer::Both;

	// UPROPERTY(EditAnywhere, Category = "Settings")
	// float DistanceBeforeWhichCanBeGrounded = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Bounds")
	bool bManuallySetBounds = false;

	// How far away from the spline you can be before it starts to check it
	UPROPERTY(EditAnywhere, Category = "Bounds", Meta = (EditCondition = bManuallySetBounds, EditConditionHides))
	float SplineBoundsDistance = 10000.0;

	/** If you are allowed to jump at all while on the grind */
	UPROPERTY(EditAnywhere, Category = "Jump")
	bool bAllowJumpWhileOnGrind = true;

	/* Whether or not the player is allowed to jump to nearby grinds while on this grind */
	UPROPERTY(EditAnywhere, Category = "Jump", Meta = (EditCondition = bAllowJumpWhileOnGrind, EditConditionHides))
	bool bAllowedToJumpToOtherGrind = true;

	/* Whether or not to activate rubberbanding */
	UPROPERTY(EditInstanceOnly, Category = "Rubberbanding")
	bool bRubberbanding = false;

	/* The actor of the other spline component 
	MAKE SURE IT HAS A SPLINE COMPONENT :) */
	UPROPERTY(EditInstanceOnly, Category = "Rubberbanding", Meta = (EditCondition = bRubberbanding, EditConditionHides))
	AActor LinkedRubberbandSplineActor;

	/* How much speed positive or negative the rubberbanding can have as a maximum.
	Gradual from 0 to this value based on how much difference in the alpha of the grind the players are on. */
	UPROPERTY(EditAnywhere, Category = "Rubberbanding", Meta = (EditCondition = bRubberbanding, EditConditionHides))
	float MaxRubberbandingSpeed = 1500.0;

	/* At which difference in percentage on the grind the rubberbanding has maximum speed.
	Example: 0.4 means that if the difference in alpha between the grinds is 40% of the spline or higher, 
	the rubber banding speed is at the maximum. */
	UPROPERTY(EditAnywhere, Category = "Rubberbanding", Meta = (EditCondition = bRubberbanding, EditConditionHides))
	float DeltaAlphaMaxRubberbandingThreshold = 0.1;

	UPROPERTY(EditAnywhere, Category = "Events")
	FBattlefieldHoverboardGrindEvent OnPlayerStartedGrinding;

	UPROPERTY(EditAnywhere, Category = "Events")
	FBattlefieldHoverboardGrindEvent OnPlayerStoppedGrinding;

	UPROPERTY(EditAnywhere, Category = "Events")
	FBattlefieldHoverboardGrindEvent OnPlayerStartedGrapplingToGrind;

	UPROPERTY(EditAnywhere, Category = "Events")
	FBattlefieldHoverboardGrindEvent OnPlayerFinishedGrapplingToGrind;

	UHazeSplineComponent SplineComp;
	UBattlefieldHoverboardGrindSplineComponent LinkedRubberbandSplineComp;

	private UBattlefieldHoverboardGrindSplineComponent PairedGrindCompForGrapplePoint;
	private TArray<FInstigator> MioIsOnGrindInstigators;
	private TArray<FInstigator> ZoeIsOnGrindInstigators;
	private TPerPlayer<UBattlefieldHoverboardGrindingComponent> GrindComp;
	private TPerPlayer<UBattlefieldHoverboardGrindingSettings> PlayerGrindSettings;
	TPerPlayer<bool> JumpingToGrind;
	TPerPlayer<AGrapplePoint> GrapplePoint;

	bool bHasSpawnedGrapplePoints;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(Owner);

		if(bRubberbanding)
		{
			LinkedRubberbandSplineComp = UBattlefieldHoverboardGrindSplineComponent::Get(LinkedRubberbandSplineActor);
			devCheck(LinkedRubberbandSplineComp != nullptr, f"{Owner.Name}'s Spline actor enabled rubberbanding, but had no valid reference to an actor with a grind spline component");
		}
	#if EDITOR
		CookChecks::EnsureSplineCanBeUsedOutsideEditor(this, SplineComp);
	#endif
		
		if(PairedGrindForGrapplePoint != nullptr)
		{
			auto PairedGrindComp = UBattlefieldHoverboardGrindSplineComponent::Get(PairedGrindForGrapplePoint);
			if(PairedGrindComp != nullptr)
				PairedGrindCompForGrapplePoint = PairedGrindComp;
		}

		if(!bManuallySetBounds)
			UpdateSplineBounds();
		
		
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(PairedGrindForGrapplePoint != nullptr)
		{
			auto PairedGrindComp = UBattlefieldHoverboardGrindSplineComponent::Get(PairedGrindForGrapplePoint);
			if(PairedGrindComp != nullptr)
				PairedGrindComp.PairedGrindForGrapplePoint = Owner;
		}

		if(LinkedRubberbandSplineActor != nullptr)
		{
			auto LinkedGrindComp = UBattlefieldHoverboardGrindSplineComponent::Get(LinkedRubberbandSplineActor);
			if(LinkedGrindComp != nullptr)
				LinkedGrindComp.LinkedRubberbandSplineActor = Owner;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			if(bWillEverBeAllowedToGrappleTo
			&& BattlefieldHoverboardSettings::bGrappleToGrindEnabled
			&& !bHasSpawnedGrapplePoints)
				CrumbSpawnGrapplePoints();
		}


		// Could make update less often if performance is needed
		for(auto Player : Game::GetPlayersSelectedBy(GrappleUsableByPlayers))
		{
			auto GrindingComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
			float DistSqrd = WorldLocation.DistSquared(Player.ActorLocation);
			if(DistSqrd <= Math::Square(SplineBoundsDistance))
			{
				GrindingComp.AddGrindIfDontHave(this);
				if(bAllowedToGrappleTo && BattlefieldHoverboardSettings::bGrappleToGrindEnabled)
					UpdateGrapplePoint(Player);
			}
			else
			{
				GrindingComp.RemoveGrindIfHave(this);
			}
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbSpawnGrapplePoints()
	{
		bHasSpawnedGrapplePoints = true;
		for(auto Player : Game::GetPlayersSelectedBy(GrappleUsableByPlayers))
		{
			GrindComp[Player] = UBattlefieldHoverboardGrindingComponent::Get(Player);
			PlayerGrindSettings[Player] = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
			if(PlayerGrindSettings[Player].GrapplePointClass == nullptr)
				return;

			auto NewGrapplePoint = SpawnActor(PlayerGrindSettings[Player].GrapplePointClass, bDeferredSpawn = true);
			NewGrapplePoint.MakeNetworked(this, Player);
			EHazeSelectPlayer SelectPlayer = EHazeSelectPlayer::Zoe;
			if (Player.IsMio())
				SelectPlayer = EHazeSelectPlayer::Mio;
			NewGrapplePoint.GrapplePoint.SetUsableByPlayers(SelectPlayer);
			FinishSpawningActor(NewGrapplePoint);
			NewGrapplePoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"PlayerStartedGrapplingToGrind");
			NewGrapplePoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"PlayerFinishedGrapplingToGrind");

			if(GrindSettings != nullptr)
			{
				NewGrapplePoint.GrapplePoint.ActivationRange = GrindSettings.GrappleActivationRange;
				NewGrapplePoint.GrapplePoint.AdditionalVisibleRange = GrindSettings.GrappleAdditionalVisibleRange;
			}
			GrapplePoint[Player] = NewGrapplePoint;
		}
	}

	private void UpdateGrapplePoint(AHazePlayerCharacter Player)
	{
		if (GrapplePoint[Player] == nullptr)
			return;

		float DistanceAlong = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		DistanceAlong += 2500.0;
		FSplinePosition ClosestSplinePosToOffset = SplineComp.GetSplinePositionAtSplineDistance(DistanceAlong);
		
		if(!GrapplePoint[Player].IsActorDisabled())
		{
			if(ShouldDisableGrapple(Player, ClosestSplinePosToOffset))
				GrapplePoint[Player].AddActorDisable(this);
		}
		else
		{
			if(!ShouldDisableGrapple(Player, ClosestSplinePosToOffset))
				GrapplePoint[Player].RemoveActorDisable(this);
		}

		// We want it to stay when grappling to it
		if(!PlayerIsGrapplingToGrind(Player))
			GrapplePoint[Player].ActorLocation = ClosestSplinePosToOffset.WorldLocation;
	}

	/* Tries to place the component in the middle of the spline.
	Also tries to make the extent encompass the entire spline with some extra room for grappling */
	private void UpdateSplineBounds()
	{
		FVector BoundsCenter;
		FVector BoundsExtent;
		Owner.GetActorBounds(false, BoundsCenter, BoundsExtent, true);
		SetWorldLocation(BoundsCenter);

		SplineBoundsDistance = BoundsExtent.Size() + 5000;
	}

	private bool ShouldDisableGrapple(AHazePlayerCharacter Player, FSplinePosition SplinePos) const
	{
		bool bSplinePosIsBackwards = SplinePos.WorldForwardVector.DotProduct(Player.ActorForwardVector) < 0;
		bool bAtEnd;
		if(bSplinePosIsBackwards)
			bAtEnd = SplinePos.CurrentSplineDistance == 0;
		else
			bAtEnd = SplinePos.CurrentSplineDistance == SplineComp.SplineLength;

		if(bAtEnd)
			return true;
		else if(PlayerIsOnGrind(Player))
			return true;
		else if(PlayerIsJumpingToGrind(Player))
			return true;
		else if(PairedGrindCompForGrapplePoint != nullptr)
		{
			if(PairedGrindCompForGrapplePoint.PlayerIsOnGrind(Player))
				return true;
			else if(PairedGrindCompForGrapplePoint.PlayerIsGrapplingToGrind(Player))
				return true;
			else if(PairedGrindCompForGrapplePoint.PlayerIsJumpingToGrind(Player))
				return true;
		}
		
		return false;
	}

	bool PlayerIsOnGrind(AHazePlayerCharacter Player) const
	{
		if(Player.IsMio())
		{
			if(MioIsOnGrindInstigators.Num() > 0)
				return true;
			else
				return false;
		}
		else
		{
			if(ZoeIsOnGrindInstigators.Num() > 0)
				return true;
			else
				return false;
		}
	}

	bool PlayerIsJumpingToGrind(AHazePlayerCharacter Player) const
	{
		return JumpingToGrind[Player];
	}

	bool PlayerIsGrapplingToGrind(AHazePlayerCharacter Player) const
	{
		if(GrapplePoint[Player] == nullptr)
			return false;
		return GrapplePoint[Player].GrapplePoint.bIsPlayerGrapplingToPoint[Player];
	}

	void AddOnGrindInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if(Player.IsMio())
			MioIsOnGrindInstigators.AddUnique(Instigator);
		else
			ZoeIsOnGrindInstigators.AddUnique(Instigator);
	}

	void RemoveOnGrindInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if(Player.IsMio())
			MioIsOnGrindInstigators.RemoveSingleSwap(Instigator);
		else
			ZoeIsOnGrindInstigators.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerStartedGrapplingToGrind(AHazePlayerCharacter Player, UGrapplePointBaseComponent TargetedGrapplePoint)
	{
		OnPlayerStartedGrapplingToGrind.Broadcast(this, Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerFinishedGrapplingToGrind(AHazePlayerCharacter Player, UGrapplePointBaseComponent TargetedGrapplePoint)
	{
		OnPlayerFinishedGrapplingToGrind.Broadcast(this, Player);
	}
};
#if EDITOR
class UBattlefieldHoverboardGrindSplineComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UBattlefieldHoverboardGrindSplineComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UBattlefieldHoverboardGrindSplineComponent Comp = Cast<UBattlefieldHoverboardGrindSplineComponent>(Component);

		if(!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
			 return;

		if(Comp.bManuallySetBounds)
		{
			SetRenderForeground(false);
			DrawWireCylinder(Comp.WorldLocation, FRotator::ZeroRotator, FLinearColor::Green, Comp.SplineBoundsDistance, 80, 50, 20, false);
		}

		// auto SplineComp = UHazeSplineComponent::Get(Comp.Owner);
		// auto SplinePos = SplineComp.GetSplinePositionAtSplineDistance(Comp.DistanceBeforeWhichCanBeGrounded);
		// DrawWireSphere(SplinePos.WorldLocation, 100, FLinearColor::Purple, 10, 12);
		// DrawWorldString("Grounded Threshold", SplinePos.WorldLocation + FVector::UpVector * 100, FLinearColor::Purple, 1);
	}
}
#endif