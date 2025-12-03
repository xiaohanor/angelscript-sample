class UBattlefieldHoverboardGrindBalancingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"BattlefieldGrinding");

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardComponent HoverboardComp;

	UHazeCrumbSyncedFloatComponent SyncedGrindBalanceValue;

	UBattlefieldHoverboardGrindingSettings Settings;

	FVector PreviousSplineForward;
	FVector PreviousSplineRight;

	float GrindInputVelocity;
	float GrindInputSpeed;

	float CurrentTutorialTime;
	float TutorialDuration = 5.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);

		Settings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);

		SyncedGrindBalanceValue = UHazeCrumbSyncedFloatComponent::GetOrCreate(Player, n"HoverboardSyncedGrindBalanceValue");
		SyncedGrindBalanceValue.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HoverboardComp.IsOn())
			return false;

		if(!GrindComp.bIsOnGrind)
			return false;

		if(!GrindComp.CurrentGrindSplineComp.bEnableBalancingWhileOnGrind)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HoverboardComp.IsOn())
			return true;

		if(!GrindComp.bIsOnGrind)
			return true;

		if(!GrindComp.CurrentGrindSplineComp.bEnableBalancingWhileOnGrind)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (CurrentTutorialTime < TutorialDuration)
		{
			FTutorialPrompt TutorialPrompt;
			TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
			TutorialPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::Keyboard_LeftRight;
			TutorialPrompt.Text = NSLOCTEXT("Battlefield", "HoverboardBalance", "Balance");
			
			Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, Player.RootComponent, FVector(0.0,0.0,230.0), 0.0);
		}

		PreviousSplineForward = GrindComp.CurrentSplinePos.WorldForwardVector;
		PreviousSplineRight = GrindComp.CurrentSplinePos.WorldRightVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.MeshOffsetComponent.FreezeRotationAndLerpBackToParent(this, 0.5);
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CurrentTutorialTime += DeltaTime;


		float GrindBalance = 0;		
		float GrindBalanceVelocity = GrindComp.GrindBalanceVelocity;
		auto SplinePos = GrindComp.CurrentSplinePos;

		if(HasControl())
		{
			GrindBalance = GrindComp.GrindBalance;

			auto MoveInputRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			if(!MoveInputRaw.IsNearlyZero())
			{
				GrindInputVelocity = Settings.InputBalanceAcceleration * Math::Abs(MoveInputRaw.Y);
				if((GrindInputVelocity < 0 && GrindBalanceVelocity > 0)
				|| (GrindInputVelocity > 0 && GrindBalanceVelocity < 0))
					GrindInputVelocity *= 2.0;

				float GrindInputTarget = MoveInputRaw.Y * Settings.InputBalanceMaxSpeed;
				GrindBalanceVelocity = Math::FInterpTo(GrindBalanceVelocity, GrindInputTarget, DeltaTime, GrindInputVelocity); 
			}
			FVector SplineForward = SplinePos.WorldForwardVector;
			FVector FlatSplineForward = SplineForward.ConstrainToPlane(FVector::UpVector);
			FVector FlatPreviousSplineForward = PreviousSplineForward.ConstrainToPlane(FVector::UpVector);
			float TurnedAngleSinceLastFrame = FlatSplineForward.GetAngleDegreesTo(FlatPreviousSplineForward);
			bool bIsTurningRight = SplineForward.DotProduct(-PreviousSplineRight) > 0;
			float TurningBalanceAcceleration = Settings.BalanceAccelerationPerDegreesLeft * TurnedAngleSinceLastFrame;
			if(!bIsTurningRight)
				TurningBalanceAcceleration *= -1;
			GrindBalanceVelocity += TurningBalanceAcceleration;

			GrindBalance += GrindBalanceVelocity * DeltaTime;
			GrindBalance = Math::Clamp(GrindBalance, -1.0, 1.0);

			GrindComp.GrindBalanceVelocity = GrindBalanceVelocity;
			GrindComp.GrindBalance = GrindBalance;

			SyncedGrindBalanceValue.SetValue(GrindBalance);
		}
		else
		{
			GrindComp.GrindBalance = SyncedGrindBalanceValue.GetValue();
		}

		FVector SplineRight = SplinePos.WorldRightVector;
		FVector BalanceRight = SplineRight.RotateAngleAxis(-GrindComp.GrindBalance * Settings.MaxBalanceMeshRotation, SplinePos.WorldForwardVector);
		FQuat MeshRotation = FQuat::MakeFromXY(SplinePos.WorldForwardVector, BalanceRight);
		Player.MeshOffsetComponent.SnapToRotation(this, MeshRotation, EInstigatePriority::High);

		PreviousSplineForward = SplinePos.WorldForwardVector;
		PreviousSplineRight = SplinePos.WorldRightVector;
	}
};