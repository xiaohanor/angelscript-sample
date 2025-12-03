

class UPlayerPoleClimbComponent : UActorComponent
{
	UPROPERTY(Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset PoleClimbDashSettings;

	UPROPERTY(Category = "Dash")
	UForceFeedbackEffect DashFF;

	UPROPERTY()
	UForceFeedbackEffect PerchFF;

	UPROPERTY()
	UForceFeedbackEffect TurnAroundFF;

	UPROPERTY()
	UForceFeedbackEffect TurnAroundFFLeft;

	UPROPERTY()
	UForceFeedbackEffect TurnAroundFFRight;

	UPROPERTY()
	UForceFeedbackEffect TurnAroundEnterFFLeft;

	UPROPERTY()
	UForceFeedbackEffect TurnAroundEnterFFRight;

	UPROPERTY()
	UForceFeedbackEffect DefaultEnterFF;
	UPROPERTY()
	UForceFeedbackEffect JumpOutFF;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UPlayerAirJumpComponent AirJumpComp;
	UPlayerAirDashComponent AirDashComp;

	UPlayerPoleClimbSettings Settings;
	FPlayerPoleClimbData Data;
	UPROPERTY(BlueprintReadOnly)
	FPlayerPoleClimbAnimData AnimData;

	bool bIgnoringPole;

	float LingerCameraSettingsTimeRemaining = -1.0;
	
	//Poles eligible for proximity enter
	TArray<APoleClimbActor> OverlappingPoles;
	//Poles eligible for aim assist jump to
	TArray<APoleClimbActor> NearbyPoles;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
		Settings = UPlayerPoleClimbSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	void Initialize()
	{
		AirJumpComp = UPlayerAirJumpComponent::Get(Player);
		AirDashComp = UPlayerAirDashComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Data.CurrCooldown < Settings.PoleCooldown)
			Data.CurrCooldown += DeltaSeconds;

		if(Data.State == EPlayerPoleClimbState::Inactive)
			Data.IgnorePoleTimer += DeltaSeconds;

		if (Data.IgnorePoleTimer > Data.IgnorePoleTime && bIgnoringPole)
		{
			bIgnoringPole = false;
			MoveComp.RemoveMovementIgnoresActor(this);
		}

		// If any camera settings are being lingered, remove them when the timer is up
		if (LingerCameraSettingsTimeRemaining > 0.0)
		{
			LingerCameraSettingsTimeRemaining -= DeltaSeconds;
			if (LingerCameraSettingsTimeRemaining <= 0.0)
			{
				Player.ClearCameraSettingsByInstigator(this, 1.5);
			}
		}
		
		// Update air jump auto targeting for all nearby poles
		for (APoleClimbActor NearbyPole : NearbyPoles)
		{
			if (!NearbyPole.bEnablePoleAirMoveAssist)
				continue;

			FVector PoleLocation = NearbyPole.ActorLocation;
			FVector ClosestPoint = Math::ClosestPointOnLine(
				PoleLocation, PoleLocation + (NearbyPole.ActorUpVector * NearbyPole.Height),
				Player.ActorLocation
			);

			FVector LocalOffset = NearbyPole.ActorTransform.InverseTransformPosition(ClosestPoint);

			if(AirJumpComp != nullptr)
			{
				FAirJumpAutoTarget AutoTarget;
				AutoTarget.Component = NearbyPole.RootComponent;
				AutoTarget.LocalOffset = LocalOffset;
				AutoTarget.bCheckHeightDifference = true;
				AutoTarget.MinHeightDifference = -50.0;
				AutoTarget.MaxHeightDifference = 50.0;
				AutoTarget.bCheckFlatDistance = true;
				AutoTarget.MaxFlatDistance = NearbyPole.MaxAirMoveAssistDistance;
				AutoTarget.bCheckInputAngle = true;
				AutoTarget.MaxInputAngle = NearbyPole.MaxAirMoveAssistAngle;

				AirJumpComp.AddAutoTarget(AutoTarget);
			}

			if (AirDashComp != nullptr)
			{
				FAirDashAutoTarget AutoTarget;
				AutoTarget.Component = NearbyPole.RootComponent;
				AutoTarget.LocalOffset = LocalOffset;
				AutoTarget.bCheckHeightDifference = true;
				AutoTarget.MinHeightDifference = -50.0;
				AutoTarget.MaxHeightDifference = 50.0;
				AutoTarget.bCheckFlatDistance = true;
				AutoTarget.MaxFlatDistance = NearbyPole.MaxAirMoveAssistDistance;
				AutoTarget.bCheckInputAngle = true;
				AutoTarget.MaxInputAngle = NearbyPole.MaxAirMoveAssistAngle;

				AirDashComp.AddAutoTarget(AutoTarget);
			}
		}
	}

	void AddNearbyPole(APoleClimbActor Pole)
	{
		NearbyPoles.Add(Pole);
	}

	void RemoveNearbyPole(APoleClimbActor Pole)
	{
		NearbyPoles.Remove(Pole);
		AirJumpComp.RemoveAutoTarget(Pole.RootComp);
		AirDashComp.RemoveAutoTarget(Pole.RootComp);
	}

	//Will assign an active Pole, attach the player and perform Data calculations for Poleclimb capabilities
	void StartClimbing(FPoleClimbEnterTestData TestData)
	{
		Data.ActivePole = TestData.PoleActor;
		Data.ClimbDirectionSign = TestData.ClimbDirectionSign;
		Data.CurrentHeight = TestData.CurrentHeight;
		Data.MaxHeight = TestData.MaxHeight;
		Data.MinHeight = TestData.MinHeight;

		AnimData.bClimbing = true;

		//TODO [AL] - This should either be constructed in a better flow or potentially have this / the ignore timer be handled on a frame by frame basis by t.ex jumpout capability
		//Clear previous poles incase we reentered during cooldown
		MoveComp.RemoveMovementIgnoresActor(this);
		
		MoveComp.AddMovementIgnoresActor(this, Data.ActivePole);
		Data.IgnorePoleTimer = 0.0;
		bIgnoringPole = true;
		Player.ApplyCameraSettings(Data.ActivePole.CameraSetting, 2, this, EHazeCameraPriority::Low);
		LingerCameraSettingsTimeRemaining = -1.0;

		Data.ActivePole.OnStartPoleClimb.Broadcast(Player, Data.ActivePole);
	}

	//Will detach player and reset all Data/AnimData / Applied Settings
	void StopClimbing()
	{
		if(Data.ActivePole == nullptr)
			return;

		if(Data.ActivePole != nullptr)
			Data.ActivePole.OnStopPoleClimb.Broadcast(Player, Data.ActivePole);

		if(Data.ActivePole.bCamSettingsShouldLinger)
			LingerCameraSettingsTimeRemaining = 1.0;
		else
			Player.ClearCameraSettingsByInstigator(this, 1.5);

		Data.ResetData();
		AnimData.ResetData();
		ResetCooldown();
	}

	void ResetCooldown()
	{
		Data.CurrCooldown = 0.0;
	}

	bool OnCooldown()
	{
		if (Data.CurrCooldown < Settings.PoleCooldown)
			return true;

		return false;
	}

	//Check to see that we are at a valid climb height (incase the pole was modified)
	bool IsWithinValidClimbHeight() const
	{
		float ConstrainedHeightDelta = (Player.ActorLocation - Data.ActivePole.ActorLocation).ConstrainToDirection(Data.ActivePole.ActorUpVector).Size();

		if(Data.ClimbDirectionSign == 1)
		{
			//Check if we are within the height of the pole - our capsule height and a slight margin
			if(ConstrainedHeightDelta >= ((Data.ActivePole.Height - (Player.ScaledCapsuleHalfHeight * 2)) + 5))
				return false;
		}
		else
		{
			if(ConstrainedHeightDelta >= (Data.ActivePole.Height - Settings.PoleMinHeightOffset) + 5)
				return false;
		}

		return true;
	}

	/*
	 * Returns Normalized direction vector from Currently Active or Piped in Pole Actor towards Player, constrained to Poles UpVector.
	 * Will return ZeroVector if pole is invalid
	 */
	FVector GetPoleToPlayerVector() const
	{
		return GetPoleToPlayerVector(Data.ActivePole);
	}

	FVector GetPoleToPlayerVector(APoleClimbActor PoleActor) const
	{
		if(PoleActor == nullptr)
			return FVector::ZeroVector;

		FVector PoleToPlayer = Player.ActorLocation - PoleActor.ActorLocation;
		PoleToPlayer = PoleToPlayer.ConstrainToPlane(PoleActor.ActorUpVector);
		PoleToPlayer = PoleToPlayer.GetSafeNormal();

		return PoleToPlayer;
	}

	FVector GetClosestPoleAllowedDirection(FVector PlayerDirection) const
	{
		TArray<FVector> AllowedDirections = Data.ActivePole.GetAllowedPlayerDirections();

		FVector BestDirection;
		float BestDirectionAngle = MAX_flt;

		for (FVector AllowedDir : AllowedDirections)
		{
			float Angle = AllowedDir.GetAngleDegreesTo(PlayerDirection);
			if (Angle < BestDirectionAngle)
			{
				BestDirection = AllowedDir;
				BestDirectionAngle = Angle;
			}
		}

		return BestDirection;
	}

	FVector GetNextPoleAllowedDirection(FVector PlayerDirection, FVector MovementInput) const
	{
		FVector PoleToPlayer = GetPoleToPlayerVector();
		TArray<FVector> AllowedDirections = Data.ActivePole.GetAllowedPlayerDirections();

		if(Data.ActivePole.bClimbInFourCardinalAngles)
		{
			return GetClosestPoleAllowedDirection(MovementInput);
		}

		int BestDirection = -1;
		float BestDirectionAngle = MAX_flt;

		for (int i = 0, Count = AllowedDirections.Num(); i < Count; ++i)
		{
			FVector AllowedDir = AllowedDirections[i];
			float Angle = AllowedDir.GetAngleDegreesTo(PoleToPlayer);
			if (Angle < BestDirectionAngle)
			{
				BestDirection = i;
				BestDirectionAngle = Angle;
			}
		}

		return AllowedDirections[(BestDirection + 1) % AllowedDirections.Num()];
	}

	/*
	 * Returns Normalized direction vector from player to currently active or piped in Pole actor, constrained to poles UpVector.
	 * Will return ZeroVector pole is invalid.
	 */
	FVector GetPlayerToPoleVector()
	{
		if(Data.ActivePole == nullptr)
			return FVector::ZeroVector;

		FVector PlayerToPole = Data.ActivePole.ActorLocation - Player.ActorLocation;
		PlayerToPole = PlayerToPole.ConstrainToPlane(Data.ActivePole.ActorUpVector);
		PlayerToPole = PlayerToPole.GetSafeNormal();

		return PlayerToPole;
	}

	FVector GetPlayerToPoleVector(APoleClimbActor PoleActor)
	{
		if(PoleActor == nullptr)
			return FVector::ZeroVector;

		FVector PlayerToPole = PoleActor.ActorLocation - Player.ActorLocation;
		PlayerToPole = PlayerToPole.ConstrainToPlane(PoleActor.ActorUpVector);
		PlayerToPole = PlayerToPole.GetSafeNormal();

		return PlayerToPole;
	}

	UFUNCTION()
	void ForceEnterPole(APoleClimbActor PoleToEnter, ASplineActor Spline = nullptr, bool bSnapCamera = true)
	{
		FPoleClimbEnterTestData EnterTestData;
		EnterTestData.PoleActor = PoleToEnter;
		
		EnterTestData.ClimbDirectionSign = int(Math::Sign(PoleToEnter.ActorUpVector.DotProduct(Player.ActorUpVector)));
		EnterTestData.MinHeight = EnterTestData.ClimbDirectionSign == 1 ? Settings.PoleMinHeightOffset : CalculatePlayerHeightOffset();
		EnterTestData.MaxHeight = EnterTestData.ClimbDirectionSign == 1 ? PoleToEnter.Height - CalculatePlayerHeightOffset() : PoleToEnter.Height - Settings.PoleMinHeightOffset;

		FVector PoleToPlayer = Player.ActorLocation - PoleToEnter.ActorLocation;
		float PoleToPlayerDot = PoleToEnter.ActorUpVector.DotProduct(PoleToPlayer);
		int VerticalDeltaSign = int(Math::Sign(PoleToPlayerDot));
		EnterTestData.CurrentHeight  = PoleToPlayer.ConstrainToDirection(PoleToEnter.ActorUpVector).Size() * VerticalDeltaSign;
		
		EnterTestData.CurrentHeight = Math::Clamp(EnterTestData.CurrentHeight, EnterTestData.MinHeight, EnterTestData.MaxHeight);
		EnterTestData.bValidHeight = true;

		FVector PoleToPlayerDirection;
		FVector EnterLocation;
		FRotator EnterRotation;

		if(Spline != nullptr)
		{
			EnterLocation = PoleToEnter.ActorLocation + (PoleToEnter.ActorUpVector * EnterTestData.CurrentHeight) + GetPoleToPlayerVector(PoleToEnter) * 45;
			FVector ClosestSplineLocation = Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(EnterLocation);

			FVector ConstrainedPoleToSplineDirection = (ClosestSplineLocation - PoleToEnter.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			EnterLocation = PoleToEnter.ActorLocation + (PoleToEnter.ActorUpVector * EnterTestData.CurrentHeight) + (ConstrainedPoleToSplineDirection * 45);
			EnterRotation = (ConstrainedPoleToSplineDirection * -1.0).Rotation();
		}
		else
		{
			PoleToPlayerDirection = GetPoleToPlayerVector(PoleToEnter);
			EnterLocation = PoleToEnter.ActorLocation + (PoleToEnter.ActorUpVector * EnterTestData.CurrentHeight) + PoleToPlayerDirection * 45;
			EnterRotation = (PoleToPlayerDirection * -1.0).Rotation();
		}

		// If the players are in fullscreen, we never wan't to snap the camera
		// since that would snap it for the player that is not respawning
		bool bShouldSnapCamera = bSnapCamera;
		if (SceneView::IsFullScreen())
			bShouldSnapCamera = false;

		Player.TeleportActor(EnterLocation, EnterRotation, this, bShouldSnapCamera);
		StartClimbing(EnterTestData);
		SetState(EPlayerPoleClimbState::Climbing);
	}

	//Will Calculate Max/Min and Current Heights for all currently overlapped Poles and select the closest one among valid heights
	bool TestForValidEnter(FPoleClimbEnterTestData& TestData)
	{
		if(OverlappingPoles.Num() == 0)
			return false;

		FVector InputDirection = MoveComp.MovementInput.GetSafeNormal();

		//If we are grounded, check if we are giving input
		if(MoveComp.IsOnWalkableGround())
			if(InputDirection.IsNearlyZero())
				return false;

		TArray<FPoleClimbEnterTestData> ValidPoles;

		for(int i = 0; i < OverlappingPoles.Num(); i++)
		{
			FPoleClimbEnterTestData CurrentTest;
			CurrentTest.PoleActor = OverlappingPoles[i];

			if(!CurrentTest.PoleActor.IsValidForPlayer(Player))
				continue;
			
			float HorizontalDot = MoveComp.PreviousHorizontalVelocity.GetSafeNormal().DotProduct(GetPlayerToPoleVector(CurrentTest.PoleActor));

			//Check if we are grounded and inputting towards pole
			if(MoveComp.IsOnWalkableGround())
			{
				float Angle = InputDirection.AngularDistance(GetPlayerToPoleVector(CurrentTest.PoleActor));

				if(Angle > Math::DegreesToRadians(Settings.EnterInputAcceptanceAngle))
					continue;
			}
			//If we are airborne and moving roughly away from the pole then ignore it
			else if(HorizontalDot < - 0.25)
				continue;

			//Calculate our current climb direction and Min/Max Heights
			CurrentTest.ClimbDirectionSign = int(Math::Sign(CurrentTest.PoleActor.ActorUpVector.DotProduct(Player.ActorUpVector)));
			CurrentTest.MinHeight = CurrentTest.ClimbDirectionSign == 1 ? Settings.PoleMinHeightOffset : CalculatePlayerHeightOffset();
			CurrentTest.MaxHeight = CurrentTest.ClimbDirectionSign == 1 ? CurrentTest.PoleActor.Height - CalculatePlayerHeightOffset() : CurrentTest.PoleActor.Height - Settings.PoleMinHeightOffset;

			//Calculate our current height
			FVector PoleToPlayer = Player.ActorLocation - CurrentTest.PoleActor.ActorLocation;
			float PoleToPlayerDot = CurrentTest.PoleActor.ActorUpVector.DotProduct(PoleToPlayer);
			int VerticalDeltaSign = int(Math::Sign(PoleToPlayerDot));
			CurrentTest.CurrentHeight  = PoleToPlayer.ConstrainToDirection(CurrentTest.PoleActor.ActorUpVector).Size() * VerticalDeltaSign;

			//If within the enter height threshhold then add it as a valid pole
			if(CurrentTest.CurrentHeight > - Settings.PoleEnterHeightMargin && CurrentTest.CurrentHeight < (CurrentTest.MaxHeight + Settings.PoleEnterHeightMargin))
			{
				CurrentTest.CurrentHeight = Math::Clamp(CurrentTest.CurrentHeight, CurrentTest.MinHeight, CurrentTest.MaxHeight);
				CurrentTest.bValidHeight = true;
				ValidPoles.Add(CurrentTest);
			}
		}

		if(ValidPoles.Num() == 0)
			return false;

		if(ValidPoles.Num() == 1)
		{
			TestData = ValidPoles[0];
			return true;
		}
		else
		{
			FPoleClimbEnterTestData HighestScoredPole;
			float ClosestDistance = 0;

			for(int i = 0; i < ValidPoles.Num(); i++)
			{
				float Distance = GetPlayerToPoleVector(ValidPoles[i].PoleActor).Size();

				if(i == 0 || Distance < ClosestDistance)
				{
					ClosestDistance = Distance;
					HighestScoredPole = ValidPoles[i];
				}
			}

			TestData = HighestScoredPole;
			return true;
		}
	}

	bool TestForValidDropDown(FPoleClimbEnterTestData& TestData, APoleClimbActor PoleActor)
	{
		//[AL] - This is mostly to initialize Data values but could include further checks

		if(PoleActor == nullptr)
			return false;

		TestData.PoleActor = PoleActor;
		TestData.ClimbDirectionSign = int(Math::Sign(TestData.PoleActor.ActorUpVector.DotProduct(Player.ActorUpVector)));
		TestData.MinHeight = TestData.ClimbDirectionSign == 1 ? Settings.PoleMinHeightOffset : CalculatePlayerHeightOffset();
		TestData.MaxHeight = TestData.ClimbDirectionSign == 1 ? TestData.PoleActor.Height - CalculatePlayerHeightOffset() : TestData.PoleActor.Height - Settings.PoleMinHeightOffset;

		return true;
	}

	//Update runtime data that can be modified by the pole / affects climbing
	void UpdatePoleData()
	{
		if(Data.ActivePole == nullptr)
			return;

		if(Data.ActivePole.Height == Data.MaxHeight - CalculatePlayerHeightOffset())
			return;

		Data.MaxHeight = Data.ClimbDirectionSign == 1 ? Data.ActivePole.Height - CalculatePlayerHeightOffset() : Data.ActivePole.Height - Settings.PoleMinHeightOffset;
		Data.MinHeight = Data.ClimbDirectionSign == 1 ? Settings.PoleMinHeightOffset : CalculatePlayerHeightOffset();
	}

	bool IsClimbing() const
	{
		return (GetState() != EPlayerPoleClimbState::Inactive &&
				 GetState() != EPlayerPoleClimbState::Cancel &&
				  GetState() != EPlayerPoleClimbState::JumpOut &&
					GetState() != EPlayerPoleClimbState::ExitToPerch);

	}

	bool DoesPoleAllowFull360Rotation() const
	{
		return Data.ActivePole != nullptr && Data.ActivePole.bAllowFull360Rotation;
	}

	EPlayerPoleClimbState GetState() const property
	{
		return Data.State;
	}

	void SetState(EPlayerPoleClimbState NewState) property
	{
		Data.State = NewState;
		AnimData.State = NewState;
	}

	EPoleType GetPoleType() const property
	{
		if(Data.ActivePole == nullptr)
			return EPoleType::Default;

		if(Settings.OverridePoleType != EPoleTypeOverride::None)
		{
			switch (Settings.OverridePoleType)
			{
				case EPoleTypeOverride::Default:
					return EPoleType::Default;
				case EPoleTypeOverride::Slippery:
					return EPoleType::Slippery;
				default:
					check(false); // Did you forgot to add the new type?
			}
		}

		return Data.ActivePole.PoleType;
	}

	void SetPoleDashProgress(float Value)
	{
		Data.CurrentDashProgress = Value;
	}

	bool IsWithinDashChainWindow()
	{
		float MinimumDuration = (Settings.DashAccelerationDuration + Settings.DashDuration) - (Settings.DashDecelerationDuration * 0.33);

		if(Data.CurrentDashProgress < MinimumDuration)
			return false;

		return true;
	}

	APoleClimbActor GetPoleClimbTransferAssistTarget(FVector ConstrainDirection, FVector TargetDirection) const
	{
		// Check nearby poles if we should do input assistance to transfer between poles
		float BestScore = 0.0;
		APoleClimbActor BestPole;
		for (auto Pole : NearbyPoles)
		{
			if (Pole == Data.ActivePole)
				continue;
			if (!Pole.bEnablePoleTransferAssist)
				continue;

			FVector PlayerRelative = Pole.ActorTransform.InverseTransformPositionNoScale(Player.ActorLocation);
			if (PlayerRelative.Z < 0.0)
				continue;
			if (PlayerRelative.Z > Pole.Height)
				continue;

			FHazeShapeSettings Shape = Pole.EnterZone.Shape;
			FVector PointOnPole = Shape.GetClosestPointToLine(
				Pole.EnterZone.WorldTransform,
				Player.ActorLocation, ConstrainDirection
			);

			float Distance = PointOnPole.Distance(Player.ActorLocation);
			float ConstrainAngle = ConstrainDirection.AngularDistance(PointOnPole - Player.ActorLocation);

			if (Distance > Pole.MaxTransferAssistDistance)
				continue;
			if (ConstrainAngle > Math::DegreesToRadians(Pole.MaxTransferAssistAngle) * 1.5)
				continue;

			float TargetingAngle = ConstrainAngle;
			if (!TargetDirection.IsNearlyZero())
			{
				TargetingAngle = TargetDirection.AngularDistance(PointOnPole - Player.ActorLocation);
			}

			if (TargetingAngle > Math::DegreesToRadians(Pole.MaxTransferAssistAngle))
				continue;

			float Score = 1.0;
			Score /= Math::Max(Distance, 0.001);
			Score /= Math::Max(TargetingAngle, 0.001);

			if (Score > BestScore)
			{
				BestScore = Score;
				BestPole = Pole;
			}
		}

		return BestPole;
	}
	
	private float CalculatePlayerHeightOffset() const
	{
		return Player.ScaledCapsuleHalfHeight * 2 + Settings.MaxHeightOffset;
	}

	// we pass in currentheight ourselves because Data.CurrentHeight isn't networked
	float CalculateClimbingFraction(const float CurrentHeight, const float ReduceHeightBy) const
	{
		const float PlayerHeightOffset = CalculatePlayerHeightOffset();

		// auto DebugColor = Player.IsMio() ? FLinearColor::Yellow : FLinearColor::LucBlue;
		// PrintToScreen("Passed in Height: " + CurrentHeight, 0.0, DebugColor);
		// PrintToScreen("Pole Current Height: " + Data.CurrentHeight, 0.0, DebugColor);

		float Frac =  Math::GetMappedRangeValueClamped(
			FVector2D(Data.MinHeight, Data.MaxHeight - PlayerHeightOffset - ReduceHeightBy), 
			FVector2D(0.0, 1.0),
			Math::Max(CurrentHeight - PlayerHeightOffset, Data.MinHeight)
		);

		return Frac;
	}
}

struct FPlayerPoleClimbData
{	
	EPlayerPoleClimbState State;
	
	APoleClimbActor OverlappingPole;
	APoleClimbActor ActivePole;

	/*
	 * Defines Climb Direction compared to pole upvector (1 = Along Poles upvector / -1 Against)
	 * Used to define Min/Max heights as well as Perch/Drop transitions on pole ends
	 */
	int ClimbDirectionSign;
	float CurrentHeight;
	float MaxHeight;
	float MinHeight;

	float IgnorePoleTimer;
	float CurrCooldown = 0.0;

	float CurrentDashProgress = 0;

	bool bPerformingTurnaround;
	bool bPerformingTurnaroundEnter;
	float TurnAroundStartTime = 0.0;
	FRotator TurnAroundRotation;
	FVector TurnAroundTargetPoleToPlayer;
	FVector VelocityOnEnter;

	bool bJumpOffBuffered = false;

	const float IgnorePoleTime = 1.0;

	void ResetData()
	{
		ActivePole = nullptr;
		State = EPlayerPoleClimbState::Inactive;
		ClimbDirectionSign = 0;
		CurrentHeight = 0.0;
		MaxHeight = 0.0;
		MinHeight = 0.0;
		bPerformingTurnaround = false;
		bPerformingTurnaroundEnter = false;
		TurnAroundStartTime = 0.0;
		CurrentDashProgress = 0;
		bJumpOffBuffered = false;

		VelocityOnEnter = FVector::ZeroVector;
	}
}

struct FPlayerPoleClimbAnimData
{
	UPROPERTY()
	EPlayerPoleClimbState State;

	UPROPERTY()
	EDashSideOverrideState DashSideOverrideState = EDashSideOverrideState::Default;

	bool bClimbing = false;
	bool bInEnter = false;
	bool bJumping;
	bool bClimbingToPerchPoint;
	bool bClimbingDownFromPerchPoint;
	bool bCancellingPoleClimb;
	bool bJumpingUp;
	bool bSliding = false;

	bool bTurnAroundEnter = false;

	bool bPerformingLeftTurnAround;
	bool bPerformingRightTurnAround;

	bool bJumpingTowardsRight;

	//Angle of jump based on 0 being towards pole.
	float JumpOutAngle = 0.0;
	float PoleClimbVerticalVelocity = 0.0;
	//Vertical Climb Input
	float PoleClimbVerticalInput = 0.0;
	//Signed Rotation Speed for rotating around pole (- Right / + Left)
	float PoleRotationSpeed = 0.0;
	//Rotation Input
	float PoleRotationInput = 0.0;
	//SlipVelocity
	float SlipVelocity = 0.0;

	void ResetData()
	{
		State = EPlayerPoleClimbState::Inactive;
		DashSideOverrideState = EDashSideOverrideState::Default;

		bClimbing = false;
		bInEnter = false;
		bJumping = false;
		bClimbingToPerchPoint = false;
		bClimbingDownFromPerchPoint = false;
		bCancellingPoleClimb = false;
		bJumpingUp = false;
		bJumpingTowardsRight = false;
		bSliding = false;

		bTurnAroundEnter = false;

		bPerformingLeftTurnAround = false;
		bPerformingRightTurnAround = false;

		JumpOutAngle = 0.0;
		PoleClimbVerticalVelocity = 0.0;
		PoleClimbVerticalInput = 0.0;
		PoleRotationSpeed = 0.0;
		PoleRotationInput = 0.0;
		SlipVelocity = 0.0;
	}
}

struct FPoleClimbEnterTestData
{
	APoleClimbActor PoleActor;
	int ClimbDirectionSign = 0;
	float MinHeight = 0;
	float MaxHeight = 0;
	float CurrentHeight = 0;
	float DistanceToActor = 0;

	bool bValidHeight = false;
}

enum EPlayerPoleClimbState
{
	Inactive,
	Enter,
	EnterFromPerch,
	Climbing,
	Dash,
	ChainDash,
	ExitToPerch,
	Cancel,
	GroundedExit,
	JumpOut
}

enum EDashSideOverrideState
{
	Default,
	Left,
	Right
}