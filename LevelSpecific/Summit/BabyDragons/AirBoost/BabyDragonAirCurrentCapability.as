

class UBabyDragonAirCurrentCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(BabyDragon::BabyDragon);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;

	ABabyDragon BabyDragon;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerAcidBabyDragonComponent DragonComp;

	TArray<ASummitAirCurrent> AirCurrents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAcidBabyDragonComponent::Get(Player);
		BabyDragon = DragonComp.BabyDragon;

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		Player.OnActorBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		Player.OnActorEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION()
	private void OnBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Current = Cast<ASummitAirCurrent>(OtherActor);
		if (Current != nullptr)
			AirCurrents.Add(Current);
	}

	UFUNCTION()
	private void OnEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Current = Cast<ASummitAirCurrent>(OtherActor);
		if (Current != nullptr)
			AirCurrents.Remove(Current);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AirCurrents.Num() == 0)
			return false;

		if(EveryAirCurrentIsBlocked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AirCurrents.Num() == 0)
			return true;

		if(EveryAirCurrentIsBlocked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.bInAirCurrent = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.bInAirCurrent = false;
	}

	bool EveryAirCurrentIsBlocked() const
	{
		for(auto AirCurrent : AirCurrents)
		{
			if(AirCurrent.AirCurrentIsBlocked())
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector VerticalVelocity = Player.GetActorVerticalVelocity();

		// Determine the maximum speed from all the currents we're in
		float CapsuleZ = Player.CapsuleComponent.WorldLocation.Z;
		float MaxAcceleration = 0.0;
		float MaxSpeed = 0.0;

		DragonComp.LastAirCurrentTime = Time::GameTimeSeconds;

		for (ASummitAirCurrent Current : AirCurrents)
		{
			float LowerPoint = Current.CurrentBox.WorldLocation.Z - Current.CurrentBox.ScaledBoxExtent.Z;
			float UpperPoint = Current.CurrentBox.WorldLocation.Z + Current.CurrentBox.ScaledBoxExtent.Z - 100.0;
			float PointPct = (CapsuleZ - LowerPoint) / (UpperPoint - LowerPoint);

			float WantedAcceleration = Current.AccelerationOfCurrent;
			if (VerticalVelocity.Z > 0.0)
				WantedAcceleration *= 1.0 - PointPct;

			if (WantedAcceleration > MaxAcceleration)
				MaxAcceleration = WantedAcceleration;

			float WantedSpeed = Math::Min((UpperPoint - CapsuleZ) / 0.5, Current.SpeedOfCurrent);
			if (WantedSpeed > MaxSpeed)
				MaxSpeed = WantedSpeed;
		}

		VerticalVelocity -= MoveComp.GetGravity() * DeltaTime * BabyDragonAirBoost::GlideGravityMultiplier;
		VerticalVelocity.Z = Math::Min(MaxSpeed, VerticalVelocity.Z + (MaxAcceleration * DeltaTime));

		// Apply upward speed to our velocity
		Player.SetActorVerticalVelocity(VerticalVelocity);
	}
};