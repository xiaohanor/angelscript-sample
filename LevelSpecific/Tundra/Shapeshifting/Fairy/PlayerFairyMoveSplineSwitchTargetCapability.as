class UTundraPlayerFairyMoveSplineSwitchTargetCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraPlayerFairyComponent FairyComp;
	UPlayerTargetablesComponent TargetablesComp;

	const float MaxStickAngle = 30;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraFairyMoveSplineSwitchTargetActivatedParams& Params) const
	{
		if(!FairyComp.bIsOnMoveSpline)
			return false;

		auto Primary = TargetablesComp.GetPrimaryTarget(UTundraFairyMoveSplineSwitchTargetableComponent);

		if((FairyComp.FocusedSwitchMoveSplineTargetable == nullptr && Primary != nullptr) ||
			(FairyComp.FocusedSwitchMoveSplineTargetable != nullptr && Primary == nullptr))
		{
			Params.NewFocused = Primary;
			return true;
		}
		
		TArray<UTargetableComponent> Targetables;
		TargetablesComp.GetVisibleTargetables(UTundraFairyMoveSplineSwitchTargetableComponent, Targetables);

		if(Targetables.Num() < 2)
			return false;

		FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector MoveInput3DDirection = FVector(MoveInput.Y, -MoveInput.X, 0.0).GetSafeNormal2D();
		if(MoveInput.Size() < 0.3)
			return false;

		FVector2D CurrentFocusedScreenPos;
		SceneView::ProjectWorldToViewpointRelativePosition(Player, FairyComp.FocusedSwitchMoveSplineTargetable.WorldLocation, CurrentFocusedScreenPos);
		FVector CurrentFocusedScreenPos3D = FVector(CurrentFocusedScreenPos.X, CurrentFocusedScreenPos.Y, 0.0);

		TArray<FVector2D> ValidTargetablesScreenPos;
		float CurrentClosestDistanceSquared = MAX_flt;
		int CurrentClosestIndex = -1;
		for(int i = 0; i < Targetables.Num(); i++)
		{
			auto Current = Cast<UTundraFairyMoveSplineSwitchTargetableComponent>(Targetables[i]);

			if(Current == nullptr)
				continue;

			if(Current == FairyComp.FocusedSwitchMoveSplineTargetable)
				continue;

			FVector2D ScreenPos;
			SceneView::ProjectWorldToViewpointRelativePosition(Player, Current.WorldLocation, ScreenPos);
			FVector ScreenPos3D = FVector(ScreenPos.X, ScreenPos.Y, 0.0);

			FVector FocusedToCurrent = (ScreenPos3D - CurrentFocusedScreenPos3D).GetSafeNormal2D();
			float Degrees = FocusedToCurrent.GetAngleDegreesTo(MoveInput3DDirection);

			if(Degrees > MaxStickAngle)
				continue;

			float Dist = CurrentFocusedScreenPos.DistSquared(ScreenPos);
			if(Dist < CurrentClosestDistanceSquared)
			{
				CurrentClosestDistanceSquared = Dist;
				CurrentClosestIndex = i;
			}

			ValidTargetablesScreenPos.Add(ScreenPos);
		}

		if(CurrentClosestIndex < 0)
			return false;

		Params.NewFocused = Cast<UTundraFairyMoveSplineSwitchTargetableComponent>(Targetables[CurrentClosestIndex]);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!FairyComp.bIsOnMoveSpline)
			return true;

		FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		if(MoveInput.Size() < 0.3)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraFairyMoveSplineSwitchTargetActivatedParams Params)
	{
		FairyComp.FocusedSwitchMoveSplineTargetable = Params.NewFocused;
	}
}

struct FTundraFairyMoveSplineSwitchTargetActivatedParams
{
	UTundraFairyMoveSplineSwitchTargetableComponent NewFocused;
}