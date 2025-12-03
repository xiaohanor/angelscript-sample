class UTeenDragonSpiritFishPounceCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::InfluenceMovement;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UTeenDragonSpiritFishPounceComponent UserComp;
	UPlayerTeenDragonComponent DragonComp;
	FTeenDragonSpiritFishPounceData Data;

	FVector Velocity;
	FVector EndLocation;
	FRotator DesiredRotation;

	float StartTotalDuration = 0.05;
	float CurrentTotalDuration;
	float Gravity;
	float PounceSpeed = 1400.0;
	float PounceDuration = 0.5;

	bool bFinishedMove;

	ATeenDragon TeenDragon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UTeenDragonSpiritFishPounceComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		Gravity = UMovementGravitySettings::GetSettings(Player).GravityAmount * 2;

		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		TeenDragon = DragonComp.GetTeenDragon();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonSpiritFishPounceData& Params) const
	{
		if (!UserComp.ConsumeCanPounce())
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.HasGroundContact())
			return false;

		Params = UserComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > CurrentTotalDuration)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration > PounceDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonSpiritFishPounceData Params)
	{
		Data = Params;
		Data.Fish.Targetable.Disable(this);
		Gravity = UMovementGravitySettings::GetSettings(Player).GravityAmount * 2;

		Player.BlockCapabilities(n"Interaction", this);
		
		EndLocation = Data.EndLocation;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(Player);
		TraceSettings.IgnoreActor(Player.OtherPlayer);

		FVector Start = Data.EndLocation + FVector::UpVector * 50;
		FVector End = Start - FVector::UpVector * 5000;
		FHitResult Hit = TraceSettings.QueryTraceSingle(Start, End);

		if (Hit.bBlockingHit)
		{
			EndLocation = Hit.ImpactPoint;
		}
		
		DesiredRotation = (EndLocation - Player.ActorLocation).ConstrainToPlane(FVector::UpVector).Rotation();
		FVector StartLocation = Player.ActorLocation;
		float HorizontalSpeed = (StartLocation - EndLocation).ConstrainToPlane(FVector::UpVector).Size() / PounceDuration; 
		Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(StartLocation, EndLocation, Gravity, HorizontalSpeed);

		CurrentTotalDuration = StartTotalDuration;
		bFinishedMove = false;

		TeenDragon.Mesh.AddLocomotionFeature(Player.IsMio() ? UserComp.LocomotionFeatureAcid : UserComp.LocomotionFeatureTail , this);

		UserComp.bIsPouncing = true;
		Player.PlayForceFeedback(UserComp.Rumble, false, false, this, 0.5);
	}

	float TotalDistance()
	{
		// FOutCalculateVelocity Params = FOutCalculateVelocity();
		return 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Data.Fish.Targetable.Enable(this);

		Player.UnblockCapabilities(n"Interaction", this);
		TeenDragon.Mesh.RemoveLocomotionFeature(Player.IsMio() ? UserComp.LocomotionFeatureAcid : UserComp.LocomotionFeatureTail, this);

		UserComp.bIsPouncing = false;

		Player.PlayForceFeedback(UserComp.Rumble, false, false, this, 1.25);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float Distance = (Player.ActorLocation - EndLocation).Size();
				Velocity -= FVector(0,0,Gravity) * DeltaTime;
				float HorizontalDelta = PounceSpeed * DeltaTime; 

				if (Distance <= HorizontalDelta || (MoveComp.HasAnyValidBlockingImpacts() && ActiveDuration > 0.25))
				{
					Velocity = Velocity.GetClampedToMaxSize(Distance);
					bFinishedMove = true;
					Data.Fish.CrumbPouncedOn();
				}

				Movement.AddVelocity(Velocity);
				Movement.InterpRotationTo(DesiredRotation.Quaternion(), 8.0);

				if (!bFinishedMove)
					CurrentTotalDuration += DeltaTime;
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(n"SpiritFish");
		}
	}
};