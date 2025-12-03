struct FCongaLineCollisionHandshake
{
	int CollisionIndex;
	float StartTime;
}


UCLASS(Abstract)
class UCongaLinePlayerComponent : UActorComponent
{
	access Internal = protected, UCongaLineActiveCapability, UCongaLineSplinePlacerCapability;

	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet ActiveSheet;

	UPROPERTY(EditDefaultsOnly)
	UCongaLinePlayerSettings DefaultSettings;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset ZoomedInSettings;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset ZoomedOutSettings;
	
	UPROPERTY()
	UForceFeedbackEffect HitWallForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect CutoffLineForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect GainedMonkeyForceFeedback;

	AHazePlayerCharacter Player;
	private UPlayerMovementComponent MoveComp;
	private UTundraPlayerShapeshiftingComponent ShapeshiftComp;

	access:Internal
	bool bIsLeadingCongaLine = false;

	TArray<FVector> SplineHitWallLocations;

	private TArray<UCongaLineDancerComponent> Dancers;

	access:Internal
	FHazeRuntimeSpline Spline;

	UCongaLinePlayerSettings Settings;

	bool bStunned = false;
	bool bMyLineCutoff = false;
	bool bOtherLineCutoff = false;
	bool bIsMovementLocked = false;
	bool bIsOnDanceFLoor = false;

	bool bMonkeysCollectedOnce = false;

	FHazeAcceleratedFloat CurrentSpeedBonus;

	TOptional<FCongaLineCollisionHandshake> OtherSideCollision;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		Dancers.Reserve(CongaLine::MaxDancers);

		if(DefaultSettings != nullptr)
			Player.ApplyDefaultSettings(DefaultSettings);

		Settings = UCongaLinePlayerSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentSpeedBonus.AccelerateTo(GetSpeedBonus(), 2, DeltaSeconds);

		//Time out collisions from other side
		if(OtherSideCollision.IsSet() && Time::GetGameTimeSince(OtherSideCollision.Value.StartTime) > 1.0)
		{
			OtherSideCollision.Reset();
		}
	}

	AHazeActor GetPlayerShapeshiftActor()
	{
		if(ShapeshiftComp == nullptr)
			ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Owner);

		return ShapeshiftComp.BigShapeComponent.GetShapeActor();
	}


	bool IsLeadingCongaLine() const
	{
		return bIsLeadingCongaLine;
	}
	
	void PlayMonkeyCollectedRumble()
	{
		Player.PlayForceFeedback(GainedMonkeyForceFeedback, false, true, this, 1);
	}

	void PlayWallHitRumble()
	{
		Player.PlayForceFeedback(HitWallForceFeedback, false, true, this, 1);
	}

	void PlayCutoffLineRumble()
	{
		Player.PlayForceFeedback(CutoffLineForceFeedback, false, true, this, 1);
	}
	/**
	 * @return Index
	 */
	int AddDancer(UCongaLineDancerComponent DancerComp)
	{
		PlayMonkeyCollectedRumble();
		
		Dancers.AddUnique(DancerComp);
		devCheck(Dancers.Num() <= CongaLine::MaxDancers, "Too many dancers in the conga line! Increase CongaLine::MaxDancers if needed.");

		FCongaLinePLayerOnDancerStartedEnteringEventData EventData;
		EventData.StartedEnteringDancer = DancerComp;
		UCongaLinePlayerEventHandler::Trigger_OnDancerStartedEntering(Player, EventData);
		UCongaLinePlayerEventHandler::Trigger_OnDancerStartedEntering(GetPlayerShapeshiftActor(), EventData);

		CongaLine::GetManager().SetMonkeyAmountForPlayer(Dancers.Num(), Player.IsMio() ? EMonkeyColorCode::Mio : EMonkeyColorCode::Zoe, true);

		FCongaLineDancerGainedEventData ManagerEventData;
		ManagerEventData.DancerComp = DancerComp;
		ManagerEventData.Player = Player;
		ManagerEventData.NewMonkeyCount = Dancers.Num();
		UCongaLineManagerEventHandler::Trigger_OnDancerGained(CongaLine::GetManager(), ManagerEventData);

		if(CongaLine::GetDanceFloor() != nullptr)
			CongaLine::GetDanceFloor().HandleNewMonkeyGained(DancerComp);

		int MaxMonkeysPerPlayer = Math::IntegerDivisionTrunc( CongaLine::GetManager().MonkeyCounter.MonkeysPerStage, 2);
		if(Dancers.Num() == MaxMonkeysPerPlayer)
			bMonkeysCollectedOnce = true;

		return Dancers.Num() - 1;
	}

	void RemoveDancer(UCongaLineDancerComponent DancerComp)
	{
		//CongaLine::GetManager().RemoveMonkey(Player.IsMio() ? EMonkeyColorCode::Mio : EMonkeyColorCode::Zoe);

		int Index = Dancers.RemoveSingle(DancerComp);
		for(int i = 0; i < Dancers.Num(); i++)
		{
			Dancers[i].SetIndex(i);
		}

		if(CongaLine::GetManager() != nullptr)
			CongaLine::GetManager().SetMonkeyAmountForPlayer(Dancers.Num(), Player.IsMio() ? EMonkeyColorCode::Mio : EMonkeyColorCode::Zoe, false);
	}

	TArray<UCongaLineDancerComponent> GetDancers() const
	{
		return Dancers;
	}

	int CurrentDancerCount() const
	{
		return Dancers.Num();
	}

	void ResetSpline()
	{
		Spline = FHazeRuntimeSpline();

		Spline.SetCustomEnterTangentPoint(-Owner.ActorForwardVector);
		PlacePointAtCurrentLocation();
		PlacePointAtCurrentLocation();
	}

	void PlacePointAtCurrentLocation()
	{
		Spline.AddPoint(GetCurrentLocationOnGround());
	}

	void HitWallAtCurrentLocation()
	{
		FVector HitWallLocation = GetCurrentLocationOnGround();
		Spline.AddPoint(HitWallLocation);
		SplineHitWallLocations.Add(HitWallLocation);
	}

	void RemoveWallHitPoint(int Index)
	{
		check(SplineHitWallLocations.Num() > Index);
		SplineHitWallLocations.RemoveAt(Index);
	}

	void UpdateLastPointToCurrentLocation()
	{
		Spline.SetPoint(GetCurrentLocationOnGround(), Spline.Points.Num() - 1);
		Spline.SetCustomExitTangentPoint(Owner.ActorForwardVector);
	}
	
	float DistanceToLastPlacedPoint() const
	{
		return GetCurrentLocationOnGround().Distance(Spline.Points[Spline.Points.Num() - 2]);
	}

	private FVector GetCurrentLocationOnGround() const
	{
		if(MoveComp.HasGroundContact())
		{
			return Owner.ActorLocation;
		}
		else
		{
			// FB TODO: Project on to ground
			return Owner.ActorLocation;
		}
	}

	float GetTargetDanceDistanceAlongSpline(int Index) const
	{
		return Spline.Length - (Index * (CongaLine::DistanceBetweenDancers) + CongaLine::DistanceFromPlayerToFirstDancer);
	}

	FVector GetTargetDanceLocation(int Index) const
	{
		const float DistanceAlongSpline = GetTargetDanceDistanceAlongSpline(Index);

		if(DistanceAlongSpline < 0)
		{
			FVector Location;
			FVector Direction;
			Spline.GetLocationAndDirection(0, Location, Direction);
			Direction = Direction.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
			return Location + (Direction * DistanceAlongSpline);
		}

		return Spline.GetLocationAtDistance(DistanceAlongSpline);
	}

	FQuat GetTargetDanceRotation(int Index) const
	{
		return Spline.GetQuatAtDistance(GetTargetDanceDistanceAlongSpline(Index));
	}

	FTransform GetTargetDanceTransform(int Index) const
	{
		// FB TODO: Optimize
		FVector Location = GetTargetDanceLocation(Index);
		FQuat Rotation = GetTargetDanceRotation(Index);

		return FTransform(Rotation, Location);
	}

	bool HasDancers() const
	{
		return !Dancers.IsEmpty();
	}

	void DisperseAllDancers()
	{
		FCongaLinePlayerLostDancersEventData ManagerEventData;
		ManagerEventData.LostMonkeyCount = Dancers.Num();
		ManagerEventData.Player = Player;
		ManagerEventData.NewMonkeyCount = 0;
		UCongaLineManagerEventHandler::Trigger_OnDancersLost(CongaLine::GetManager(), ManagerEventData);

		for(int i = Dancers.Num() - 1; i >= 0; i--)
		{
			Dancers[i].ExitCongaLine(true);
		}
	}


	void SetMovementLocked(bool ShouldLock)
	{
		bIsMovementLocked = ShouldLock;
	}

	float GetSpeedBonus() const
	{
		return Dancers.Num() * CongaLine::SpeedIncreasePerMonkey;
	}

	float GetSpeed(FVector Forward, float DeltaTime) const
	{
		if(bIsMovementLocked) 
			return 0;

		const float CurrentSpeed = MoveComp.Velocity.DotProduct(Forward.VectorPlaneProject(FVector::UpVector));
		TEMPORAL_LOG(Player).DirectionalArrow("Conga Line Forward", Player.ActorLocation, Forward * 500, 100);
	
		float TargetSpeed = Settings.MoveSpeed + CurrentSpeedBonus.Value;

		float InterpSpeed = Settings.Acceleration;
		if(CurrentSpeed > TargetSpeed)
			InterpSpeed = Settings.Deceleration;

		if(bMonkeysCollectedOnce)
			TargetSpeed = CongaLine::MaxMoveSpeedCap;

		if(TargetSpeed > CongaLine::MaxMoveSpeedCap)
			TargetSpeed = CongaLine::MaxMoveSpeedCap;

		if(CongaLine::GetManager().bIsCompleted)
			TargetSpeed = CongaLine::EndSpeed;
		
		return Math::FInterpConstantTo(CurrentSpeed, TargetSpeed, DeltaTime, InterpSpeed);
	}

	void CheckCollisionWithCongaLine()
	{
		if(CongaLine::IgnoreCollisions.IsEnabled())
			return;

		if(CongaLine::GetManager().bShouldCollide == false)
			return;

		CheckCollisionOwnCongaLine();
		int CollisionIndex = CheckCollisionOtherCongaLine();
		
		if(CollisionIndex >= 0 && !OtherSideCollision.IsSet())
		{
			NetRemoteCollidedWithLine(CollisionIndex);
		}

		CheckCollisionOtherPlayerOwnCongaLine();
	}


	void DisperseBothPlayersMonkeys()
	{
		UCongaLinePlayerComponent OtherPlayer = UCongaLinePlayerComponent::Get(Game::GetOtherPlayer(Player.Player));
		FCongaLinePLayerOnCollidedWithCongaLineEventData OtherPlayerEventData;
		OtherPlayerEventData.DispersedDancers = OtherPlayer.Dancers;
		UCongaLinePlayerEventHandler::Trigger_OnCollidedWithCongaLine(OtherPlayer.GetPlayerShapeshiftActor(), OtherPlayerEventData);
		OtherPlayer.DisperseAllDancers();
		OtherPlayer.PlayCutoffLineRumble();
		OtherPlayer.OtherSideCollision.Reset();
		
		FCongaLinePLayerOnCollidedWithCongaLineEventData EventData;
		EventData.DispersedDancers = Dancers;
		UCongaLinePlayerEventHandler::Trigger_OnCollidedWithCongaLine(GetPlayerShapeshiftActor(), EventData);
		DisperseAllDancers();
		PlayCutoffLineRumble();
		OtherSideCollision.Reset();

		CongaLine::GetDanceFloor().HandleDispersedMonkeys();		
	}


	void CheckCollisionOwnCongaLine()
	{
		int CollisionIndex = -1;

		// Skip the first dancers, since we can never hit them
		for(int i = 3; i < Dancers.Num(); i++)
		{
			UCongaLineDancerComponent Dancer = Dancers[i];

			if(!Dancer.IsInCongaLine())
				continue;

			if(Dancer.Owner.ActorLocation.Distance(Owner.ActorLocation) > CongaLine::DistanceBetweenDancers * 0.5 + 30)
				continue;

			CollisionIndex = i;
			break;
		}

		if(CollisionIndex < 0)
			return;

		CrumbOnCollidedWithCongaLine(CollisionIndex);
	}

	void CheckCollisionOtherPlayerOwnCongaLine()
	{
		const UCongaLinePlayerComponent OtherPlayer = UCongaLinePlayerComponent::Get(Player.GetOtherPlayer());
		int CollisionIndex = OtherPlayer.CheckCollisionOtherCongaLine();
		if(CollisionIndex >= 0)
		{
			if(!HasControl())
				return;

			if(OtherPlayer.OtherSideCollision.IsSet())
			{
				CrumbOnCollidedWithCongaLine(CollisionIndex);
				OtherSideCollision.Reset();
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetRemoteCollidedWithLine(int CollisionIndex)
	{
		FCongaLineCollisionHandshake Handshake;
		Handshake.StartTime = Time::GameTimeSeconds;
		Handshake.CollisionIndex = CollisionIndex;
		OtherSideCollision.Set(Handshake);
		bOtherLineCutoff = true;
	}


	int CheckCollisionOtherCongaLine() const
	{
		UCongaLinePlayerComponent OtherPlayer = UCongaLinePlayerComponent::Get(Player.GetOtherPlayer());

		int CollisionIndex = -1;
		for(int i = 0; i < OtherPlayer.Dancers.Num(); i++)
		{
			UCongaLineDancerComponent Dancer = OtherPlayer.Dancers[i];

			if(!Dancer.IsInCongaLine())
				continue;

			if(Dancer.Owner.ActorLocation.Distance(Owner.ActorLocation) > CongaLine::DistanceBetweenDancers * 0.5 + 30)
				continue;

			CollisionIndex = i;
			break;
		}

		return CollisionIndex;
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnCollidedWithCongaLine(int CollisionIndex)
	{
		#if EDITOR
		if(CongaLine::GetManager().bDisperseAllMonkeysOnLineCutoff)
		{
			DisperseBothPlayersMonkeys();
			return;
		}
		#endif

		FCongaLinePLayerOnCollidedWithCongaLineEventData PlayerEventData;

		int LostDancerCount = Dancers.Num() - CollisionIndex;

		for(int i = Dancers.Num() - 1; i >= CollisionIndex; i--)
		{
			UCongaLineDancerComponent Dancer = Dancers[i];
			PlayerEventData.DispersedDancers.Add(Dancer);
			Dancer.ExitCongaLine(true);
		}
		UCongaLinePlayerEventHandler::Trigger_OnCollidedWithCongaLine(GetPlayerShapeshiftActor(), PlayerEventData);

		FCongaLinePlayerLostDancersEventData ManagerEventData;
		ManagerEventData.LostMonkeyCount = LostDancerCount;
		ManagerEventData.Player = Player;
		ManagerEventData.NewMonkeyCount = Dancers.Num();
		UCongaLineManagerEventHandler::Trigger_OnDancersLost(CongaLine::GetManager(), ManagerEventData);

		PlayCutoffLineRumble();
		bMyLineCutoff = true;

		if(CongaLine::GetDanceFloor() != nullptr)
		{
			CongaLine::GetDanceFloor().HandleDispersedMonkeys();
		}
	}
};