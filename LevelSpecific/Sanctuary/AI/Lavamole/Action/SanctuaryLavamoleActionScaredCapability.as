struct FSanctuaryLavamoleActionScaredData
{
}

class USanctuaryLavamoleActionScaredCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryLavamoleActionScaredData Params;
	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default CapabilityTags.Add(LavamoleTags::Action);
	USanctuaryLavamoleSettings Settings;
	UHazeActionQueueComponent ActionComp;

	FVector StartedFacingDirection;
	float WiggleRotationTimer;
	float TimeSinceBite = 0.0;
	float StartedHeight = 0.0;
	
	AAISanctuaryLavamole Mole;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mole = Cast<AAISanctuaryLavamole>(Owner);
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		ActionComp = UHazeActionQueueComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FSanctuaryLavamoleActionScaredData Parameters)
	{
		Params = Parameters;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Mole.Bite1Comp.IsBitten() || Mole.Bite2Comp.IsBitten())
			return true;
		if (ActiveDuration > Settings.ScaredDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(LavamoleTags::LavaMoleFacePlayer, this);
		StartedFacingDirection = Owner.ActorForwardVector;
		StartedHeight = Owner.ActorLocation.Z - Mole.OccupiedHole.ActorLocation.Z;
		Mole.bHasBeenPulledOutOfBurrow = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(LavamoleTags::LavaMoleFacePlayer, this);
		if (!Mole.Bite1Comp.IsBitten() && !Mole.Bite2Comp.IsBitten() && HasControl())
		{
			ActionComp.Capability(USanctuaryLavamoleActionDigDownCapability, FSanctuaryLavamoleActionDigDownData());
		}

		Mole.bIsWhacky = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// scared wiggle
		WiggleRotationTimer += DeltaTime * Settings.ScaredWiggleRotationSpeed;
		float SinTimer = Math::Sin(WiggleRotationTimer);
		float WiggleDegrees = SinTimer * Settings.ScaredWiggleRotationMax;
		FVector NewDirection = StartedFacingDirection.RotateAngleAxis(WiggleDegrees, FVector::UpVector);
		Owner.SetActorRotation(FRotator::MakeFromXZ(NewDirection, FVector::UpVector));

		// scared location
		FVector InterpolatedOffset = FVector::ZeroVector;
		float HeightInterpolation = Math::Clamp(ActiveDuration / Settings.ScaredHeightInterpolationDuration, 0.0, 1.0);
		InterpolatedOffset.Z = Math::EaseOut(StartedHeight, Settings.ScaredHeightOffset, HeightInterpolation, 2.0);
		Owner.SetActorLocation(Mole.OccupiedHole.ActorLocation + InterpolatedOffset);
	}
}

/*
class USanctuaryLavamoleScaredCapability : UHazeCapability
{
	AAISanctuaryLavamole Lavamole;
	USanctuaryLavamoleSettings Settings;
	USanctuaryLavamoleGrabbedComponent GrabbedComp;
	
	FVector StartedFacingDirection;
	float WiggleRotationTimer;
	float TimeSinceBite = 0.0;
	float StartedHeight = 0.0;

	float GrabbedTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Lavamole = Cast<AAISanctuaryLavamole>(Owner);
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		GrabbedComp = USanctuaryLavamoleGrabbedComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryLavamoleScaredActivationParams& Params) const
	{
		if(GrabbedComp.GetNumGrabbers() == 1)
		{
			Params = GetActivationParams();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TimeSinceBite > Settings.ScaredDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryLavamoleScaredActivationParams Params)
	{
		StartedFacingDirection = Owner.ActorForwardVector;
		StartedHeight = Owner.ActorLocation.Z - Lavamole.OccupiedHole.ActorLocation.Z;
		WiggleRotationTimer = 0.0;
		GrabbedTimer = 0.0;
		Lavamole.bWantToBeScared = false;
		Lavamole.bScared = true;
		if (Params.BitingPlayer != nullptr && Params.BitingPlayer.HasControl())
		{
			UCentipedeBiteComponent BiteComp = UCentipedeBiteComponent::Get(Params.BitingPlayer);
			BiteComp.BiteSnapToLocation(Params.HeadTargetLocation, Params.ToBiteTarget, Settings.GrabAlignPlayerHeadDuration);
		}
	}

	FSanctuaryLavamoleScaredActivationParams GetActivationParams() const
	{
		USanctuaryLavamoleCentipedeBiteResponseComponent Responser;
		FCentipedeBiteEventParams BiteData;
		GrabbedComp.GetFirstResponder(Responser, BiteData);

		FVector ToBiteTarget = Responser.WorldLocation - BiteData.CentipedeHead.ActorLocation;
		ToBiteTarget.Z = 0.0;
		FVector HeadTargetLocation = Lavamole.OccupiedHole.ActorLocation - ToBiteTarget.GetSafeNormal() * Settings.DesiredDistanceToCentoHead;
		HeadTargetLocation.Z = BiteData.Player.ActorLocation.Z;
		FSanctuaryLavamoleScaredActivationParams Params;
		Params.BitingPlayer = BiteData.Player;
		Params.HeadTargetLocation = HeadTargetLocation;
		Params.ToBiteTarget = ToBiteTarget;
		return Params;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Lavamole.bScared = false;
		if(GrabbedComp.GetNumGrabbers() == 0)
			Lavamole.bWantsToDig = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// scared wiggle
		WiggleRotationTimer += DeltaTime * Settings.ScaredWiggleRotationSpeed;
		float SinTimer = Math::Sin(WiggleRotationTimer);
		float WiggleDegrees = SinTimer * Settings.ScaredWiggleRotationMax;
		FVector NewDirection = StartedFacingDirection.RotateAngleAxis(WiggleDegrees, FVector::UpVector);
		Owner.SetActorRotation(FRotator::MakeFromXZ(NewDirection, FVector::UpVector));

		// scared location
		FVector InterpolatedOffset = FVector::ZeroVector;
		float HeightInterpolation = Math::Clamp(ActiveDuration / Settings.ScaredHeightInterpolationDuration, 0.0, 1.0);
		InterpolatedOffset.Z = Math::EaseOut(StartedHeight, Settings.ScaredHeightOffset, HeightInterpolation, 2.0);
		Owner.SetActorLocation(Lavamole.OccupiedHole.ActorLocation + InterpolatedOffset);

		if (GrabbedComp.GetNumGrabbers() == 1)
		{
			GrabbedTimer += DeltaTime;
			TimeSinceBite = 0.0;
		}
		else
		{
			GrabbedTimer = 0.0;
			TimeSinceBite += DeltaTime;
		}
		
		GrabbedComp.State.bGrabbed = GrabbedTimer > Settings.ScaredBittenCountAsGrabDuration;
		// PrintToScreen("GrabbedTimer: " + GrabbedTimer);
	}
}
*/