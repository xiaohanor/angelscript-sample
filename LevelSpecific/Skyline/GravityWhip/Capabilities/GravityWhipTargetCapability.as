enum EGravityWhipTargetOcclusion
{
	Unchecked,
	Visible,
	Occluded
}

struct FGravityWhipTargetQuery
{
	UGravityWhipTargetComponent Component = nullptr;
	EGravityWhipTargetOcclusion Occlusion = EGravityWhipTargetOcclusion::Unchecked;
	bool bWithinDistance = false;
	bool bWithinAngularDistance = false;
	bool bIsTargeted = false;
	bool bIsGrabbed = false;
	float Score = 0.0;

	int opCmp(const FGravityWhipTargetQuery& Other) const
	{
		if (Score > Other.Score)
			return -1;
		if (Score < Other.Score)
			return 1;

		return 0;
	}
}

class UGravityWhipTargetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(GravityWhipTags::GravityWhip);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipTarget);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipGameplay);

	default DebugCategory = GravityWhipTags::GravityWhip;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 80;

	UGravityWhipUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UGravityWhipUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		//if (UserComp.HasActiveGrab())
		//	return false;

		if (!AimComp.IsAiming(UserComp))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		//if (UserComp.HasActiveGrab())
		//	return true;

		if (!AimComp.IsAiming(UserComp))
			return true;

		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Clear previous target components from targeting data
		auto& TargetData = UserComp.TargetData;
		TargetData.TargetComponents.Empty();
		
		// Get a list of all available targetables
		TArray<UTargetableComponent> Targetables;
		TargetablesComp.GetRegisteredTargetables(UGravityWhipTargetComponent, Targetables);

		bool bHas2DConstraint = AimComp.HasAiming2DConstraint();
		FVector ConstraintNormal;
		if (bHas2DConstraint)
			ConstraintNormal = AimComp.Get2DConstraintPlaneNormal();

		auto AimingRayFromCamera = UserComp.GetAimingRay(bPlaceOriginAtPlayerDepth = false);
		auto AimingRayFromPlayer = UserComp.GetAimingRay(bPlaceOriginAtPlayerDepth = true);

		TArray<FGravityWhipTargetQuery> Queries;
		for (int i = 0; i < Targetables.Num(); ++i)
		{
			auto Targetable = Cast<UGravityWhipTargetComponent>(Targetables[i]);
			if (Targetable == nullptr || 
				Targetable.IsDisabledForPlayer(Player))
				continue;

			if (MoveComp.GroundContact.Actor != nullptr &&
				MoveComp.GroundContact.Actor == Targetable.Owner)
				continue;

			float Distance = (Targetable.WorldLocation - Player.ActorLocation).Size();
			if (!UserComp.HasActiveGrab())
			{
				if (Distance > Targetable.VisibleDistance)
					continue;
				if (Distance <= 0.001)
					continue;
			}

			FVector TargetLocation = Targetable.WorldLocation;
			if (!Targetable.TargetShape.IsZeroSize())
			{
				TargetLocation = Targetable.TargetShape.GetClosestPointToLine(
					Targetable.WorldTransform * FTransform(Targetable.TargetShapeOffset),
					AimingRayFromCamera.Origin, AimingRayFromCamera.Direction
				);
			}

			FVector TargetDirection = (TargetLocation - AimingRayFromCamera.Origin);
			if (bHas2DConstraint)
				TargetDirection = TargetDirection.ConstrainToPlane(ConstraintNormal);

			// Debug::DrawDebugLine(AimingRay.Origin, TargetLocation, FLinearColor::Red, 10.0, 0, true);

			float AngularBend = Math::RadiansToDegrees(
				AimingRayFromCamera.Direction.AngularDistanceForNormals(TargetDirection.GetSafeNormal())
			);

			if (!UserComp.HasActiveGrab())
			{
				if (AngularBend > Targetable.MaximumAngle)
					continue;
			}

			bool bWithinDistance = (Distance <= Targetable.MaximumDistance);
			bool bWithinAngularDistance = (AngularBend <= Targetable.MaximumAngle);

			float Score = Math::Clamp(1.0 - Distance / Targetable.MaximumDistance, 0.0, 1.0) * GravityWhip::Grab::DistanceWeight;
			Score += Math::Clamp(1.0 - AngularBend / Targetable.MaximumAngle, 0.0, 1.0) * (1.0 - GravityWhip::Grab::DistanceWeight);
			Score *= Targetable.ScoreMultiplier;

			FGravityWhipTargetQuery Query;
			Query.Component = Targetable;
			Query.Occlusion = EGravityWhipTargetOcclusion::Unchecked;
			Query.bWithinDistance = bWithinDistance;
			Query.bWithinAngularDistance = bWithinAngularDistance;
			Query.bIsTargeted = false;
			Query.bIsGrabbed = false;
			for (int j = 0; j < UserComp.Grabs.Num(); ++j)
			{
				if(UserComp.Grabs[j].Actor == Targetable.GetOwner())
				{
					Query.bIsGrabbed = true;
					break;
				}
			}
			Query.Score = Score;
			if (UserComp.HasActiveGrab())
			{
				if(Query.bIsGrabbed)
					Queries.Add(Query);
			}
			else
			{
				Queries.Add(Query);
			}

		}

		// Sort by score
		for (int i = 0; i < Queries.Num(); ++i)
		{
			for (int j = 0; j < i; ++j)
			{
				if (Queries[j] > Queries[i])
					Queries.Swap(i, j);
			}
		}

		// Find primary target by looking for the first primary-considerable
		//  and non-occluded targetable in the sorted array
		int PrimaryIndex = -1;
		
		for (int i = 0; i < Queries.Num(); ++i)
		{
			auto& Query = Queries[i];
			ComputeOcclusion(Query, AimingRayFromPlayer);

			if (!Query.bWithinDistance)
				continue;
			if (!Query.bWithinAngularDistance && ! Query.bIsGrabbed)
				continue;

			if (Query.Occlusion == EGravityWhipTargetOcclusion::Visible
				&& PrimaryIndex == -1)
			{
				auto ResponseComponent = UGravityWhipResponseComponent::Get(Query.Component.Owner);

				if (ResponseComponent == nullptr)
				{
					devCheck(false, f"Target component owner \"{Query.Component.Owner.Name}\" doesn't have a response component.");
					continue;
				}
				
				PrimaryIndex = i;
				TargetData.CategoryName = ResponseComponent.CategoryName;
				TargetData.GrabMode = ResponseComponent.GrabMode;
				TargetData.bAllowMultiGrab = ResponseComponent.bAllowMultiGrab;
			}
		}

		if (PrimaryIndex >= 0 && PrimaryIndex < Queries.Num())
		{
			int MaxGrabs = 1;
			if (TargetData.bAllowMultiGrab && (GravityWhip::Grab::bAlwaysMultiGrab || IsActioning(ActionNames::SecondaryLevelAbility)))
				MaxGrabs = GravityWhip::Grab::MaxNumGrabs;

			auto& PrimaryQuery = Queries[PrimaryIndex];
			PrimaryQuery.bIsTargeted = true;

			// Add primary to targeted components first
			TargetData.TargetComponents.Add(PrimaryQuery.Component);

			// Grab rest of targetables until we've reached limit when multi-grabbing
			//  filtered by category name, grab mode, angle and occlusion
			int NextIndex = PrimaryIndex + 1;
			while (MaxGrabs > 1 && NextIndex < Queries.Num() && TargetData.TargetComponents.Num() < MaxGrabs)
			{
				auto& Query = Queries[NextIndex];
				NextIndex++;

				if (GravityWhip::Grab::bLegacyTargetExclusion)
				{
					if (PrimaryQuery.Component.Owner.Class != Query.Component.Owner.Class)
						continue;
				}
				else
				{
					auto ResponseComponent = UGravityWhipResponseComponent::Get(Query.Component.Owner);

					if (ResponseComponent == nullptr)
					{
						devCheck(false, f"\"{Query.Component.Owner.Name}\" doesn't have a response component, it will not be targeted.");
						continue;
					}

					// Filter category name and grab mode
					if (ResponseComponent.CategoryName != TargetData.CategoryName || 
						ResponseComponent.GrabMode != TargetData.GrabMode ||
						!ResponseComponent.bAllowMultiGrab)
						continue;
				}

				ComputeOcclusion(Query, AimingRayFromPlayer);
				if (Query.Occlusion == EGravityWhipTargetOcclusion::Occluded)
					continue;
				if (!Query.bWithinDistance)
					continue;
				if (!Query.bWithinAngularDistance)
					continue;

				Query.bIsTargeted = true;
				TargetData.TargetComponents.Add(Query.Component);
			}

			// Apply outline to primary targets
			for (int i = 0; i < Queries.Num(); ++i)
			{
				FGravityWhipTargetQuery Query = Queries[i];
				if (Query.Component.bInvisibleTarget)
					continue;

				TArray<UTargetableOutlineComponent> OutlineComponents;
				Query.Component.Owner.GetComponentsByClass(OutlineComponents);

				for (auto OutlineComp : OutlineComponents)
				{
					if (OutlineComp == nullptr)
						continue;

					if (OutlineComp.GetTargetableOutlineData().TargetableCategory != GravityWhip::Grab::TargetableCategory)
						continue;

					if (Query.bIsGrabbed)
					{
						// OutlineComp.ShowOutlines(Player, ETargetableOutlineType::Grabbed);
					}
					else if (Query.bIsTargeted)
					{
						// OutlineComp.ShowOutlines(Player, ETargetableOutlineType::Primary);
					}
					else if (Query.bWithinDistance)
					{
						// OutlineComp.ShowOutlines(Player, ETargetableOutlineType::Target);
					}
					else
					{
						// OutlineComp.ShowOutlines(Player, ETargetableOutlineType::Visible);
					}
				}
			}
		}

		// We had no primary targets, but we can still apply an outline to all visible targets
		for (int i = 0; i < Queries.Num(); ++i)
		{
			UGravityWhipTargetComponent Targetable = Queries[i].Component;
			if (Targetable.bInvisibleTarget)
				continue;
			if (Queries[i].Occlusion == EGravityWhipTargetOcclusion::Occluded)
				continue;

			// UTargetableOutlineComponent OutlineComp = UTargetableOutlineComponent::Get(Targetable.Owner);
			// if(OutlineComp != nullptr)
			// 	OutlineComp.ShowOutlines(Player, ETargetableOutlineType::Visible);

			UWidgetPoolComponent Pool = UWidgetPoolComponent::GetOrCreate(Player);

			if (!UserComp.HasActiveGrab() /*&& !Queries[i].bIsTargeted*/)
			{
				auto TargetWidget = Cast<UGravityWhipGrabbableTargetWidget>(
					Pool.TakeSingleFrameWidget(UserComp.GrabbableTargetWidget, Targetable)
				);
				TargetWidget.AttachWidgetToComponent(Targetable);
			}
		}
	}

	void ComputeOcclusion(FGravityWhipTargetQuery& Query, const FAimingRay& AimingRay)
	{
		if (Query.Occlusion != EGravityWhipTargetOcclusion::Unchecked)
			return;

		auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceZoe, n"WhipTargetOcclusion");
		Trace.IgnorePlayers();

		auto HitResult = Trace.QueryTraceSingle(
			AimingRay.Origin,
			Query.Component.WorldLocation,
		);

		if (HitResult.bBlockingHit &&
			HitResult.Component.Owner != Query.Component.Owner)
		{
			Query.Occlusion = EGravityWhipTargetOcclusion::Occluded;
		}
		else
		{
			Query.Occlusion = EGravityWhipTargetOcclusion::Visible;
		}
	}
}

UCLASS(Abstract)
class UGravityWhipGrabbableTargetWidget : UPooledWidget
{
	UPROPERTY(BindWidget)
	UWidget MainContainer;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		MainContainer.SetRenderOpacity(0.0);
	}
	
	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bIsInDelayedRemove)
		{
			MainContainer.SetRenderOpacity(
				Math::FInterpConstantTo(
					MainContainer.RenderOpacity,
					0.0,
					InDeltaTime,
					4.0
				),
			);

			if (MainContainer.RenderOpacity < 0.001)
				FinishRemovingWidget();
		}
		else
		{
			MainContainer.SetRenderOpacity(
				Math::FInterpConstantTo(
					MainContainer.RenderOpacity,
					1.0,
					InDeltaTime,
					4.0
				),
			);
		}
	}
}